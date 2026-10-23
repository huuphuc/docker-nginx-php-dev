#!/usr/bin/env python3
"""Rewrite the PHP version table in README.md.

Usage: update-php-versions.py README.md php-versions.json LATEST_PHP [VERSION_DIR]

VERSION_DIR holds one file per published minor version, e.g. a file "8.5"
whose first field is the full PHP version ("8.5.12 ..."). Versions not published in this run keep the value already
in the README; versions no longer listed in php-versions.json are dropped.
"""
import json
import pathlib
import re
import sys

START = "<!-- php-versions:start -->"
END = "<!-- php-versions:end -->"

readme_path = pathlib.Path(sys.argv[1])
supported = json.loads(pathlib.Path(sys.argv[2]).read_text())
latest = sys.argv[3]
version_dir = pathlib.Path(sys.argv[4]) if len(sys.argv) > 4 else None

readme = readme_path.read_text()
head, rest = readme.split(START, 1)
block, tail = rest.split(END, 1)

versions = dict(re.findall(r"^\| `(\d+\.\d+)`[^|]*\| (\d+\.\d+\.\d+) \|", block, re.M))
if version_dir and version_dir.is_dir():
    for f in version_dir.iterdir():
        versions[f.name] = f.read_text().split()[0]

rows = ["| Tag | PHP |", "| --- | --- |"]
for minor in supported:
    tags = f"`{minor}`" + (", `latest`" if minor == latest else "")
    rows.append(f"| {tags} | {versions.get(minor, 'not published yet')} |")

readme_path.write_text(f"{head}{START}\n" + "\n".join(rows) + f"\n{END}{tail}")
