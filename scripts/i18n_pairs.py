"""English and Swahili written side by side in Python, found without running it. Used by i18n-review.mjs."""

import ast
import json
import sys
from pathlib import Path

AFTER_FIRST = {"field", "step", "Perm", "SystemRole"}


def text(node: ast.AST) -> str | None:
    return node.value if isinstance(node, ast.Constant) and isinstance(node.value, str) else None


def main() -> None:
    base = Path(sys.argv[1])
    pairs: list[tuple[str, str, str]] = []
    for path in sorted(base.rglob("*.py")):
        if "migrations" in path.parts or "demo" in path.parts:
            continue
        where = str(path.relative_to(base))
        for node in ast.walk(ast.parse(path.read_text())):
            if isinstance(node, ast.Call):
                name = getattr(node.func, "attr", getattr(node.func, "id", ""))
                if name in AFTER_FIRST and len(node.args) >= 3:
                    en, sw = text(node.args[1]), text(node.args[2])
                    if en and sw:
                        pairs.append((f"{where}: {en}", en, sw))
                words = {k.arg: text(k.value) for k in node.keywords if k.arg}
                for name, sw in words.items():
                    en = words.get(f"{name[:-3]}_en") if name.endswith("_sw") else None
                    if en and sw:
                        pairs.append((f"{where}: {en}", en, sw))
            if isinstance(node, ast.Assign) and isinstance(node.value, ast.Dict):
                if any(isinstance(t, ast.Name) and t.id == "SW" for t in node.targets):
                    for k, v in zip(node.value.keys, node.value.values, strict=True):
                        en, sw = text(k) if k else None, text(v)
                        if en and sw:
                            pairs.append((f"{where}: {en}", en, sw))
            if isinstance(node, ast.ClassDef):
                named = {
                    t.id: text(s.value)
                    for s in node.body
                    if isinstance(s, ast.Assign)
                    for t in s.targets
                    if isinstance(t, ast.Name)
                }
                for name, sw in named.items():
                    en = named.get(f"{name[:-3]}_en") if name.endswith("_sw") else None
                    if en and sw:
                        pairs.append((f"{where}: {en}", en, sw))
    json.dump(list(dict.fromkeys(pairs)), sys.stdout, ensure_ascii=False)


main()
