from dataclasses import dataclass


@dataclass
class Note:
    id: int
    text: str
    done: bool = False

    def to_dict(self) -> dict:
        return {"id": self.id, "text": self.text, "done": self.done}

    @classmethod
    def from_dict(cls, data: dict) -> "Note":
        return cls(id=data["id"], text=data["text"], done=data.get("done", False))