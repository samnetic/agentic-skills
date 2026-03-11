#!/usr/bin/env python3
"""
Validate skill quality against Anthropic Skill Creator 2.0 standards.

Checks span 8 categories aligned with the official spec:
  1. Frontmatter / Metadata
  2. SKILL.md Body Structure
  3. Description Quality (Triggering)
  4. Writing Style
  5. Progressive Disclosure
  6. Content Richness
  7. Reference File Quality
  8. Overall Architecture
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


FRONTMATTER_BOUNDARY = "---"
BANNED_FILES = {
    "README.md",
    "INSTALLATION_GUIDE.md",
    "QUICK_REFERENCE.md",
    "CHANGELOG.md",
}
NAME_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]{1,62}$")

# --- Severity weights ---
FAIL_WEIGHT = 20
WARN_WEIGHT = 7
INFO_WEIGHT = 2

# --- Thresholds ---
MAX_BODY_LINES = 500
MIN_BODY_LINES = 40
MIN_DESCRIPTION_CHARS_DEFAULT = 80
MIN_DESCRIPTION_WORDS = 30
MAX_DESCRIPTION_WORDS = 250
REF_TOC_THRESHOLD = 300  # reference files over this many lines need a TOC
HEAVY_IMPERATIVE_THRESHOLD = 5  # max all-caps MUST/ALWAYS/NEVER per 100 body lines
NEEDS_REFS_BODY_THRESHOLD = 400  # if body > this and no refs, suggest splitting
CODE_FENCE_PATTERN = re.compile(r"^```", re.MULTILINE)
EXAMPLE_PATTERN = re.compile(r"\*\*example\s*\d|example\s*\d|input:.*output:|## example", re.I)
CHECKLIST_PATTERN = re.compile(r"- \[[ x]\]")

# Section heading keywords for detection
WORKFLOW_KEYWORDS = {"workflow", "process", "steps", "procedure", "how to"}
QUALITY_GATE_KEYWORDS = {"quality gate", "validation", "verification", "verify", "checklist"}
OUTPUT_CONTRACT_KEYWORDS = {"output contract", "deliverable", "output format", "what you get"}
ANTI_PATTERN_KEYWORDS = {"anti-pattern", "antipattern", "common mistake", "pitfall", "avoid"}
DECISION_TREE_KEYWORDS = {"decision", "choosing", "selection", "when to use", "which to"}
PRINCIPLES_KEYWORDS = {"principle", "core principle", "philosophy", "ground rule"}


@dataclass
class Issue:
    """A single finding with category and severity."""
    message: str
    category: str
    severity: str  # "fail", "warn", "info"


@dataclass
class SkillResult:
    skill_dir: Path
    score: int = 0
    grade: str = ""
    issues: list[Issue] = field(default_factory=list)

    @property
    def fails(self) -> list[str]:
        return [i.message for i in self.issues if i.severity == "fail"]

    @property
    def warns(self) -> list[str]:
        return [i.message for i in self.issues if i.severity == "warn"]

    @property
    def infos(self) -> list[str]:
        return [i.message for i in self.issues if i.severity == "info"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check skill quality against Anthropic Skill Creator 2.0 standards."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["skills"],
        help="Skill directories or parent directories to scan",
    )
    parser.add_argument("--max-lines", type=int, default=MAX_BODY_LINES, help="Max SKILL.md body lines")
    parser.add_argument(
        "--profile",
        choices=["internal", "third-party"],
        default="internal",
        help="Validation profile (internal is stricter)",
    )
    parser.add_argument(
        "--min-description-chars",
        type=int,
        default=MIN_DESCRIPTION_CHARS_DEFAULT,
        help="Minimum description length in characters",
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
    parser.add_argument(
        "--category",
        choices=[
            "frontmatter", "body", "description", "style",
            "disclosure", "content", "references", "architecture",
        ],
        help="Only run checks for a specific category",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
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
    body = "\n".join(lines[end_idx + 1:])
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


def extract_headings(body: str) -> list[str]:
    headings = []
    for line in body.splitlines():
        if line.startswith("#"):
            headings.append(re.sub(r"^#+\s*", "", line).strip().lower())
    return headings


def has_heading_match(headings: list[str], keywords: set[str]) -> bool:
    return any(
        any(kw in heading for kw in keywords)
        for heading in headings
    )


def count_code_fences(body: str) -> int:
    return len(CODE_FENCE_PATTERN.findall(body)) // 2


def count_heavy_imperatives(body: str) -> int:
    """Count all-caps MUST, ALWAYS, NEVER, REQUIRED, FORBIDDEN in the body."""
    return len(re.findall(r"\b(?:MUST|ALWAYS|NEVER|REQUIRED|FORBIDDEN)\b", body))


def count_why_explanations(body: str) -> int:
    """Count reasoning indicators: because, why, reason, this ensures, this prevents."""
    return len(re.findall(
        r"\b(?:because|why|reason|this ensures|this prevents|this avoids|the goal is|this matters)\b",
        body, re.I,
    ))


def has_toc(text: str) -> bool:
    """Check if a document has a table of contents (markdown links or heading list)."""
    toc_indicators = [
        re.compile(r"^#+\s*(?:table of contents|contents|toc)\s*$", re.I | re.M),
        re.compile(r"- \[.*\]\(#"),  # markdown anchor links
    ]
    return any(pat.search(text) for pat in toc_indicators)


def grade_from_score(score: int) -> str:
    if score >= 90:
        return "A"
    if score >= 80:
        return "B"
    if score >= 70:
        return "C"
    if score >= 55:
        return "D"
    return "F"


# ── Category 1: Frontmatter / Metadata ──────────────────────────────────────

def check_frontmatter(
    parsed: dict[str, str],
    skill_dir: Path,
    min_description_chars: int,
    strict_frontmatter: bool,
) -> list[Issue]:
    issues: list[Issue] = []
    cat = "frontmatter"

    name = parsed.get("name", "").strip()
    description = parsed.get("description", "").strip()

    if not name:
        issues.append(Issue("Frontmatter missing 'name'", cat, "fail"))
    elif not NAME_PATTERN.match(name):
        issues.append(Issue(f"Invalid skill name format: {name!r}", cat, "fail"))

    if name and skill_dir.name != name:
        issues.append(Issue(
            f"Directory name {skill_dir.name!r} differs from frontmatter name {name!r}",
            cat, "warn",
        ))

    if not description:
        issues.append(Issue("Frontmatter missing 'description'", cat, "fail"))
    else:
        if len(description) < min_description_chars:
            issues.append(Issue(
                f"Description too short ({len(description)} chars < {min_description_chars})",
                cat, "fail",
            ))

    if strict_frontmatter:
        extras = sorted(set(parsed) - {"name", "description", "compatibility"})
        if extras:
            issues.append(Issue(
                f"Unexpected frontmatter fields: {', '.join(extras)}", cat, "warn",
            ))

    return issues


# ── Category 2: Body Structure ───────────────────────────────────────────────

def check_body_structure(
    body: str,
    headings: list[str],
    max_lines: int,
) -> list[Issue]:
    issues: list[Issue] = []
    cat = "body"
    body_lines = len(body.splitlines())

    if body_lines > max_lines:
        issues.append(Issue(
            f"Body too long ({body_lines} lines > {max_lines}). "
            "Move deep-dive content to references/ and keep core workflow in SKILL.md",
            cat, "fail",
        ))

    if body_lines < MIN_BODY_LINES:
        issues.append(Issue(
            f"Body is very short ({body_lines} lines). "
            "Add workflow steps, examples, and quality gates",
            cat, "warn",
        ))

    if not has_heading_match(headings, WORKFLOW_KEYWORDS):
        issues.append(Issue(
            "Missing workflow/process section. "
            "Add numbered, execution-ready steps that guide the model through the task",
            cat, "warn",
        ))

    if not has_heading_match(headings, QUALITY_GATE_KEYWORDS):
        issues.append(Issue(
            "No quality gates/validation section. "
            "Consider adding measurable criteria the model checks before delivering output",
            cat, "info",
        ))

    if not has_heading_match(headings, OUTPUT_CONTRACT_KEYWORDS):
        issues.append(Issue(
            "No output contract/deliverables section. "
            "Consider defining exactly what artifacts the skill produces",
            cat, "info",
        ))

    return issues


# ── Category 3: Description Quality (Triggering) ────────────────────────────

def check_description_quality(description: str) -> list[Issue]:
    issues: list[Issue] = []
    cat = "description"

    if not description:
        return issues  # already caught in frontmatter

    lowered = description.lower()
    words = description.split()
    word_count = len(words)

    # Trigger language
    if "use when" not in lowered and "use whenever" not in lowered and "when the user" not in lowered:
        issues.append(Issue(
            "Description lacks trigger language ('Use when...'). "
            "The description is the primary mechanism that determines whether Claude invokes the skill",
            cat, "warn",
        ))

    # Explicit trigger keywords list (our convention, not official requirement)
    if "triggers:" not in lowered and "trigger:" not in lowered:
        issues.append(Issue(
            "Description has no explicit 'Triggers:' keyword list. "
            "Consider adding a comma-separated list of trigger words/phrases at the end "
            "to help Claude match user intent reliably",
            cat, "info",
        ))

    # Word count bounds
    if word_count < MIN_DESCRIPTION_WORDS:
        issues.append(Issue(
            f"Description too brief ({word_count} words < {MIN_DESCRIPTION_WORDS}). "
            "Include what the skill does, when to use it, and trigger keywords",
            cat, "warn",
        ))
    elif word_count > MAX_DESCRIPTION_WORDS:
        issues.append(Issue(
            f"Description very long ({word_count} words > {MAX_DESCRIPTION_WORDS}). "
            "Keep metadata around 100 words; move details to body",
            cat, "info",
        ))

    # Pushiness — Claude undertriggers by default, descriptions should be proactive
    use_when_count = len(re.findall(r"use when|use whenever|use if", lowered))
    if use_when_count < 2:
        issues.append(Issue(
            "Description may undertrigger — only mentions trigger context once. "
            "Add multiple 'Use when...' scenarios to encourage Claude to invoke the skill proactively. "
            "Claude tends to undertrigger, so descriptions should be slightly 'pushy'",
            cat, "info",
        ))

    # Hedging language weakens triggering
    hedges = re.findall(r"\b(?:might|possibly|perhaps|maybe|could potentially)\b", lowered)
    if hedges:
        issues.append(Issue(
            f"Description uses hedging language ({', '.join(set(hedges))}). "
            "Use confident, action-oriented phrasing for better triggering",
            cat, "info",
        ))

    return issues


# ── Category 4: Writing Style ────────────────────────────────────────────────

def check_writing_style(body: str) -> list[Issue]:
    issues: list[Issue] = []
    cat = "style"
    body_lines = body.splitlines()
    line_count = len(body_lines)

    if line_count == 0:
        return issues

    # Heavy-handed imperatives density
    imperative_count = count_heavy_imperatives(body)
    per_100 = (imperative_count / max(line_count, 1)) * 100
    if per_100 > HEAVY_IMPERATIVE_THRESHOLD:
        issues.append(Issue(
            f"High density of all-caps imperatives ({imperative_count} MUST/ALWAYS/NEVER in {line_count} lines = "
            f"{per_100:.1f}/100 lines). "
            "Explain the WHY instead — models respond better to reasoning than rigid commands. "
            "Reframe 'NEVER do X' as 'Avoid X because [reason]'",
            cat, "warn",
        ))

    # WHY-to-imperative ratio
    why_count = count_why_explanations(body)
    if imperative_count > 3 and why_count < imperative_count:
        issues.append(Issue(
            f"Low WHY-to-imperative ratio ({why_count} explanations vs {imperative_count} imperatives). "
            "For each rule, explain the reasoning so the model understands when and why to follow it. "
            "Use 'because', 'this ensures', 'this prevents' to add context",
            cat, "info",
        ))

    return issues


# ── Category 5: Progressive Disclosure ───────────────────────────────────────

def check_progressive_disclosure(
    body: str,
    skill_dir: Path,
) -> list[Issue]:
    issues: list[Issue] = []
    cat = "disclosure"

    has_ref_links = "references/" in body
    has_script_links = "scripts/" in body
    has_asset_links = "assets/" in body
    has_any_links = has_ref_links or has_script_links or has_asset_links

    if not has_any_links:
        issues.append(Issue(
            "No progressive disclosure links (references/scripts/assets) found. "
            "Keep SKILL.md under 500 lines by moving deep-dive content to references/, "
            "reusable scripts to scripts/, and templates to assets/",
            cat, "warn",
        ))

    references_dir = skill_dir / "references"
    if references_dir.exists():
        reference_files = [p for p in references_dir.rglob("*") if p.is_file()]
        if not reference_files:
            issues.append(Issue(
                "references/ directory exists but contains no files",
                cat, "warn",
            ))
    elif has_ref_links:
        issues.append(Issue(
            "SKILL.md links to references/ but the directory does not exist",
            cat, "fail",
        ))

    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        # Only check direct children — not vendored deps like venvs
        script_files = [p for p in scripts_dir.iterdir() if p.is_file()]
        if not script_files:
            issues.append(Issue(
                "scripts/ directory exists but contains no files",
                cat, "warn",
            ))
        for script in script_files:
            if script.suffix in {".py", ".sh"} and not script.stat().st_mode & 0o111:
                issues.append(Issue(
                    f"Script is not executable: {script.name}",
                    cat, "warn",
                ))

    # Body too long without references = should split
    body_lines = len(body.splitlines())
    if body_lines > NEEDS_REFS_BODY_THRESHOLD and not references_dir.exists():
        issues.append(Issue(
            f"Body is {body_lines} lines with no references/ directory. "
            "Split domain-specific deep dives into separate reference files "
            "(e.g., references/patterns.md, references/config.md)",
            cat, "warn",
        ))

    # Check if SKILL.md has "when to read" guidance for reference links
    if has_ref_links and references_dir.exists():
        ref_link_lines = [
            line for line in body.splitlines()
            if "references/" in line
        ]
        guidance_patterns = re.compile(r"when|if you need|for .* details|see .* for", re.I)
        links_with_guidance = sum(1 for line in ref_link_lines if guidance_patterns.search(line))
        if ref_link_lines and links_with_guidance < len(ref_link_lines) // 2:
            issues.append(Issue(
                "Reference links lack 'when to read' guidance. "
                "Each reference link should explain when the model should consult it "
                "(e.g., 'Security hardening → references/SECURITY.md')",
                cat, "info",
            ))

    return issues


# ── Category 6: Content Richness ─────────────────────────────────────────────

def check_content_richness(body: str, headings: list[str]) -> list[Issue]:
    issues: list[Issue] = []
    cat = "content"

    # Code examples
    fence_count = count_code_fences(body)
    if fence_count == 0:
        issues.append(Issue(
            "No code fences found. Include concrete, copy-paste-ready examples "
            "with language-specific fencing (```typescript, ```bash, etc.)",
            cat, "warn",
        ))

    # Examples with input/output pattern
    has_examples = bool(EXAMPLE_PATTERN.search(body))
    if not has_examples and fence_count < 3:
        issues.append(Issue(
            "No labeled examples found (Example 1, Input/Output pairs). "
            "Add realistic examples showing input → expected output to demonstrate the skill's behavior",
            cat, "info",
        ))

    # Anti-patterns section
    if not has_heading_match(headings, ANTI_PATTERN_KEYWORDS):
        issues.append(Issue(
            "No anti-patterns section. "
            "Add a table or list of common mistakes with 'Why it's dangerous' and 'Fix' columns "
            "to help the model avoid pitfalls",
            cat, "info",
        ))

    # Decision trees / selection guidance
    if not has_heading_match(headings, DECISION_TREE_KEYWORDS):
        issues.append(Issue(
            "No decision tree or selection guidance section. "
            "When multiple valid approaches exist, add a decision tree "
            "to help the model choose the right one for the context",
            cat, "info",
        ))

    # Core principles section
    if not has_heading_match(headings, PRINCIPLES_KEYWORDS):
        issues.append(Issue(
            "No core principles section. "
            "Add a concise principles table explaining the WHY behind the skill's approach",
            cat, "info",
        ))

    # Checklist section
    has_checklist = bool(CHECKLIST_PATTERN.search(body))
    if not has_checklist:
        issues.append(Issue(
            "No checklist found (- [ ] items). "
            "Add a review checklist the model can use to verify output quality before delivery",
            cat, "info",
        ))

    return issues


# ── Category 7: Reference File Quality ───────────────────────────────────────

def check_reference_files(skill_dir: Path) -> list[Issue]:
    issues: list[Issue] = []
    cat = "references"

    references_dir = skill_dir / "references"
    if not references_dir.exists():
        return issues

    for ref_file in sorted(references_dir.rglob("*.md")):
        try:
            content = ref_file.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            issues.append(Issue(
                f"Cannot read reference file: {ref_file.name}", cat, "warn",
            ))
            continue

        line_count = len(content.splitlines())
        rel_path = ref_file.relative_to(skill_dir)

        if line_count > REF_TOC_THRESHOLD and not has_toc(content):
            issues.append(Issue(
                f"Reference file {rel_path} is {line_count} lines with no table of contents. "
                f"Files over {REF_TOC_THRESHOLD} lines should include a TOC with anchor links "
                "so the model can navigate efficiently",
                cat, "warn",
            ))

    return issues


# ── Category 8: Architecture ─────────────────────────────────────────────────

def check_architecture(skill_dir: Path) -> list[Issue]:
    issues: list[Issue] = []
    cat = "architecture"

    for banned in sorted(BANNED_FILES):
        if (skill_dir / banned).exists():
            issues.append(Issue(
                f"Banned auxiliary file present: {banned}. "
                "Keep all guidance in SKILL.md or references/",
                cat, "warn",
            ))

    return issues


# ── Main evaluation ──────────────────────────────────────────────────────────

def evaluate_skill(
    skill_dir: Path,
    max_lines: int,
    min_description_chars: int,
    strict_frontmatter: bool,
    profile: str,
    category_filter: str | None = None,
) -> SkillResult:
    result = SkillResult(skill_dir=skill_dir)
    skill_file = skill_dir / "SKILL.md"
    text = skill_file.read_text(encoding="utf-8")
    frontmatter, body = split_frontmatter(text)

    if not frontmatter:
        result.issues.append(Issue("Missing YAML frontmatter", "frontmatter", "fail"))
        parsed = {}
    else:
        parsed = parse_frontmatter(frontmatter)

    description = parsed.get("description", "").strip()
    headings = extract_headings(body)

    # Run all category checks
    checks: dict[str, list[Issue]] = {
        "frontmatter": check_frontmatter(parsed, skill_dir, min_description_chars, strict_frontmatter),
        "body": check_body_structure(body, headings, max_lines),
        "description": check_description_quality(description),
        "style": check_writing_style(body),
        "disclosure": check_progressive_disclosure(body, skill_dir),
        "content": check_content_richness(body, headings),
        "references": check_reference_files(skill_dir),
        "architecture": check_architecture(skill_dir),
    }

    # Apply category filter if specified
    for cat_name, cat_issues in checks.items():
        if category_filter and cat_name != category_filter:
            continue
        result.issues.extend(cat_issues)

    # Score: start at 100, deduct by severity
    deductions = sum(
        FAIL_WEIGHT if i.severity == "fail"
        else WARN_WEIGHT if i.severity == "warn"
        else INFO_WEIGHT
        for i in result.issues
    )
    result.score = max(0, 100 - deductions)
    result.grade = grade_from_score(result.score)
    return result


# ── Output formatting ────────────────────────────────────────────────────────

def print_report(results: list[SkillResult], verbose: bool) -> None:
    print("grade\tscore\tfails\twarns\tinfos\tskill")
    for r in results:
        skill_name = r.skill_dir.name
        print(f"{r.grade}\t{r.score}\t{len(r.fails)}\t{len(r.warns)}\t{len(r.infos)}\t{skill_name}")
        if verbose:
            for issue in r.issues:
                tag = issue.severity.upper()
                print(f"  {tag}: [{issue.category}] {issue.message}")

    total = len(results)
    total_fails = sum(len(r.fails) for r in results)
    total_warns = sum(len(r.warns) for r in results)
    total_infos = sum(len(r.infos) for r in results)
    grades = {g: sum(1 for r in results if r.grade == g) for g in ("A", "B", "C", "D", "F")}
    avg_score = sum(r.score for r in results) / max(total, 1)

    print("")
    print(f"skills={total}  fails={total_fails}  warns={total_warns}  infos={total_infos}  avg_score={avg_score:.0f}")
    print(f"grades: A={grades['A']} B={grades['B']} C={grades['C']} D={grades['D']} F={grades['F']}")


def print_json(results: list[SkillResult]) -> None:
    import json
    data = []
    for r in results:
        data.append({
            "skill": r.skill_dir.name,
            "path": str(r.skill_dir),
            "grade": r.grade,
            "score": r.score,
            "issues": [
                {"message": i.message, "category": i.category, "severity": i.severity}
                for i in r.issues
            ],
        })
    print(json.dumps(data, indent=2))


# ── Refactor plan ────────────────────────────────────────────────────────────

def action_for_issue(issue: Issue, skill_dir: Path) -> str:
    msg = issue.message.lower()
    sf = str(skill_dir / "SKILL.md")

    actions: list[tuple[str, str]] = [
        ("missing yaml frontmatter", f"Add YAML frontmatter with `name` and `description` in `{sf}`."),
        ("frontmatter missing 'name'", f"Add a valid `name` field to `{sf}`."),
        ("frontmatter missing 'description'", f"Add a trigger-rich `description` field to `{sf}` (include `Use when...` and `Triggers:` keyword list)."),
        ("invalid skill name format", f"Fix skill name to match `[a-z0-9][a-z0-9-]{{1,62}}` in `{sf}`."),
        ("description too short", f"Expand `description` in `{sf}` to 50-150 words: what it does, when to use it, and a `Triggers:` keyword list."),
        ("description lacks trigger language", f"Add 'Use when...' phrasing to `description` in `{sf}`. This is the primary mechanism for Claude to decide when to invoke the skill."),
        ("description missing explicit 'triggers:'", f"Append `Triggers: keyword1, keyword2, ...` to the description in `{sf}`. Include both direct and adjacent-domain keywords."),
        ("description too brief", f"Expand description in `{sf}` to at least {MIN_DESCRIPTION_WORDS} words covering scope, trigger contexts, and keywords."),
        ("description very long", f"Trim description in `{sf}` to ~100 words. Move details into the SKILL.md body."),
        ("description may undertrigger", f"Add multiple 'Use when...' scenarios to description in `{sf}`. Claude undertriggers by default — be slightly 'pushy'."),
        ("description uses hedging", f"Replace hedging words (might, possibly, perhaps) with confident language in `{sf}` description."),
        ("body too long", f"Move deep-dive content from `{sf}` into `references/` files. Keep SKILL.md to core workflow + decision trees + quality gates (~400-500 lines)."),
        ("body is very short", f"Add workflow steps, code examples, quality gates, and output contract to `{sf}`."),
        ("missing workflow", f"Add a `## Workflow` section with numbered, execution-ready steps in `{sf}`."),
        ("missing quality gates", f"Add `## Quality Gates` or `## Validation` with measurable pass/fail criteria in `{sf}`."),
        ("missing output contract", f"Add `## Output Contract` listing the concrete deliverables the skill produces in `{sf}`."),
        ("high density of all-caps imperatives", f"Reduce MUST/ALWAYS/NEVER in `{sf}`. Replace with reasoning: 'Avoid X because [reason]', 'This prevents [problem]'. Models respond better to understanding than commands."),
        ("low why-to-imperative ratio", f"Add explanations after rules in `{sf}`. For each MUST/NEVER, add a 'because...' clause explaining the reasoning."),
        ("no progressive disclosure links", f"Add `references/` links in `{sf}` and create reference files for domain deep-dives."),
        ("links to references/ but the directory does not exist", f"Create `{skill_dir}/references/` and populate with referenced files."),
        ("references/ directory exists but contains no files", f"Populate `{skill_dir}/references/` or remove the empty directory."),
        ("scripts/ directory exists but contains no files", f"Populate `{skill_dir}/scripts/` or remove the empty directory."),
        ("script is not executable", f"Run `chmod +x` on scripts in `{skill_dir}/scripts/`."),
        ("body is .* lines with no references/", f"Create `{skill_dir}/references/` and split domain content from `{sf}` into focused reference files."),
        ("reference links lack 'when to read' guidance", f"Add context to each reference link in `{sf}`: 'For security hardening → see references/SECURITY.md'."),
        ("no code fences", f"Add code examples with language-specific fencing (```typescript, ```bash) in `{sf}`."),
        ("no labeled examples", f"Add labeled examples (Example 1, Example 2) with Input → Output in `{sf}`."),
        ("no anti-patterns section", f"Add `## Anti-Patterns` with a table: Anti-Pattern | Why It's Dangerous | Fix in `{sf}`."),
        ("no decision tree", f"Add `## Decision Tree` or `## Choosing...` section to help select the right approach in `{sf}`."),
        ("no core principles", f"Add `## Core Principles` table explaining the WHY behind the skill's approach in `{sf}`."),
        ("no checklist", f"Add a review checklist with `- [ ]` items that the model checks before delivering output in `{sf}`."),
        ("reference file .* lines with no table of contents", "Add a `## Table of Contents` with anchor links to the large reference file."),
        ("banned auxiliary file", f"Remove the file from `{skill_dir}` and keep guidance in SKILL.md or references/."),
        ("directory name .* differs from frontmatter", f"Align directory name with frontmatter `name` in `{sf}`."),
    ]

    for pattern, action in actions:
        if re.search(pattern, msg):
            return action

    return f"Address issue in `{sf}`: {issue.message}"


def write_refactor_plan(results: list[SkillResult], output_path: str) -> None:
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    lines.append("# Skill Refactor Plan — Skill Creator 2.0 Compliance")
    lines.append("")
    lines.append("Auto-generated by `scripts/check-skill-quality.py --emit-plan`.")
    lines.append("")
    lines.append("## Summary")
    lines.append("")

    failing = [r for r in results if r.fails]
    warning = [r for r in results if r.warns and not r.fails]
    passing = [r for r in results if not r.fails and not r.warns]

    lines.append(f"- **{len(failing)}** skills with FAILs (need refactoring)")
    lines.append(f"- **{len(warning)}** skills with WARNs only (should improve)")
    lines.append(f"- **{len(passing)}** skills fully passing")
    lines.append("")

    # Priority order: most fails first
    ranked = sorted(results, key=lambda r: (len(r.fails), len(r.warns)), reverse=True)

    for result in ranked:
        if not result.issues:
            continue
        lines.append(f"## {result.skill_dir.name}")
        lines.append("")
        lines.append(f"- Grade: **{result.grade}** (score {result.score})")
        lines.append(f"- Fails: {len(result.fails)} | Warns: {len(result.warns)} | Infos: {len(result.infos)}")
        lines.append("")

        # Group by category
        categories: dict[str, list[Issue]] = {}
        for issue in result.issues:
            categories.setdefault(issue.category, []).append(issue)

        for cat_name, cat_issues in categories.items():
            lines.append(f"### {cat_name.title()}")
            lines.append("")
            for issue in cat_issues:
                sev_tag = issue.severity.upper()
                lines.append(f"- **{sev_tag}**: {issue.message}")
                lines.append(f"  - Action: {action_for_issue(issue, result.skill_dir)}")
            lines.append("")

    if len(lines) <= 8:
        lines.append("All skills pass Skill Creator 2.0 checks.")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ── Entry point ──────────────────────────────────────────────────────────────

def main() -> int:
    args = parse_args()
    skill_dirs = discover_skill_dirs(args.paths)
    if not skill_dirs:
        print("No skills found for provided paths.", file=sys.stderr)
        return 1

    results = [
        evaluate_skill(
            skill_dir=sd,
            max_lines=args.max_lines,
            min_description_chars=args.min_description_chars,
            strict_frontmatter=args.strict_frontmatter,
            profile=args.profile,
            category_filter=args.category,
        )
        for sd in skill_dirs
    ]

    if args.json:
        print_json(results)
    else:
        print_report(results, args.verbose)

    if args.emit_plan:
        write_refactor_plan(results, args.emit_plan)

    fail_count = sum(len(r.fails) for r in results)
    warn_count = sum(len(r.warns) for r in results)
    if fail_count > 0:
        return 1
    if args.fail_on_warn and warn_count > 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
