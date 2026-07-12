---
name: windows-safe-text-write
description: >-
  Safely write or edit non-ASCII text (中文, Japanese, accented characters,
  emoji) in files on Windows, where PowerShell arguments, heredocs, and
  cross-agent prompt text corrupt bytes silently. Use whenever a task
  involves creating or changing any non-ASCII string in code, tests, data,
  or docs on a Windows machine — especially when the change is dispatched to
  another agent.
---

# Windows-Safe Non-ASCII Text Writing

## The failure this prevents

On Windows, non-ASCII characters passed through PowerShell 5.1 arguments,
Git Bash heredocs, `echo`, or a dispatch prompt get transcoded through legacy
code pages and arrive corrupted — silently. Observed in production:
「電腦」 became `?餉N`, AND the test suite stayed green because the test
expectations were corrupted by the same channel. A green suite proves
nothing about byte correctness here.

Two rules follow:

1. Non-ASCII bytes never travel through a shell channel. They are generated
   locally, from pure-ASCII source, by a real interpreter.
2. Done means byte-verified at runtime, not tests-passed.

## Procedure

### Step 1: Get the codepoints (ASCII-only representation)

Express every non-ASCII character as `\uXXXX` (or `\u{XXXXX}` for codepoints
above FFFF). Example: 電腦 is `\u96FB\u8166`. To find codepoints for a string
you must not paste through the shell, read them from an existing correct
file:

```bash
node -e "const s=require('fs').readFileSync('path/to/source.js','utf8'); for (const ch of s.slice(100,120)) console.log(ch.codePointAt(0).toString(16))"
```

### Step 2: Write through node from pure-ASCII source

Create the content inside a node/python script whose source contains ONLY
ASCII — the escapes are decoded by the interpreter, never by the shell:

```bash
node -e "const fs=require('fs'); const label='\u96FB\u8166'; let s=fs.readFileSync('src/ui.js','utf8'); s=s.replace('OLD_PLACEHOLDER', label); fs.writeFileSync('src/ui.js', s, 'utf8')"
```

- Python works too (`chr(0x96FB)+chr(0x8166)`), but call it as `python` or a
  full path — `python3` on Windows is often a Store stub that silently does
  nothing.
- Never put the literal character in the `-e` argument, a heredoc, or an
  `echo`; that is exactly the corrupting channel.

### Step 3: Verify the bytes after writing

Read the file back and print the region as JSON — `JSON.stringify` does not
escape CJK, so instead compare codepoints, which keeps both the check and
its output pure ASCII:

```bash
node -e "const s=require('fs').readFileSync('src/ui.js','utf8'); const i=s.indexOf('\u96FB\u8166'); console.log(i>=0 ? 'FOUND at '+i : 'MISSING'); if(i>=0) console.log([...s.slice(i,i+2)].map(c=>c.codePointAt(0).toString(16)).join(' '))"
```

Expected output: `FOUND at <n>` and `96fb 8166`. `MISSING` or replacement
characters (codepoint `fffd`) mean the write failed — do not proceed.

### Step 4: Verify at runtime, not just in tests

If the string is user-visible or stored, add a Required Verification step
that checks the RUNNING artifact (rendered DOM, HTTP response, stored file)
with the same codepoint-comparison technique. Tests alone are insufficient
because test expectations can be corrupted by the same channel as the code.

## For orchestrators writing task contracts

- Any task touching non-ASCII strings must list this skill under
  `Relevant Skills` and include a byte-level runtime check in Required
  Verification.
- Put the needed strings into the task file as `\uXXXX` escapes (the task
  file travels through dispatch channels too).
- Such a task is never `LIGHT` effort unless the contract spells out the
  exact commands (see `MODELS.md` selection rules).
