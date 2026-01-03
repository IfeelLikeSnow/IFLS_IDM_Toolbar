#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validate a ReaPack index.xml against common real-world breakages:
- malformed percent-encoding
- spaces or forbidden chars in URLs
- URLs not matching files present in the repository
- duplicate <source file="..."> entries
- <source main="main"> not pointing to .lua files

Run:
  python tools/validate_reapack_index.py
"""

from __future__ import annotations
import os, re, sys, string
from pathlib import Path
from urllib.parse import unquote
import xml.etree.ElementTree as ET
from collections import Counter

HEX = set(string.hexdigits)
BAD_CHARS = set(' <>"{}|\\^`')

def iter_repo_files(root: Path) -> set[str]:
    out=set()
    for p in root.rglob("*"):
        if p.is_file():
            rel = p.relative_to(root).as_posix()
            out.add(rel)
    return out

def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    index_path = repo_root / "index.xml"
    if not index_path.exists():
        print("ERROR: index.xml not found at repo root.")
        return 2

    repo_files = iter_repo_files(repo_root)
    repo_files.discard("index.xml")  # index isn't normally indexed

    tree = ET.parse(index_path)
    root = tree.getroot()

    sources = root.findall(".//source")
    if not sources:
        print("ERROR: No <source> elements found.")
        return 2

    # Duplicate file attributes
    files = [s.attrib.get("file", "") for s in sources]
    dup = [f for f,c in Counter(files).items() if c>1]
    if dup:
        print("ERROR: Duplicate <source file=\"...\"> entries:")
        for f in dup[:50]:
            print("  ", f)
        return 2

    # URL checks
    space_urls=[]
    bad_percent=[]
    bad_chars=[]
    non_https=[]
    bad_targets=[]
    main_non_lua=[]

    for s in sources:
        file_attr = s.attrib.get("file","")
        url = (s.text or "").strip()

        if not url.startswith("https://"):
            non_https.append((file_attr, url))

        if " " in url:
            space_urls.append((file_attr, url))

        for ch in BAD_CHARS:
            if ch in url:
                bad_chars.append((file_attr, url, ch))
                break

        for m in re.finditer("%", url):
            i=m.start()
            if i+2>=len(url) or not (url[i+1] in HEX and url[i+2] in HEX):
                bad_percent.append((file_attr, url, url[i:i+3]))
                break

        # try map github raw url to repo file
        m = re.search(r"/IFLS_IDM_Toolbar/(?:main|master|[0-9a-f]{7,40})/(.+)$", url)
        if m:
            rel = unquote(m.group(1))
            if rel not in repo_files:
                bad_targets.append((file_attr, rel))
        else:
            # not a github raw URL; skip mapping
            pass

        if s.attrib.get("main") == "main" and not file_attr.lower().endswith(".lua"):
            main_non_lua.append(file_attr)

    ok=True
    if non_https:
        ok=False
        print("ERROR: Non-https URLs:")
        for f,u in non_https[:20]:
            print("  ", f, "=>", u)

    if space_urls:
        ok=False
        print("ERROR: URLs containing literal spaces (must be %20):")
        for f,u in space_urls[:20]:
            print("  ", f, "=>", u)

    if bad_chars:
        ok=False
        print("ERROR: URLs containing forbidden chars:")
        for f,u,ch in bad_chars[:20]:
            print("  ", f, "=>", ch)

    if bad_percent:
        ok=False
        print("ERROR: Malformed percent-encoding in URLs:")
        for f,u,seg in bad_percent[:20]:
            print("  ", f, "=>", seg, "in", u)

    if bad_targets:
        ok=False
        print("ERROR: URL points to a repo path that does not exist:")
        for f,rel in bad_targets[:20]:
            print("  ", f, "=>", rel)

    if main_non_lua:
        ok=False
        print("ERROR: <source main=\"main\"> on non-.lua files:")
        for f in main_non_lua[:20]:
            print("  ", f)

    if ok:
        print("OK: index.xml passed validation")
        print(f"  sources: {len(sources)}")
    return 0 if ok else 2

if __name__ == "__main__":
    raise SystemExit(main())
