# Ablerite Mobile — Session Handoff

Written for a fresh Claude Code instance picking up this project cold. Read this
before touching code — it captures conventions and gotchas that aren't obvious
from the code alone.

## The two repos

- **Mobile app (this repo)**: `/Users/admin/Desktop/Ablerite Mobile/ableritemobile`
  — Flutter, targets iOS/Android. Not a git repo as of this writing (no `.git`
  found at the working directory root) — confirm with `git status` before
  assuming version control is available.
- **Desktop web app**: `/Users/admin/Desktop/Ablerite Website/ablerite-web-app`
  — React/TypeScript (Vite), single giant `index.tsx` (~9000+ lines) plus a
  few extracted components (`TasksBoard.tsx`, `FreeformBoards.tsx`,
  `CalendarModal.tsx`, `MiniDatePicker.tsx`, etc). This one **is** a git repo,
  and as of this session had **uncommitted local changes** to `FreeformBoards.tsx`,
  `TasksBoard.tsx`, `index.tsx`, `vite.config.ts`, plus untracked
  `CalendarModal.tsx` / `MiniDatePicker.tsx`. Run `git status` there before
  assuming the working tree matches origin — the desktop app is mid-feature
  (calendar/date-picker work) and not everything is committed.

Both apps share one Supabase backend/schema. When a feature exists on both
platforms, check desktop's implementation for the data contract before
building the mobile side — mobile is generally the one catching up.

## Data model gotchas (learned the hard way this session)

- The `items` Postgres table is a shared dumping ground across nearly every
  feature (goals, quick tasks, goal-linked tasks, vision board images,
  journal entries, notebooks, expectations, cosmic orders, MBS logs...),
  disambiguated by a `section` column. Don't assume a column means the same
  thing across sections.
- **Two parallel task systems exist, don't conflate them:**
  1. **Quick Tasks / custom boards** (`todo_page.dart` on mobile,
     `FreeformBoards.tsx` on desktop) — tasks live as a **JSON blob** in the
     `task_boards.lists` column, not as `items` rows.
  2. **Goal-linked task boards** (`task_board_page.dart` +
     `goal_detail_page.dart`'s inline task list on mobile, `TasksBoard.tsx`
     on desktop) — tasks are real rows in `items` with `section: 'tasks'`,
     `parent_id` pointing at the goal (or at another task, for one level of
     "sub-task board" nesting).
- **Due-date field naming differs by which system you're in** — this bit us
  once already:
  - `items` table columns are real Postgres columns → always snake_case:
    `due_date`.
  - The `task_boards.lists` JSON blob is just a serialized JS/Dart object —
    desktop's `FreeformBoards.tsx` writes it as **camelCase `dueDate`**.
    Mobile's `todo_page.dart` / `calendar_page.dart` read `dueDate` first,
    falling back to legacy `due_date` for old rows, and write `dueDate` to
    stay in sync with desktop. If you touch this JSON blob, match desktop's
    field names exactly — nothing enforces a shared schema here.

## The Calendar feature

`lib/ui/calendar_page.dart` aggregates due-dated items from all three
sources above (goals, `items`-table tasks, `task_boards` blob tasks) into one
grouped list (Overdue / Today / Tomorrow / upcoming). Tapping a row navigates
to the *actual* owning page (not an in-place editor):
- Goals → `GoalDetailPage`.
- Blob tasks → `TodoPage`, extended with `initialBoardId`/`initialListId`/
  `initialTaskId` params so it opens on the right board/list and
  auto-opens that task's edit dialog.
- `items`-table tasks → `TaskBoardPage`, extended with `initialTaskId`;
  resolves the owning board by walking `parent_id` one hop (goal, or a
  promoted parent task) since a task's `parent_id` isn't always the goal
  directly.

Entry point: calendar icon in the header of all three main hubs —
**Action Center** (`coach_hub.dart`), **Exploration** (`hubs/exploration_hub.dart`),
and **MBS** (`hubs/mbs_hub.dart`) — each alongside a Text Coaching sparkles
icon and the guide book icon (see "Header shortcut icons" below). Note: the
file `action_center_page.dart` is **not** the real Action Center — it's wired
to the "Self Development" nav slot. The actual Action Center (center nav
button) is `coach_hub.dart`. This tripped us up once; don't trust filenames
here, check `main_scaffold.dart`'s `_buildTabPage` switch for the real
tab→widget mapping.

## Header shortcut icons (Text Coaching + Calendar + Guide)

All three main hubs — `coach_hub.dart` (Action Center), `hubs/exploration_hub.dart`,
`hubs/mbs_hub.dart` (MBS) — share the same three-icon `headerAction` Row
passed into the shared `HubHeroSection` (`widgets/hub_intro_panel.dart`): a
sparkles (`Icons.auto_awesome`) **Text Coaching** shortcut, a **Calendar**
shortcut, then the **Guide** book icon, in that order. Each icon has a
matching `SpotlightStep` in that hub's `walkthroughSteps` list and a short
paragraph in that hub's guide page.

The Text Coaching shortcut used to live on the Home page AppBar instead
(paywall-gated via `SubscriptionService().showPaywallIfNeeded()` before
pushing `ChatPage()`). It was moved off Home and onto the three hub headers
by product decision — Home's AppBar was getting crowded next to the new
live clock (see below), and Text Coaching fits more naturally next to each
hub's own content than as a Home-page-only shortcut. If you add a fourth
main hub, replicate this exact Row pattern rather than inventing a new
layout — Row + matching walkthrough step + guide paragraph is the
established convention now.

Calendar previously only existed on Action Center; it was added to
Exploration and MBS in the same pass so all three hubs expose it
consistently, not just Action Center.

## Android fullscreen system UI

The app runs in true immersive fullscreen (`SystemUiMode.immersiveSticky`),
hiding both the status bar and nav bar by default. This is centralized in
`lib/services/system_ui_service.dart` (`SystemUiService.apply()` /
`.reapply()`) — every place that touches `SystemChrome.setEnabledSystemUIMode`
(`main.dart`, `main_scaffold.dart`'s resume handler, `affirmations_page.dart`,
`ambient_focus_overlay.dart`) goes through this service so there's one
tracked "current mode," correctly restored on app resume. Do **not** call
`SystemChrome.setEnabledSystemUIMode` directly anywhere new — route it
through `SystemUiService`, or a future fullscreen page will silently break
this.

Because the status bar is hidden, the Home page (`home_page.dart`) has a
live clock in the AppBar `leading` slot (far left) as a stand-in. Home's
AppBar `actions` no longer includes a Text Coaching shortcut — that moved to
the hub headers (see "Header shortcut icons" above); Home's actions are now
just Focus Mode, Pro Desktop App, Guide, Help/Walkthrough, Settings.

## Guide pages

Every main hub now has a "book" icon next to its walkthrough "?" icon,
opening a guide page built on the shared `lib/ui/widgets/guide_page.dart`
(`GuidePage` + `GuideSectionData`). Five guides exist:
`HomeGuidePage`, `SelfDevelopmentGuidePage`, `ActionCenterGuidePage`,
`ExplorationGuidePage`, `MBSGuidePage`. Style is deliberately copied from the
pre-existing `CosmicOrderingGuidePage` (hero banner + icon-titled section
cards) — don't diverge from that pattern without a reason.

Guide sections can carry an optional `imageAsset` — a cropped screenshot
shown full-width (aspect ratio preserved, `BoxFit.fitWidth`, **not** cropped
further in-app) with a tap-to-zoom full-screen viewer. Screenshots live in
`assets/guide_images/` (registered in `pubspec.yaml`). If you add more:
raw source screenshots the user provides go in
`assets/help_guide images/<Theme>/` (note the space in the folder name —
it's intentionally *not* declared as a pubspec asset, so raw screenshots
never get bundled into the app). Crop them with ImageMagick before using:

```bash
magick "source.png" -crop "1206x<HEIGHT>+0+190" +repage "assets/guide_images/name.png"
```

The `+0+190` y-offset is calibrated to start right below the iPhone status
bar / Dynamic Island. Keep the bottom edge (`190 + HEIGHT`) under ~2340px to
stay clear of the bottom system nav bar — i.e. `HEIGHT` should not exceed
~2150 for a full-page crop on a 2622px-tall source screenshot. Verify every
crop by actually reading it back (the `Read` tool renders images) — don't
trust height math alone, we got it wrong twice this session before nailing
the offset.

## Goal progress bar — deliberately removed, don't re-add

Both platforms used to show a task-completion-based progress bar/percentage
on goals (mobile: a dedicated section on `goal_detail_page.dart`; desktop: inline
in the goals accordion list, `index.tsx` `renderGoal`). This was **removed
by product decision**, not because it was unused — the reasoning: tying
"progress" to task completion is misleading when tasks get finished and new
ones added continuously, so the percentage doesn't mean what it looks like
it means. Desktop's "Mark Goal as Complete" button also used to warn if a
goal had incomplete tasks before archiving; that check was removed for the
same reason. If asked to add goal progress back, raise this history first —
it wasn't an oversight.

## Recent fix log (this session, roughly chronological)

- Fixed MBS Metrics page text-overflow (legend rows lacked `Flexible`/
  ellipsis).
- Fixed two real bugs in MBS habit reminders
  (`lib/services/notification_service.dart`,
  `lib/ui/widgets/habit_tracker_widget.dart`): notification IDs were
  tracked in a volatile in-memory map that reset every app restart (now a
  deterministic hash of the habit id); and habit mutators silently dropped
  updates for not-yet-persisted default habits instead of appending them.
- Built the Calendar feature end-to-end (see above).
- Fixed the "AI keeps re-greeting" chat bug by making the system prompt's
  greeting protocol explicitly conditional on turn count (`chat_page.dart`).
- Renamed the in-app AI coach from Isabella to Diana.
- Fixed vision board canvas corrupting saved layouts on open — it forces
  landscape orientation but was clamping positions against transient
  portrait constraints before the OS rotation finished.
- Fixed journal entry dialog not blurring the background list
  (`BackdropFilter` was missing).
- Multiple rounds on Android fullscreen — landed on `immersiveSticky` via
  `SystemUiService` (see above); earlier attempts (`SystemUiMode.manual` +
  a forced re-apply callback) were tried and superseded, don't resurrect
  them.
- Home page layout: moved "Ablerite" text out of the AppBar into a row with
  the welcome greeting pushed to the far right; added a live clock to the
  AppBar `leading` slot.
- Built the 5-guide-page system described above, including cropped
  screenshot support.
- Removed the goal progress bar from both platforms (see above).
- Replaced Home's Share button with a sparkles Text Coaching shortcut, then
  moved that shortcut off Home entirely and onto the header of all three
  main hubs (Action Center, Exploration, MBS) alongside a new Calendar
  shortcut on Exploration and MBS (Action Center already had one) — see
  "Header shortcut icons" above for the current state.

## Things worth double-checking before you trust them

- **Desktop repo's uncommitted changes** — confirm current `git status`/`git diff`
  there before assuming the `due_date`/`dueDate` contract or the calendar
  UI described above still matches what's on disk.
- **No automated tests observed** in either repo during this session —
  verification was done via `flutter analyze` + manual screenshot review,
  not `flutter test`. If tests exist, find and run them; don't assume
  `flutter analyze` passing means the feature works.
- **RevenueCat / Supabase MCP connectors were unauthenticated** in this
  session (tools deferred, no OAuth flow available) — if you need to touch
  Supabase schema or RevenueCat config directly rather than through app
  code, you'll need the user to authenticate those first.
