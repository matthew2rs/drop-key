# Roadmap

## Possible next steps
- **Touch ID per read** (optional): a small Swift helper using `SecAccessControl` with `.userPresence`, so `dropkey get` needs a fingerprint. This trades away unattended agent runs, so it would be opt-in per key.
- **Signed, notarised release build**, so people can download the app instead of building it. That needs an Apple Developer ID.
- **`dropkey env <name>=<VAR> ... -- <command>`**: run a command with keys injected as environment variables, so the agent never handles the value at all.
- **Menu-bar version** with a list of saved names and one-click delete.

## Intentional limits
- macOS only.
- One user, one Mac. No sync and no sharing.
- Single-line secrets only (see SETUP.md for PEM keys).
- No GUI for reading keys back. Reading is the agent's job; viewing is what Keychain Access.app is for.
