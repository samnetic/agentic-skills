#!/usr/bin/env python3
"""
Validate skill quality against structural and authoring standards.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


FRONTMATTER_BOUNDARY = "---"
BANNED_FILES = {
    "README.md",
    "INSTALLATION_GUIDE.md",
    "QUICK_REFERENCE.md",
    "CHANGELOG.md",
}
NAME_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]{1,62}$")


@dataclass
class SkillResult:
    skill_dir: Path
    score: int
    grade: str
    fails: list[str]
    warns: list[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check skill quality.")
    parser.add_argument(
        "paths",
        nargs="*",
        default=["skills"],
        help="Skill directories or parent directories to scan",
    )
    parser.add_argument("--max-lines", type=int, default=500, help="Max SKILL.md body lines")
    parser.add_argument(
        "--profile",
        choices=["internal", "third-party"],
        default="internal",
        help="Validation profile",
    )
    parser.add_argument(
        "--min-description-chars",
        type=int,
        default=80,
        help="Minimum description length",
    )
    parser.add_argument(
        "--strict-frontmatter",
        action="store_true",
        help="Warn when frontmatter contains fields other than name/description",
    )
    parser.add_argument(
        "--fail-on-warn",
        action="store_true",
        help="Return non-zero if warnings are present",
    )
    parser.add_argument("--verbose", action="store_true", help="Print detailed findings")
    parser.add_argument(
        "--emit-plan",
        help="Write markdown refactor plan to this file path",
    )
    return parser.parse_args()


def discover_skill_dirs(paths: list[str]) -> list[Path]:
    skill_dirs: set[Path] = set()
    for path_str in paths:
        path = Path(path_str).expanduser().resolve()
        if not path.exists():
            continue
        if path.is_file() and path.name == "SKILL.md":
            skill_dirs.add(path.parent)
            continue
        if path.is_dir() and (path / "SKILL.md").is_file():
            skill_dirs.add(path)
            continue
        if path.is_dir():
            for child in sorted(path.iterdir()):
                if child.is_dir() and (child / "SKILL.md").is_file():
                    skill_dirs.add(child)
    return sorted(skill_dirs)


def split_frontmatter(text: str) -> tuple[str, str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != FRONTMATTER_BOUNDARY:
        return "", text
    end_idx = None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == FRONTMATTER_BOUNDARY:
            end_idx = idx
            break
    if end_idx is None:
        return "", text
    frontmatter = "\n".join(lines[1:end_idx])
    body = "\n".join(lines[end_idx + 1 :])
    return frontmatter, body


def parse_frontmatter(frontmatter: str) -> dict[str, str]:
    parsed: dict[str, str] = {}
    current_key: str | None = None
    for raw_line in frontmatter.splitlines():
        line = raw_line.rstrip()
        match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if match:
            current_key = match.group(1)
            parsed[current_key] = match.group(2).strip()
            continue
        if current_key and (line.startswith("  ") or line.startswith("\t")):
            continuation = line.strip()
            if continuation:
                prev = parsed.get(current_key, "")
                parsed[current_key] = (prev + " " + continuation).strip()
    return parsed


def grade_from_score(score: int) -> str:
    if score >= 90:
        return "A"
    if score >= 80:
        return "B"
    if score >= 70:
        return "C"
    return "D"


def evaluate_skill(
    skill_dir: Path,
    max_lines: int,
    min_description_chars: int,
    strict_frontmatter: bool,
    profile: str,
) -> SkillResult:
    fails: list[str] = []
    warns: list[str] = []
    skill_file = skill_dir / "SKILL.md"
    text = skill_file.read_text(encoding="utf-8")
    frontmatter, body = split_frontmatter(text)
    if not frontmatter:
        fails.append("Missing YAML frontmatter")
        parsed = {}
    else:
        parsed = parse_frontmatter(frontmatter)

    name = parsed.get("name", "").strip()
    description = parsed.get("description", "").strip()

    if not name:
        fails.append("Frontmatter missing 'name'")
    elif not NAME_PATTERN.match(name):
        fails.append(f"Invalid skill name format: {name!r}")

    if name and skill_dir.name != name:
        warns.append(f"Directory name {skill_dir.name!r} differs from frontmatter name {name!r}")

    if not description:
        fails.append("Frontmatter missing 'description'")
    else:
        if len(description) < min_description_chars:
            fails.append(
                f"Description too short ({len(description)} chars < {min_description_chars})"
            )
        lowered = description.lower()
        if "use when" not in lowered and "when the user" not in lowered:
            warns.append("Description should contain explicit trigger language ('Use when...')")

    if strict_frontmatter:
        extras = sorted(set(parsed) - {"name", "description"})
        if extras:
            warns.append(f"Unexpected frontmatter fields: {', '.join(extras)}")

    body_lines = len(body.splitlines())
    if body_lines > max_lines:
        fails.append(f"Body too long ({body_lines} lines > {max_lines})")
    if body_lines < 40:
        warns.append(f"Body is very short ({body_lines} lines)")

    headings = []
    for line in body.splitlines():
        if line.startswith("#"):
            headings.append(re.sub(r"^#+\s*", "", line).strip().lower())
    if not any("workflow" in heading for heading in headings):
        if profile == "internal":
            fails.append("Missing workflow section")
        else:
            warns.append("Missing workflow section")
    if not any(("quality gate" in h) or ("validation" in h) for h in headings):
        warns.append("Missing explicit quality gates or validation section")
    if not any(("output contract" in h) or ("deliverable" in h) for h in headings):
        warns.append("Missing output contract/deliverables section")

    has_progressive_links = any(token in body for token in ("references/", "scripts/", "assets/"))
    if not has_progressive_links:
        warns.append("No progressive disclosure links (references/scripts/assets) found")

    references_dir = skill_dir / "references"
    if references_dir.exists():
        reference_files = [p for p in references_dir.rglob("*") if p.is_file()]
        if not reference_files:
            warns.append("references/ exists but contains no files")

    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        script_files = [p for p in scripts_dir.rglob("*") if p.is_file()]
        if not script_files:
            warns.append("scripts/ exists but contains no files")
        for script in script_files:
            if script.suffix in {".py", ".sh"} and not script.stat().st_mode & 0o111:
                warns.append(f"Script is not executable: {script.name}")

    for banned in sorted(BANNED_FILES):
        if (skill_dir / banned).exists():
            warns.append(f"Banned auxiliary file present: {banned}")

    score = max(0, 100 - (20 * len(fails)) - (7 * len(warns)))
    grade = grade_from_score(score)
    return SkillResult(skill_dir=skill_dir, score=score, grade=grade, fails=fails, warns=warns)


def print_report(results: list[SkillResult], verbose: bool) -> None:
    print("grade\tscore\tfails\twarns\tskill")
    for result in results:
        print(
            f"{result.grade}\t{result.score}\t{len(result.fails)}\t{len(result.warns)}\t"
            f"{result.skill_dir}"
        )
        if verbose:
            for fail in result.fails:
                print(f"  FAIL: {fail}")
            for warn in result.warns:
                print(f"  WARN: {warn}")

    total = len(results)
    total_fails = sum(len(item.fails) for item in results)
    total_warns = sum(len(item.warns) for item in results)
    print("")
    print(f"skills={total} total_fails={total_fails} total_warns={total_warns}")


def action_for_issue(issue: str, skill_dir: Path) -> str:
    issue_lower = issue.lower()
    skill_file = skill_dir / "SKILL.md"
    if "missing yaml frontmatter" in issue_lower:
        return f"Add YAML frontmatter with `name` and `description` in `{skill_file}`."
    if "frontmatter missing 'name'" in issue_lower:
        return f"Add a valid `name` field to `{skill_file}`."
    if "frontmatter missing 'description'" in issue_lower:
        return f"Add a trigger-rich `description` field to `{skill_file}` (include `Use when...`)."
    if "description too short" in issue_lower:
        return f"Expand `description` in `{skill_file}` to include scope, triggers, and boundaries."
    if "explicit trigger language" in issue_lower:
        return f"Update `description` in `{skill_file}` to include explicit trigger phrasing (`Use when...`)."
    if "unexpected frontmatter fields" in issue_lower:
        return (
            f"Remove non-standard frontmatter keys from `{skill_file}` "
            "or move them into body/references."
        )
    if "body too long" in issue_lower:
        return f"Move detailed content from `{skill_file}` into `references/` and keep core workflow in `SKILL.md`."
    if "body is very short" in issue_lower:
        return f"Add missing workflow detail, outputs, and quality gates to `{skill_file}`."
    if "missing workflow section" in issue_lower:
        return f"Add `## Workflow` with numbered, execution-ready steps in `{skill_file}`."
    if "missing explicit quality gates or validation section" in issue_lower:
        return f"Add `## Quality Gates` or `## Validation` with measurable criteria in `{skill_file}`."
    if "missing output contract/deliverables section" in issue_lower:
        return f"Add `## Output Contract` with concrete deliverables in `{skill_file}`."
    if "no progressive disclosure links" in issue_lower:
        return f"Add `references/` or `scripts/` links in `{skill_file}` and move deep details there."
    if "references/ exists but contains no files" in issue_lower:
        return f"Populate `{skill_dir / 'references'}` with focused reference files or remove empty folder."
    if "scripts/ exists but contains no files" in issue_lower:
        return f"Add scripts to `{skill_dir / 'scripts'}` or remove the empty directory."
    if "script is not executable" in issue_lower:
        return f"Set executable bit on scripts in `{skill_dir / 'scripts'}` (`chmod +x`)."
    if "banned auxiliary file present" in issue_lower:
        return f"Remove auxiliary docs in `{skill_dir}` and keep guidance in `SKILL.md` or `references/`."
    if "directory name" in issue_lower and "differs from frontmatter name" in issue_lower:
        return f"Rename directory or align frontmatter `name` in `{skill_file}`."
    return f"Refactor `{skill_file}` to address: {issue}"


def write_refactor_plan(results: list[SkillResult], output_path: str) -> None:
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    lines.append("# Skill Refactor Plan")
    lines.append("")
    lines.append("Auto-generated by `scripts/check-skill-quality.py --emit-plan`.")
    lines.append("")
    for result in results:
        issues = result.fails + result.warns
        if not issues:
            continue
        lines.append(f"## {result.skill_dir.name}")
        lines.append("")
        lines.append(f"- Current grade: `{result.grade}` (score `{result.score}`)")
        lines.append(f"- File: `{result.skill_dir / 'SKILL.md'}`")
        lines.append("")
        lines.append("### Actions")
        lines.append("")
        for issue in issues:
            lines.append(f"- Issue: {issue}")
            lines.append(f"  Action: {action_for_issue(issue, result.skill_dir)}")
        lines.append("")

    if len(lines) <= 4:
        lines.append("No refactor actions needed. All checked skills passed without issues.")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    skill_dirs = discover_skill_dirs(args.paths)
    if not skill_dirs:
        print("No skills found for provided paths.", file=sys.stderr)
        return 1

    results = [
        evaluate_skill(
            skill_dir=skill_dir,
            max_lines=args.max_lines,
            min_description_chars=args.min_description_chars,
            strict_frontmatter=args.strict_frontmatter,
            profile=args.profile,
        )
        for skill_dir in skill_dirs
    ]
    print_report(results, args.verbose)
    if args.emit_plan:
        write_refactor_plan(results, args.emit_plan)

    fail_count = sum(len(result.fails) for result in results)
    warn_count = sum(len(result.warns) for result in results)
    if fail_count > 0:
        return 1
    if args.fail_on_warn and warn_count > 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
