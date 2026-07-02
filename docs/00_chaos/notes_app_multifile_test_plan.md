# Notes App Multifile Test Plan

Date: 2026-06-30

This note defines the next proc-17 test case.

## Goal

Test whether proc-17 can move beyond single-file stdout code generation.

Target pipeline:

```text
idea -> plan -> multi-file code -> workspace write -> tests -> possible fix pass
```

The goal is not to prove that a model can write a notes app.

The goal is to test the body loop:

```text
plan mode
build mode
△ code manifest
workspace sandbox write
runtime test feedback
optional rebuild/fix
```

## Product

Mini Notes App CLI.

Workspace:

```text
sandbox/projects/notes_app
```

Features:

```text
add "text"      add note
list            list notes
done ID         mark note done
delete ID       delete note
```

Storage:

```text
JSON file notes.json
note fields: id, text, done
```

Files:

```text
sandbox/projects/notes_app/notes_app/models.py
sandbox/projects/notes_app/notes_app/storage.py
sandbox/projects/notes_app/notes_app/main.py
sandbox/projects/notes_app/tests/test_notes.py
```

No external libraries.

Tests use:

```text
python3 -m unittest discover tests
```

## Plan Mode Prompt

Ask for blueprint only.

Expected content:

```text
project files
responsibilities per file
functions
storage rules
CLI flow
tests
residue / assumptions
```

No code in plan mode.

## Build Mode Prompt

Build mode receives the blueprint and must return strict multi-file format:

````text
FILE: sandbox/projects/notes_app/notes_app/models.py
```python
...
```

FILE: sandbox/projects/notes_app/notes_app/storage.py
```python
...
```

FILE: sandbox/projects/notes_app/notes_app/main.py
```python
...
```

FILE: sandbox/projects/notes_app/tests/test_notes.py
```python
...
```
````

The strict format matters because the body does not yet have a multi-file manifest parser.
The bridge may be manual or scripted.

## Manual Bridge

Until proc-17 owns multi-file write:

```text
extract FILE blocks from substrate_result
make_dir sandbox/projects/notes_app
make_dir sandbox/projects/notes_app/notes_app
make_dir sandbox/projects/notes_app/tests
write files through fs tool context=workspace
run tests
```

## Success

Success means:

```text
all files created under sandbox/
no write outside sandbox/
python compiles
unittest passes
CLI basic behavior is coherent
```

## Useful Failure

Failure is useful if:

```text
tests fail with clear error
runtime feedback can be given to build mode
second build/fix pass can repair files
```

This would be the first real multi-turn repair test.

## Expected Pressure

This test will expose pressure around:

```text
multi-file manifest parsing
workspace file write organ
test runner organ
repo mutation manifest
fix-pass protocol
```

It is intentionally small enough to debug by hand.

