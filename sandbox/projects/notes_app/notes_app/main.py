import sys
from .models import Note
from .storage import load_notes, save_notes, next_id


def main():
    args = sys.argv[1:]
    if not args:
        print("Usage: python -m notes_app.main <command> [arguments]")
        print("Commands: add <text>, list, done <id>, delete <id>")
        return

    command = args[0]

    if command == "add":
        if len(args) < 2:
            print("Error: missing text argument")
            return
        text = args[1]
        notes = load_notes()
        note = Note(id=next_id(notes), text=text, done=False)
        notes.append(note)
        save_notes(notes)
        print(f"Added note {note.id}: {note.text}")

    elif command == "list":
        notes = load_notes()
        if not notes:
            print("No notes found.")
            return
        for note in notes:
            status = "[x]" if note.done else "[ ]"
            print(f"{status} {note.id}: {note.text}")

    elif command == "done":
        if len(args) < 2:
            print("Error: missing id argument")
            return
        try:
            note_id = int(args[1])
        except ValueError:
            print("Error: id must be an integer")
            return
        notes = load_notes()
        for note in notes:
            if note.id == note_id:
                note.done = True
                save_notes(notes)
                print(f"Marked note {note_id} as done.")
                return
        print(f"Error: note with id {note_id} not found")

    elif command == "delete":
        if len(args) < 2:
            print("Error: missing id argument")
            return
        try:
            note_id = int(args[1])
        except ValueError:
            print("Error: id must be an integer")
            return
        notes = load_notes()
        for i, note in enumerate(notes):
            if note.id == note_id:
                del notes[i]
                save_notes(notes)
                print(f"Deleted note {note_id}.")
                return
        print(f"Error: note with id {note_id} not found")

    else:
        print(f"Unknown command: {command}")
        print("Commands: add <text>, list, done <id>, delete <id>")


if __name__ == "__main__":
    main()