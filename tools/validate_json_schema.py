#!/usr/bin/env python3
"""Validate one JSON document against a checked-in Draft 2020-12 schema."""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print(
        "Missing pinned dependency 'jsonschema'. Install it with: "
        "python -m pip install --requirement tools/requirements-visual-qa.txt",
        file=sys.stderr,
    )
    raise SystemExit(2)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: validate_json_schema.py SCHEMA.json DOCUMENT.json", file=sys.stderr)
        return 2
    schema_path = Path(sys.argv[1])
    document_path = Path(sys.argv[2])
    schema = json.loads(schema_path.read_text(encoding="utf-8-sig"))
    document = json.loads(document_path.read_text(encoding="utf-8-sig"))
    Draft202012Validator.check_schema(schema)
    errors = sorted(
        Draft202012Validator(schema).iter_errors(document),
        key=lambda error: tuple(str(part) for part in error.absolute_path),
    )
    if errors:
        for error in errors:
            location = "/".join(str(part) for part in error.absolute_path) or "<root>"
            print(f"{location}: {error.message}", file=sys.stderr)
        return 1
    print(f"Valid: {document_path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
