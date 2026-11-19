# Handoff notes

## What works (tested)
- `tests/smoke_test.sh`, 17 checks, all passing on macOS 26.6.2 (Apple silicon):
  - the app compiles
  - save a plain key and a key containing quotes, a backslash, `$`, backticks and spaces, and read both back exactly
  - overwriting a key, `has`, `list` (names only, no values), delete
  - names with spaces or `;` are refused
  - no temp files are left behind
  - pasted whitespace is trimmed
- The original private version of this app has been in daily use since October 2026 for handing keys to AI coding sessions.

## Not tested
- The dialogs themselves are not driven by the smoke test. The logic behind them (trim, name check, save) is covered by the tests, but the full click-through of the rebuilt app needs one hand test before release.
- Intel Macs and macOS versions older than 26. Everything it uses has been in macOS for many years, so no problems are expected.
- Keychains other than the default login keychain.

## Changed from the original
1. **Security fix:** the original passed the secret to `security add-generic-password -w <value>` as a command-line argument, which is briefly visible in the process list. It now goes through a private temp file read on stdin.
2. Key names are validated, so a name can no longer break the command.
3. Pasted values are trimmed, and multi-line values are refused with a clear message instead of failing silently.
4. The app reads the value back and checks it matches, and shows an error if not. The original always said "Saved".
5. `dropkey get` tells "no such key" apart from "the Keychain refused" (e.g. locked).
6. Added the `bin/dropkey` reader, the agent instructions snippet and the smoke test.
7. The service name is now the generic `drop-key`.

## Known soft spots
- `dropkey list` parses `security dump-keychain` text output, which Apple doesn't document as stable. Only `list` depends on it; `get`, `has` and `delete` don't.
- The private temp file trade-off is explained in ARCHITECTURE.md.

## Open decisions
- Whether to ship a signed, downloadable build (needs an Apple Developer ID).
- Whether to add Touch ID mode (see ROADMAP.md).
