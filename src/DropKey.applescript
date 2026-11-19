-- Drop Key
-- Saves a named secret (an API key, a token) into your macOS Keychain, so you
-- never have to paste it into an AI chat, a terminal or a text file.
-- Your AI agent then reads it by name with:  bin/dropkey get <name>
--
-- Build:  ./build.sh   (makes "Drop Key.app")
-- Licence: MIT (see LICENSE)

-- Every key is stored as a Keychain "generic password" under this service.
-- Change it here AND set DROPKEY_SERVICE for bin/dropkey if you want another one.
property serviceName : "drop-key"

on run argv
	-- Test mode, used by tests/smoke_test.sh only:
	--   osascript src/DropKey.applescript --save <name> <value>
	if class of argv is list and (count of argv) is 3 and item 1 of argv is "--save" then
		return saveKey(item 2 of argv, item 3 of argv)
	end if

	set keyName to askName()
	if keyName is "" then return
	set keyValue to text returned of (display dialog "Paste the key for: " & keyName default answer "" with title "Drop Key" buttons {"Cancel", "Save"} default button "Save" with hidden answer)
	set keyValue to trimEnds(keyValue)
	if keyValue is "" then return
	try
		saveKey(keyName, keyValue)
		display notification "Saved \"" & keyName & "\" to your Keychain. Tell your AI it's there." with title "Drop Key"
	on error errMsg
		display dialog "Drop Key could not save that key: " & errMsg with title "Drop Key" buttons {"OK"} default button "OK" with icon stop
	end try
end run

on askName()
	repeat
		set n to text returned of (display dialog "What is this key called? Letters, numbers, dots, dashes and underscores only (e.g. openai-api)" default answer "" with title "Drop Key" buttons {"Cancel", "Next"} default button "Next")
		set n to trimEnds(n)
		if n is "" then return ""
		if validName(n) then return n
		display dialog "Use only letters, numbers, dots, dashes and underscores." with title "Drop Key" buttons {"OK"} default button "OK"
	end repeat
end askName

-- Saves without ever putting the secret on a command line (where any process
-- list could see it). The command goes into a private temp file that only you
-- can read, `security -i` reads it from stdin, and the file is deleted.
on saveKey(keyName, keyValue)
	if not validName(keyName) then error "bad key name"
	if keyValue contains linefeed or keyValue contains return then error "the key has a line break in it"
	set cmd to "add-generic-password -U -s " & q(serviceName) & " -a " & q(keyName) & " -l " & q("Drop Key: " & keyName) & " -T /usr/bin/security -w " & q(keyValue) & linefeed
	set tmpPath to do shell script "umask 077; /usr/bin/mktemp \"${TMPDIR:-/tmp}/dropkey.XXXXXX\""
	try
		set fh to open for access (POSIX file tmpPath) with write permission
		set eof of fh to 0
		write cmd to fh as «class utf8»
		close access fh
	on error errMsg
		try
			close access (POSIX file tmpPath)
		end try
		do shell script "/bin/rm -f " & quoted form of tmpPath
		error errMsg
	end try
	do shell script "/usr/bin/security -i < " & quoted form of tmpPath & " >/dev/null 2>&1; /bin/rm -f " & quoted form of tmpPath
	-- Read it back and compare, so a failed overwrite can't leave an old value
	-- behind while we say "saved". The value comes back through a pipe, never argv.
	try
		set stored to do shell script "/usr/bin/security find-generic-password -s " & quoted form of serviceName & " -a " & quoted form of keyName & " -w 2>/dev/null"
	on error
		error "the Keychain did not accept it"
	end try
	considering case
		if stored is not keyValue then error "the Keychain still holds a different value"
	end considering
	return "saved"
end saveKey

-- Quote a value for `security -i`: wrap in double quotes, escape \ and ".
on q(s)
	set s to replaceText(s, "\\", "\\\\")
	set s to replaceText(s, "\"", "\\\"")
	return "\"" & s & "\""
end q

on validName(n)
	set ok to "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"
	if (length of n) > 100 then return false
	repeat with c in characters of n
		considering case
			if ok does not contain (c as text) then return false
		end considering
	end repeat
	return true
end validName

on trimEnds(s)
	set ws to {space, tab, linefeed, return}
	repeat while s is not "" and (character 1 of s) is in ws
		if (length of s) is 1 then return ""
		set s to text 2 thru -1 of s
	end repeat
	repeat while s is not "" and (character -1 of s) is in ws
		if (length of s) is 1 then return ""
		set s to text 1 thru -2 of s
	end repeat
	return s
end trimEnds

on replaceText(s, findText, replaceWith)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set parts to text items of s
	set AppleScript's text item delimiters to replaceWith
	set s to parts as text
	set AppleScript's text item delimiters to oldDelims
	return s
end replaceText
