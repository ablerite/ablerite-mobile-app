import { execFileSync } from "node:child_process";
import {
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const mobileRoot = path.resolve(scriptDir, "..");
const homepageRoot = path.resolve(mobileRoot, "..", "ablerite-homepage");
const outputDir = path.join(mobileRoot, "store-assets", "google-play");
const sourceDir = path.join(outputDir, "source");
const tempDir = path.join(outputDir, ".tmp");

const width = 1024;
const height = 500;

mkdirSync(outputDir, { recursive: true });
mkdirSync(sourceDir, { recursive: true });
mkdirSync(tempDir, { recursive: true });

const background = path.join(
  sourceDir,
  "feature-graphic-background-source.png",
);
const iconSource = path.join(mobileRoot, "assets", "app_icon.png");
const featureGraphic = path.join(outputDir, "feature-graphic-1024x500.png");
const playIcon = path.join(outputDir, "app-icon-512.png");

const screens = {
  finance: path.join(
    homepageRoot,
    "assets",
    "websalespage",
    "homescreens",
    "Simulator Screenshot - iPhone 16 Pro - 2026-07-23 at 17.00.09.png",
  ),
  media: path.join(
    homepageRoot,
    "assets",
    "websalespage",
    "homescreens",
    "Simulator Screenshot - iPhone 16 Pro - 2026-07-23 at 17.00.06.png",
  ),
  exploration: path.join(
    homepageRoot,
    "assets",
    "websalespage",
    "homescreens",
    "Simulator Screenshot - iPhone 16 Pro - 2026-07-23 at 17.00.14.png",
  ),
};

function imageDataUrl(filePath) {
  return `data:image/png;base64,${readFileSync(filePath).toString("base64")}`;
}

function phoneSvg({ src, x, y, w, rotate = 0 }) {
  const h = w * (2622 / 1206);
  const cx = x + w / 2;
  const cy = y + h / 2;

  return `<g transform="rotate(${rotate} ${cx} ${cy})" filter="url(#phoneShadow)">
    <image href="${imageDataUrl(src)}" x="${x}" y="${y}" width="${w}" height="${h}" preserveAspectRatio="xMidYMid meet" filter="url(#fittedBezel)"/>
  </g>`;
}

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <linearGradient id="leftShade" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#042B27" stop-opacity="0.34"/>
      <stop offset="72%" stop-color="#042B27" stop-opacity="0"/>
    </linearGradient>
    <filter id="phoneShadow" x="-40%" y="-30%" width="180%" height="190%">
      <feDropShadow dx="0" dy="14" stdDeviation="13" flood-color="#021B18" flood-opacity="0.42"/>
    </filter>
    <filter id="fittedBezel" x="-7%" y="-4%" width="114%" height="108%" color-interpolation-filters="sRGB">
      <feMorphology in="SourceAlpha" operator="dilate" radius="4" result="expanded"/>
      <feComposite in="expanded" in2="SourceAlpha" operator="out" result="outline"/>
      <feFlood flood-color="#071018" flood-opacity="0.98" result="bezelColor"/>
      <feComposite in="bezelColor" in2="outline" operator="in" result="bezel"/>
      <feMerge>
        <feMergeNode in="bezel"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <image href="${imageDataUrl(background)}" x="0" y="0" width="${width}" height="${height}" preserveAspectRatio="xMidYMid slice"/>
  <rect width="${width}" height="${height}" fill="url(#leftShade)"/>

  <g>
    <rect x="104" y="93" width="130" height="35" rx="17.5" fill="#174E45" stroke="#68E0C0" stroke-opacity="0.32"/>
    <text x="169" y="116" text-anchor="middle" fill="#BDF8E7" font-family="Avenir Next, Helvetica Neue, sans-serif" font-size="13" font-weight="800" letter-spacing="3">ABLERITE</text>

    <text x="104" y="166" fill="#6FE5C4" font-family="Avenir Next, Helvetica Neue, sans-serif" font-size="14" font-weight="800" letter-spacing="2.5">YOUR LIFE, WORKING TOGETHER</text>
    <text x="101" y="224" fill="#FFFFFF" font-family="Avenir Next, Helvetica Neue, sans-serif" font-size="40" font-weight="800" letter-spacing="-1.5">
      <tspan x="101" dy="0">One app. Your whole</tspan>
      <tspan x="101" dy="52">life, connected.</tspan>
    </text>
    <text x="104" y="334" fill="#C9F4E8" font-family="Avenir Next, Helvetica Neue, sans-serif" font-size="18" font-weight="600">
      <tspan x="104" dy="0">Finance, goals, learning, wellness and coaching—</tspan>
      <tspan x="104" dy="28">working together around you.</tspan>
    </text>
  </g>

  ${phoneSvg({ src: screens.finance, x: 620, y: 148, w: 170, rotate: -5 })}
  ${phoneSvg({ src: screens.exploration, x: 820, y: 137, w: 184, rotate: 5 })}
  ${phoneSvg({ src: screens.media, x: 680, y: 54, w: 226 })}
</svg>`;

const svgPath = path.join(tempDir, "feature-graphic.svg");
const renderedPath = path.join(tempDir, "feature-graphic-rendered.png");
writeFileSync(svgPath, svg, "utf8");

execFileSync(
  "rsvg-convert",
  [
    "--width",
    String(width),
    "--height",
    String(height),
    "--output",
    renderedPath,
    svgPath,
  ],
  { stdio: "inherit" },
);

execFileSync(
  "magick",
  [
    renderedPath,
    "-background",
    "#075F59",
    "-alpha",
    "remove",
    "-alpha",
    "off",
    "-strip",
    `PNG24:${featureGraphic}`,
  ],
  { stdio: "inherit" },
);

execFileSync(
  "magick",
  [
    iconSource,
    "-resize",
    "512x512!",
    "-alpha",
    "on",
    "-strip",
    "-define",
    "png:color-type=6",
    `PNG32:${playIcon}`,
  ],
  { stdio: "inherit" },
);

rmSync(tempDir, { recursive: true, force: true });

console.log(`Generated Google Play assets in ${outputDir}`);
