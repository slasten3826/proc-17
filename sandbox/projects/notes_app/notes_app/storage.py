import json
import os
from pathlib import Path
from .models import Note


NOTES_FILE = Path(__file__).resolve().parent.parent / "notes.json"


def load_notes() -> list[Note]:
    if not NOTES_FILE.exists():
        return []
    try:
        with open(NOTES_FILE, "r") as f:
            data = json.load(f)
        return [Note.from_dict(item) for item in data]
    except (json.JSONDecodeError, KeyError, TypeError):
        return []


def save_notes(notes: list[Note]) -> None:
    data = [note.to_dict() for note in notes]
    with open(NOTES_FILE, "w") as f:
        json.dump(data, f, indent=2)


def next_id(notes: list[Note]) -> int:
    if not notes:
        return 1
    return max(note.id for note in notes) + 1