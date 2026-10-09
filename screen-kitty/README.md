# Screen Kitty

A pixel-art cat that lives on your iPhone and bugs you until you do the
things. Desktop Goose energy, iOS edition: a mood-driven kitty that is
sweet when you're productive and increasingly furious when you're not.

**No Mac required.** The app is written anywhere, compiled by GitHub
Actions on macOS runners, and sideloaded to your phone from Windows.

## What it does

- **In-app kitty** — animated pixel cat whose animation, colors, and
  constant commentary follow its mood (happy / content / uneasy / grumpy /
  furious)
- **Task list** — add tasks, optionally with due times
- **Notifications** — due reminders, overdue escalations that get meaner
  as the mood drops, a daily "wrap it up" nag, and a streak-rescue ping
- **Streaks + mood engine** — completing tasks makes the kitty happier;
  overdue tasks and ignored nags make it grumpier. Mood decays toward
  neutral over ~hours
- **Home screen + Lock Screen widgets** — kitty pose, mood word, next
  task with live countdown, streak. The medium widget has a "done"
  button that completes the focus task directly from the home screen
- **Dynamic Island** — a Live Activity with the kitty's face, current
  task, mood, streak, and a self-counting clock until the next due time

## Architecture

```
Packages/KittyKit    pure-Foundation logic: mood engine, nag planner,
                     sass generator, pixel art. swift test runs on Linux
Shared/              code both targets compile: App Group store paths,
                     pixel -> UIImage renderer, ActivityKit attributes
App/ScreenKitty      SwiftUI app: home, tasks, settings, notifications,
                     Live Activity controller
Widget/              widget extension: home/lock widgets, Dynamic Island,
                     interactive complete-task AppIntent
project.yml          XcodeGen spec -> CI generates the .xcodeproj
.github/workflows    Linux logic tests + macOS unsigned IPA build
```

Editing the personality: all kitty dialogue lives in
`Packages/KittyKit/Sources/KittyKit/Sass/MessageBank.swift`. Edit the
strings, push, reinstall. That's the whole API.

Editing the cat: frames are 16x16 character grids in
`KittyFrames.swift` (each row is authored as four 4-char chunks so the
width is structurally correct). Run `check_art.ps1` after editing.
Palette is in `PixelFrame.swift`.

## Build (every time you change something)

1. Commit + push to `main` on GitHub (public repo = unlimited macOS CI).
2. Actions tab -> latest `ci` run -> **build-ipa** job -> download
   `ScreenKitty-unsigned-ipa` artifact.
3. Unzip on Windows, then sideload (below).

If the `logic-tests` job fails, the IPA isn't built — fix the tests.

## One-time Windows setup

1. **Sideloadly** — download from https://sideloadly.io and install.
2. **Apple USB drivers** — install the *web* (direct download) versions
   of 64-bit iTunes and iCloud from apple.com. The Microsoft Store
   versions do NOT include the drivers Sideloadly needs. Reboot after.
3. **iPhone** — Settings > Privacy & Security > Developer Mode > on
   (requires a reboot). Plug in via USB and tap "Trust This Computer".

## Sideload ritual

1. Open Sideloadly, drag `ScreenKitty-unsigned.ipa` into it.
2. Enter your Apple ID + password (accept the 2FA prompt).
3. Start. Sideloadly registers the App IDs, builds a free profile with
   the App Group capability, re-signs, and installs.
4. On the phone: Settings > General > VPN & Device Management > trust
   your developer profile. First launch may need this once.
5. Long-press the home screen > + > add the **Screen Kitty** widget.
   Background the app to summon the Dynamic Island kitty.

### The 7-day rule

Free Apple ID profiles expire after **7 days**. Set a repeating calendar
reminder for day 6: re-sideload the same IPA with the same Apple ID.
That refreshes the app **in place** — tasks, streak, and mood survive.
If you let it expire and delete it, the data goes with it.

### Free-account limits

- 3 sideloaded apps installed at once — keep slots free
- 10 App ID registrations per 7 days — **never rename the bundle IDs**
  (`com.domin.ScreenKitty` / `...ScreenKittyWidget` are pinned on purpose)
- The widget extension registers its own App ID but rides in the same
  install slot

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Sideloadly can't see the phone | Store-installed iTunes, missing drivers — use the apple.com web installers, reboot |
| Widget shows a sad fallback / "app group MISSING" in Settings | The App Group entitlement didn't survive re-signing; make sure the CI `ldid` step ran (it's in ci.yml — don't remove it) |
| No notifications | Allow them in Settings > notifications, or in-app Settings > "allow nagging" |
| Dynamic Island shows nothing | Background the app with at least one open task; check the activity isn't expired (>8h) — reopen the app to restart it |
| "Unable to install" | Free account out of app slots or App ID budget; delete an old sideloaded app or wait out the 7-day window |
| Apple server error in Sideloadly | Retry in a few minutes; transient anisette issues are common |

## Known v1 limits

- The Dynamic Island doesn't update while the app is closed beyond its
  self-counting timer; it refreshes on next app foreground (iOS gives
  background updates a tiny, unreliable budget — the copy reads as the
  kitty napping, not a bug)
- The widget's "done" button updates widgets immediately but the island
  refreshes on next app open (extensions can't poke each other's activities)
- Kitty "pokes" are notifications, not island pop-ups (`AlertConfiguration`
  requires push, which needs a paid account)

## Phase 2 ideas

- Screen Time / DeviceActivity integration: real doom-scroll detection,
  kitty reacts to Instagram marathons
- Focus timer (pomodoro) with a sitting kitty
- Export/import the kitty brain (it's one JSON file)
- More outfits, accessory pixels, seasonal palettes
- App Store route with a paid developer account (push-updated island)
