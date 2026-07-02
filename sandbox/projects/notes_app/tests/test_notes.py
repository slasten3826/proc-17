import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from notes_app.models import Note
from notes_app.storage import load_notes, save_notes, next_id, NOTES_FILE


class TestNotesApp(unittest.TestCase):

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.temp_file = Path(self.temp_dir.name) / "notes.json"
        self.patcher = patch("notes_app.storage.NOTES_FILE", self.temp_file)
        self.patcher.start()

    def tearDown(self):
        self.patcher.stop()
        self.temp_dir.cleanup()

    def test_add_creates_note(self):
        notes = load_notes()
        note = Note(id=next_id(notes), text="Test note", done=False)
        notes.append(note)
        save_notes(notes)
        loaded = load_notes()
        self.assertEqual(len(loaded), 1)
        self.assertEqual(loaded[0].text, "Test note")
        self.assertFalse(loaded[0].done)

    def test_list_returns_notes(self):
        notes = [Note(id=1, text="First"), Note(id=2, text="Second")]
        save_notes(notes)
        loaded = load_notes()
        self.assertEqual(len(loaded), 2)
        self.assertEqual(loaded[0].text, "First")
        self.assertEqual(loaded[1].text, "Second")

    def test_done_marks_note(self):
        notes = [Note(id=1, text="Task", done=False)]
        save_notes(notes)
        notes = load_notes()
        notes[0].done = True
        save_notes(notes)
        loaded = load_notes()
        self.assertTrue(loaded[0].done)

    def test_delete_removes_note(self):
        notes = [Note(id=1, text="A"), Note(id=2, text="B")]
        save_notes(notes)
        notes = load_notes()
        notes = [n for n in notes if n.id != 1]
        save_notes(notes)
        loaded = load_notes()
        self.assertEqual(len(loaded), 1)
        self.assertEqual(loaded[0].id, 2)

    def test_storage_persists_json(self):
        original = [Note(id=1, text="Persist me", done=True)]
        save_notes(original)
        with open(self.temp_file, "r") as f:
            data = json.load(f)
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["text"], "Persist me")
        self.assertTrue(data[0]["done"])
        loaded = load_notes()
        self.assertEqual(loaded[0].text, "Persist me")
        self.assertTrue(loaded[0].done)