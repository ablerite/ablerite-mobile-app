#!/usr/bin/env python3
"""Build the Ablerite audio catalog and upload staging folder."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path


SOURCE_ROOT = Path(
    "/Users/admin/Desktop/Ablerite/Ablerite Content/Audio Sessions/2_Episodes"
)
OUTPUT_ROOT = Path("/private/tmp/ablerite-audio-r2")
REPO_CATALOG_PATH = Path("assets/audio/catalog.json")
PUBLIC_BASE_URL = "https://assets.ablerite.com"
BUCKET_NAME = "ablerite"


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "audio"


def clean_title(value: str) -> str:
    value = re.sub(r"^\d+[_\s-]*", "", value.strip())
    value = value.replace("_", " ")
    value = re.sub(r"\s+", " ", value)
    fixes = {
        "Networth": "Net Worth",
        "Task Lists": "Task Lists",
    }
    return fixes.get(value, value)


def natural_key(path: Path) -> list[object]:
    parts = re.split(r"(\d+)", path.name.lower())
    return [int(part) if part.isdigit() else part for part in parts]


def duration_label(path: Path) -> str:
    try:
        result = subprocess.run(
            ["afinfo", str(path)],
            check=True,
            capture_output=True,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "Audio"

    match = re.search(r"estimated duration:\s*([0-9.]+)\s*sec", result.stdout)
    if not match:
        return "Audio"
    seconds = round(float(match.group(1)))
    minutes, seconds = divmod(seconds, 60)
    return f"{minutes}:{seconds:02d}"


def convert_transcript(source: Path, target: Path, title: str) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        ["textutil", "-convert", "txt", "-stdout", str(source)],
        check=True,
        capture_output=True,
        text=True,
    )
    target.write_text(normalize_transcript(result.stdout, title), encoding="utf-8")


def is_diagram_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    if re.search(r"[┌┐└┘├┤┬┴┼│─═╔╗╚╝╠╣╦╩╬║╭╮╰╯▽▼▲△►◄]", stripped):
        return True
    if re.fullmatch(r"[=\-_*•·\s]{3,}", stripped):
        return True
    if re.search(r"[-=]{2,}>|<[-=]{2,}|[↔↕←↑→↓↙↘↗↖]", stripped):
        return True
    return False


def normalize_heading(line: str) -> str:
    stripped = re.sub(r"\s+", " ", line.strip())
    stripped = stripped.strip("_-–—: ")

    match = re.match(r"(?i)^part\s*(\d+)\s*[:._-]?\s*(.*)$", stripped)
    if match:
        part = int(match.group(1))
        title = match.group(2).strip(" _-–—:")
        return f"Part {part}: {title}" if title else f"Part {part}"

    return stripped


def normalize_transcript(text: str, title: str) -> str:
    text = text.replace("\u0000", "").replace("\uFFFD", "'")
    normalized_lines: list[str] = []
    previous_blank = True

    for raw_line in text.splitlines():
        line = raw_line.strip()

        if is_diagram_line(line):
            previous_blank = True
            continue

        line = normalize_heading(line)

        if not line:
            if not previous_blank:
                normalized_lines.append("")
            previous_blank = True
            continue

        normalized_lines.append(line)
        previous_blank = False

    while normalized_lines and normalized_lines[-1] == "":
        normalized_lines.pop()

    if normalized_lines and normalized_lines[0].casefold() != title.casefold():
        normalized_lines.insert(0, title)
    elif not normalized_lines:
        normalized_lines.append(title)

    return "\n\n".join(
        line for line in normalized_lines if line
    ) + "\n"


def discover_groups() -> list[dict[str, object]]:
    groups: list[dict[str, object]] = []
    section_dirs = sorted(
        [path for path in SOURCE_ROOT.iterdir() if path.is_dir()],
        key=natural_key,
    )

    for section_dir in section_dirs:
        section_title = clean_title(section_dir.name)
        section_id = slugify(section_title)
        direct_mp3s = sorted(
            [path for path in section_dir.glob("*.mp3") if path.is_file()],
            key=natural_key,
        )
        transcript_files = sorted(section_dir.glob("**/*.rtf"), key=natural_key)

        if direct_mp3s:
            groups.append(
                {
                    "section_id": section_id,
                    "section_title": section_title,
                    "subsection_id": None,
                    "subsection_title": None,
                    "source_dir": section_dir,
                    "mp3s": direct_mp3s,
                    "transcript": transcript_files[0] if transcript_files else None,
                }
            )

        child_dirs = sorted(
            [
                path
                for path in section_dir.iterdir()
                if path.is_dir() and path.name not in {"Source", "Transcripts"}
            ],
            key=natural_key,
        )
        for child_dir in child_dirs:
            mp3s = sorted(
                [path for path in child_dir.glob("*.mp3") if path.is_file()],
                key=natural_key,
            )
            if not mp3s:
                continue
            subsection_title = clean_title(child_dir.name)
            child_transcripts = sorted(child_dir.glob("**/*.rtf"), key=natural_key)
            groups.append(
                {
                    "section_id": section_id,
                    "section_title": section_title,
                    "subsection_id": slugify(subsection_title),
                    "subsection_title": subsection_title,
                    "source_dir": child_dir,
                    "mp3s": mp3s,
                    "transcript": child_transcripts[0] if child_transcripts else None,
                }
            )

    return groups


def main() -> None:
    if OUTPUT_ROOT.exists():
        shutil.rmtree(OUTPUT_ROOT)
    content_root = OUTPUT_ROOT / "audio"
    content_root.mkdir(parents=True)

    categories: list[dict[str, str]] = []
    episodes: list[dict[str, object]] = []
    upload_commands = ["#!/usr/bin/env bash", "set -euo pipefail", ""]
    upload_commands.append("# Requires: wrangler login")
    upload_commands.append('WRANGLER_BIN="${WRANGLER_BIN:-wrangler}"')
    upload_commands.append("")

    seen_sections: set[str] = set()
    groups = discover_groups()

    for group in groups:
        section_id = str(group["section_id"])
        section_title = str(group["section_title"])
        subsection_id = group["subsection_id"]
        subsection_title = group["subsection_title"]
        group_slug = str(subsection_id or section_id)

        if section_id not in seen_sections:
            categories.append({"id": section_id, "title": section_title})
            seen_sections.add(section_id)

        key_parts = ["audio", section_id]
        if subsection_id:
            key_parts.append(str(subsection_id))
        target_dir = OUTPUT_ROOT.joinpath(*key_parts)
        target_dir.mkdir(parents=True, exist_ok=True)

        transcript_url = None
        transcript = group["transcript"]
        if isinstance(transcript, Path):
            transcript_name = f"{group_slug}-transcript.txt"
            transcript_target = target_dir / transcript_name
            convert_transcript(
                transcript,
                transcript_target,
                str(subsection_title or section_title),
            )
            transcript_key = "/".join([*key_parts, transcript_name])
            transcript_url = f"{PUBLIC_BASE_URL}/{transcript_key}"
            upload_commands.append(
                '"$WRANGLER_BIN" r2 object put '
                f"{BUCKET_NAME}/{transcript_key} --file={json.dumps(str(transcript_target))} "
                "--content-type=text/plain --remote"
            )

        mp3s = group["mp3s"]
        assert isinstance(mp3s, list)
        for index, source_mp3 in enumerate(mp3s, start=1):
            assert isinstance(source_mp3, Path)
            audio_name = f"{group_slug}-{index}.mp3"
            target_mp3 = target_dir / audio_name
            shutil.copy2(source_mp3, target_mp3)
            audio_key = "/".join([*key_parts, audio_name])
            title_base = str(subsection_title or section_title)
            episode = {
                "id": f"{group_slug}-{index}",
                "title": f"{title_base} {index}",
                "description": f"Part {index} of the {title_base} audio series.",
                "duration": duration_label(source_mp3),
                "fileName": audio_name,
                "url": f"{PUBLIC_BASE_URL}/{audio_key}",
                "category": section_id,
                "sectionId": section_id,
                "sectionTitle": section_title,
            }
            if subsection_id:
                episode["subsectionId"] = subsection_id
                episode["subsectionTitle"] = subsection_title
            if transcript_url:
                episode["transcriptUrl"] = transcript_url
            episodes.append(episode)
            upload_commands.append(
                '"$WRANGLER_BIN" r2 object put '
                f"{BUCKET_NAME}/{audio_key} --file={json.dumps(str(target_mp3))} "
                "--content-type=audio/mpeg --remote"
            )

    catalog = {
        "version": 2,
        "generatedFrom": str(SOURCE_ROOT),
        "categories": categories,
        "episodes": episodes,
    }
    catalog_path = content_root / "catalog.json"
    catalog_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    REPO_CATALOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPO_CATALOG_PATH.write_text(
        json.dumps(catalog, indent=2) + "\n",
        encoding="utf-8",
    )
    upload_commands.append(
        '"$WRANGLER_BIN" r2 object put '
        f"{BUCKET_NAME}/audio/catalog.json --file={json.dumps(str(catalog_path))} "
        "--content-type=application/json --remote"
    )
    (OUTPUT_ROOT / "upload_audio_to_r2.sh").write_text(
        "\n".join(upload_commands) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {catalog_path}")
    print(f"Wrote {REPO_CATALOG_PATH}")
    print(f"Wrote {len(episodes)} episodes across {len(categories)} sections")
    print(f"Staged upload folder at {OUTPUT_ROOT}")


if __name__ == "__main__":
    main()
