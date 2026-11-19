# Setup

Tested on macOS 26.6.2 (Apple silicon) with the built-in AppleScript, bash 3.2 and `/usr/bin/security`. There are no third-party dependencies and nothing to install from the internet.

## 1. Get the code

```bash
git clone https://github.com/matthew2rs/drop-key.git
cd drop-key
```

## 2. Prove it works on your Mac (optional, 10 seconds)

```bash
./tests/smoke_test.sh
```

This saves and reads test keys under a throwaway Keychain service (`drop-key-selftest-<pid>`) and deletes them at the end. It never touches the `drop-key` service. You should see `All smoke tests passed`.

## 3. Build the app

```bash
./build.sh
rm -rf "/Applications/Drop Key.app" && mv "Drop Key.app" /Applications/
```

**First launch:** an app you build yourself normally opens straight away. If macOS ever says it "can't be opened" (for example after you copy it to another Mac), right-click it, choose **Open**, then **Open** again.

**Notifications:** macOS may ask whether "Drop Key" can send notifications. Allow it if you want the "Saved" confirmation. Saving works either way.

## 4. Put the reader on your PATH

```bash
sudo mkdir -p /usr/local/bin
sudo ln -sf "$(pwd)/bin/dropkey" /usr/local/bin/dropkey
```

Use the symlink, not a PATH line in `~/.zshrc`. AI agents usually run commands in non-interactive shells that skip `~/.zshrc`, so they wouldn't find `dropkey`. If you'd rather use PATH, put it in `~/.zshenv`.

Check it: `dropkey list` (prints nothing yet).

## 5. Tell your agent

Paste `examples/CLAUDE.md.snippet` into your agent's instructions file:

- Claude Code: `CLAUDE.md` in your project, or `~/.claude/CLAUDE.md` for every project
- Cursor: `.cursorrules` or a project rule
- Codex and others: `AGENTS.md`

From then on, when the agent needs a key, it asks you to "Drop Key it as `<name>`".

## Using it

1. Open **Drop Key**.
2. Type a name: letters, numbers, dots, dashes and underscores only (e.g. `stripe-test`).
3. Paste the key into the hidden field and click **Save**. Spaces or line breaks pasted around it are trimmed off.
4. Saving the same name again replaces the old value.

Reading, from a terminal or an agent:

| Command | What it does |
|---|---|
| `dropkey get <name>` | prints the key (use inside `$(...)` or a pipe) |
| `dropkey has <name>` | exit code 0 if it exists, prints nothing |
| `dropkey list` | key names only |
| `dropkey delete <name>` | removes it |

You can also see and delete the items in **Keychain Access.app**: search for `drop-key`.

## Using a different service name

The default service is `drop-key`. To change it, edit `property serviceName` at the top of `src/DropKey.applescript`, rebuild, and set `export DROPKEY_SERVICE=<same name>` for the reader. The two must match.

## Gotchas

- **Keychain prompt on read.** Items are saved with `/usr/bin/security` on their access list, so `dropkey get` reads them without a prompt. If you move an item to a different keychain or edit its access control in Keychain Access, macOS may start asking for your login password on each read.
- **Locked keychain.** If your login keychain is locked (rare on a logged-in Mac, common over SSH), reads fail. Run `security unlock-keychain` first.
- **SSH and remote machines.** It reads the keychain of the Mac it runs on. Keys don't travel to servers. For a cloud host, set the key in that host's own secret settings.
- **Multi-line secrets** (e.g. PEM private keys) are refused, because the save goes through a line-based command. Store the file path instead, or base64 it first.
- **Timezones, regions:** none. Nothing in Drop Key depends on location.
