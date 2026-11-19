# Drop Key

**Stop pasting API keys into AI chats.**

Drop Key is a tiny Mac app. You give a key a name, paste it into a hidden box, and it's saved in your Mac's Keychain (the same encrypted store your passwords live in). Your AI coding agent (Claude Code, Cursor, Codex, anything with a terminal) then reads the key by name, straight into the command that needs it. The key never appears in the chat, in your shell history or in a text file.

```
You:    open Drop Key → name "openai-api" → paste → Save
Agent:  OPENAI_API_KEY="$(dropkey get openai-api)" python3 run.py
```

## Who it's for

People who run AI agents on their own Mac and keep hitting "paste your API key here". Every key you paste into a chat sits in that transcript forever, and often in logs and synced history too.

## What it does

- A double-click app with two dialogs: a name, then the key in a hidden field.
- Saves it as a Keychain item (service `drop-key`, account = the name you gave it).
- `bin/dropkey`, a small command-line reader: `get`, `has`, `list` (names only), `delete`.
- A ready-made snippet for your agent's instructions file, so it knows to ask you to "Drop Key it" instead of asking you to paste (`examples/CLAUDE.md.snippet`).
- The secret never goes on a command line, where other processes could see it. See ARCHITECTURE.md.

## What it does NOT do

- It isn't a password manager, a team vault or a sync service. It's one Mac, one user.
- Windows and Linux aren't supported. It uses the macOS Keychain.
- It doesn't stop an agent from printing a key once it reads it. Tell your agent to pipe keys straight into commands and never echo them (the snippet does this).
- No Touch ID prompt for each read (see ROADMAP.md).

## Quick start

```bash
git clone https://github.com/matthew2rs/drop-key.git && cd drop-key
./tests/smoke_test.sh        # optional: proves it works on your Mac (uses a throwaway Keychain entry)
./build.sh                   # makes "Drop Key.app"
rm -rf "/Applications/Drop Key.app" && mv "Drop Key.app" /Applications/
sudo mkdir -p /usr/local/bin && sudo ln -sf "$(pwd)/bin/dropkey" /usr/local/bin/dropkey
```

Then add `examples/CLAUDE.md.snippet` to your agent's instructions file. Full detail is in SETUP.md.

## No dependencies

Only what ships with macOS: AppleScript (`osacompile`, `osascript`), `/usr/bin/security` and bash.

## Similar tools

If you want more (Touch ID per read, encrypted handoff, agent detection), look at NoxKey, KeepKeys, Crystl or mxkey. Drop Key is the minimum version: about 100 lines you can read in five minutes and trust.

## Licence

MIT. See LICENSE.
