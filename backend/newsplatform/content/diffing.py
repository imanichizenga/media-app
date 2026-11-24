"""What changed between two revisions, block by block. Blocks keep their ids, so moving is not rewriting."""

import difflib
import re
from typing import Any

from newsplatform.content import blocks

_TEXT = (
    "headline",
    "standfirst",
    "slug",
    "seo_title",
    "seo_description",
    "focus_keyword",
    "update_note",
    "correction_note",
)
_WORDS = re.compile(r"\s+|\w+|[^\w\s]+")
_MAX_TOKENS = 4000  # beyond this a word diff is slow and unreadable: show it as replaced


def words(old: str, new: str) -> list[dict[str, str]]:
    """Runs of {"op": "same" | "add" | "del", "text"}; joining all but "add" gives `old` back."""
    if old == new:
        return [{"op": "same", "text": old}] if old else []
    a, b = _WORDS.findall(old), _WORDS.findall(new)
    if len(a) + len(b) > _MAX_TOKENS:
        return [{"op": op, "text": t} for op, t in (("del", old), ("add", new)) if t]
    out: list[dict[str, str]] = []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag == "equal":
            out.append({"op": "same", "text": "".join(a[i1:i2])})
            continue
        if i2 > i1:
            out.append({"op": "del", "text": "".join(a[i1:i2])})
        if j2 > j1:
            out.append({"op": "add", "text": "".join(b[j1:j2])})
    return out


def _text(block: dict[str, Any]) -> str:
    return blocks.plain_text({"blocks": [block]})


def body(old: dict[str, Any], new: dict[str, Any]) -> list[dict[str, Any]]:
    before = {b["id"]: b for b in old.get("blocks", [])}
    after = {b["id"]: b for b in new.get("blocks", [])}
    matcher = difflib.SequenceMatcher(None, list(before), list(after), autojunk=False)
    out: list[dict[str, Any]] = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag != "equal":
            gone = [i for i in list(before)[i1:i2] if i not in after]
            out += [_entry("removed", before[i], words(_text(before[i]), "")) for i in gone]
        for ident in list(after)[j1:j2]:
            block = after[ident]
            if ident not in before:
                out.append(_entry("added", block, words("", _text(block))))
            elif before[ident] != block:
                out.append(_entry("changed", block, words(_text(before[ident]), _text(block))))
            else:
                op = "same" if tag == "equal" else "moved"
                out.append(_entry(op, block, words(_text(block), _text(block))))
    return out


def _entry(op: str, block: dict[str, Any], runs: list[dict[str, str]]) -> dict[str, Any]:
    return {"op": op, "id": block["id"], "type": block["type"], "words": runs}


def revisions(old: dict[str, Any], new: dict[str, Any]) -> dict[str, Any]:
    texts = []
    for locale in sorted({*old["texts"], *new["texts"]}):
        a, b = old["texts"].get(locale, {}), new["texts"].get(locale, {})
        fields = [
            {"field": f, "words": words(a.get(f, ""), b.get(f, ""))}
            for f in _TEXT
            if a.get(f, "") != b.get(f, "")
        ]
        changes = body(a.get("body") or blocks.EMPTY, b.get("body") or blocks.EMPTY)
        texts.append({"locale": locale, "fields": fields, "blocks": changes})
    other = sorted(k for k in {*old, *new} - {"texts"} if old.get(k) != new.get(k))
    return {"fields": other, "texts": texts}
