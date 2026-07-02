# Notes App Multifile Test Results

Date: 2026-06-30

This note records the first multi-file workspace project test.

## Goal

Test proc-17 beyond single-file stdout code generation.

Target pipeline:

```text
plan -> build -> multi-file manifest -> workspace write -> unittest -> CLI smoke
```

## Task

Mini Python Notes App CLI.

Workspace:

```text
sandbox/projects/notes_app
```

Required commands:

```text
add "text"
list
done ID
delete ID
```

Storage:

```text
notes.json
note fields: id, text, done
```

Required tests:

```text
add creates note
list returns notes
done marks note
delete removes note
storage persists JSON
```

## Plan/Build

Logs:

```text
logs/notes_app_multifile/2026-06-30/
```

Build output used strict `FILE:` blocks.

Produced files:

```text
sandbox/projects/notes_app/notes_app/__init__.py
sandbox/projects/notes_app/notes_app/models.py
sandbox/projects/notes_app/notes_app/storage.py
sandbox/projects/notes_app/notes_app/main.py
sandbox/projects/notes_app/tests/__init__.py
sandbox/projects/notes_app/tests/test_notes.py
```

`△` manifest classified the output as:

```json
{
  "type": "code",
  "language": "python"
}
```

## Workspace Write

Files were written through:

```text
tools/fs.lua
context=workspace
write_mode=create_only
```

The project was created inside:

```text
sandbox/projects/notes_app
```

No write outside sandbox was needed.

## Unit Test Result

Command:

```text
cd sandbox/projects/notes_app
python3 -m unittest discover tests
```

Result:

```text
.....
----------------------------------------------------------------------
Ran 5 tests in 0.002s

OK
```

## CLI Smoke

Command sequence:

```text
rm -f notes.json
python3 -m notes_app.main add "hello world note"
python3 -m notes_app.main list
python3 -m notes_app.main done 1
python3 -m notes_app.main list
python3 -m notes_app.main delete 1
python3 -m notes_app.main list
```

Observed:

```text
Added note 1: hello world note
[ ] 1: hello world note
Marked note 1 as done.
[x] 1: hello world note
Deleted note 1.
No notes found.
```

## Important Observation

The first multi-file project passed on the first build.

No fix pass was required.

This means proc-17 now has a demonstrated path:

```text
multi-file code manifest
workspace file artifact
runtime unit tests
CLI smoke
```

This is a stronger threshold than tic-tac-toe:

```text
tic-tac-toe = single-file code generation + runtime checks
notes app  = multi-file project generation + workspace write + tests
```

## Current Boundary

The bridge is still manual/scripted:

```text
extract FILE blocks
write through fs tool
run tests
```

The body does not yet own this as a first-class organ route.

Next pressure:

```text
multi-file manifest parser
file_write organ
test_runner organ
fix-pass protocol
repo mutation manifest
```

