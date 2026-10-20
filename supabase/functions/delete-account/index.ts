/// <reference lib="deno.ns" />
import "jsr:@supabase/functions-js@2.110.5/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.90.1";

const MAX_BODY_BYTES = 1024;
const USER_FILES_BUCKET = "user-images";

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function allowedOrigin(request: Request): string | null {
  const origin = request.headers.get("Origin");
  if (!origin) return null;
  const configured =
    Deno.env.get("CONSUMER_APP_ORIGIN") ?? "https://app.ablerite.com";
  if (
    origin === configured ||
    /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
  ) {
    return origin;
  }
  throw new HttpError(403, "Origin not allowed");
}

function responseHeaders(origin: string | null): HeadersInit {
  return {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Vary": "Origin",
    ...(origin ? { "Access-Control-Allow-Origin": origin } : {}),
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function json(
  origin: string | null,
  body: unknown,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: responseHeaders(origin),
  });
}

async function readConfirmation(request: Request): Promise<string> {
  const declaredLength = Number(request.headers.get("Content-Length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    throw new HttpError(413, "Request body is too large");
  }
  const raw = await request.text();
  if (new TextEncoder().encode(raw).byteLength > MAX_BODY_BYTES) {
    throw new HttpError(413, "Request body is too large");
  }
  try {
    const body = JSON.parse(raw || "{}") as { confirmation?: unknown };
    return typeof body.confirmation === "string" ? body.confirmation : "";
  } catch {
    throw new HttpError(400, "Invalid JSON body");
  }
}

async function listFilesRecursively(
  storage: ReturnType<typeof createClient>["storage"],
  bucket: string,
  folder: string,
): Promise<string[]> {
  const paths: string[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await storage.from(bucket).list(folder, {
      limit: 100,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) throw new HttpError(500, "Could not remove account files");
    if (!data || data.length === 0) break;

    for (const entry of data) {
      const path = `${folder}/${entry.name}`;
      if (entry.id == null) {
        paths.push(...await listFilesRecursively(storage, bucket, path));
      } else {
        paths.push(path);
      }
    }

    if (data.length < 100) break;
    offset += data.length;
  }

  return paths;
}

Deno.serve(async (request: Request) => {
  let origin: string | null = null;
  try {
    origin = allowedOrigin(request);
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: responseHeaders(origin),
      });
    }
    if (request.method !== "POST") {
      throw new HttpError(405, "Method not allowed");
    }
    if (await readConfirmation(request) !== "DELETE") {
      throw new HttpError(400, "Account deletion was not confirmed");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      throw new HttpError(500, "Server configuration is incomplete");
    }

    const authHeader = request.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.slice(7)
      : "";
    if (!token) throw new HttpError(401, "Missing bearer token");

    const authClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: userData, error: userError } =
      await authClient.auth.getUser(token);
    if (userError || !userData.user) {
      throw new HttpError(401, "Invalid or expired session");
    }
    const userId = userData.user.id;

    // Storage objects must be removed before Auth will allow their owner to be
    // deleted. All consumer uploads are kept beneath this user-ID prefix.
    const paths = await listFilesRecursively(
      adminClient.storage,
      USER_FILES_BUCKET,
      userId,
    );
    for (let index = 0; index < paths.length; index += 100) {
      const { error } = await adminClient.storage
        .from(USER_FILES_BUCKET)
        .remove(paths.slice(index, index + 100));
      if (error) throw new HttpError(500, "Could not remove account files");
    }

    // Revoke refresh sessions first. Existing access JWTs cannot be revoked,
    // so the app also clears its persisted local token after this succeeds.
    const { error: signOutError } = await adminClient.auth.admin.signOut(token);
    if (signOutError) {
      console.warn(JSON.stringify({
        message: "Account deletion session revocation warning",
        userId,
        error: signOutError.message,
      }));
    }

    // Public user-owned rows use ON DELETE CASCADE, so this removes the Auth
    // identity and all database data associated with it in one operation.
    const { error: deleteError } =
      await adminClient.auth.admin.deleteUser(userId);
    if (deleteError) {
      console.error(JSON.stringify({
        message: "Account deletion failed",
        userId,
        error: deleteError.message,
      }));
      throw new HttpError(500, "Account deletion could not be completed");
    }

    return json(origin, { deleted: true });
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    const message = error instanceof Error
      ? error.message
      : "Unexpected server error";
    if (status >= 500) console.error(error);
    return json(origin, { error: message }, status);
  }
});
