#!/usr/bin/env python3
"""
Score experiment hypotheses with the RICE model.

Input CSV columns:
- hypothesis
- reach
- impact
- confidence
- effort

Output:
- Sorted table by descending RICE score.
"""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass


@dataclass
class Row:
    hypothesis: str
    reach: float
    impact: float
    confidence: float
    effort: float

    @property
    def rice(self) -> float:
        if self.effort <= 0:
            return 0.0
        return (self.reach * self.impact * self.confidence) / self.effort


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Score hypotheses with RICE.")
    parser.add_argument("csv_file", help="Path to CSV file")
    return parser.parse_args()


def parse_float(value: str, field: str, line_no: int) -> float:
    try:
        return float(value)
    except ValueError as exc:
        raise ValueError(f"line {line_no}: invalid {field} value {value!r}") from exc


def load_rows(path: str) -> list[Row]:
    rows: list[Row] = []
    with open(path, "r", encoding="utf-8", newline="") as file_handle:
        reader = csv.DictReader(file_handle)
        required = {"hypothesis", "reach", "impact", "confidence", "effort"}
        missing = required.difference(reader.fieldnames or set())
        if missing:
            raise ValueError(f"missing required columns: {', '.join(sorted(missing))}")

        for line_no, row in enumerate(reader, start=2):
            hypothesis = (row.get("hypothesis") or "").strip()
            if not hypothesis:
                raise ValueError(f"line {line_no}: hypothesis is required")
            reach = parse_float(row.get("reach", ""), "reach", line_no)
            impact = parse_float(row.get("impact", ""), "impact", line_no)
            confidence = parse_float(row.get("confidence", ""), "confidence", line_no)
            effort = parse_float(row.get("effort", ""), "effort", line_no)
            rows.append(
                Row(
                    hypothesis=hypothesis,
                    reach=reach,
                    impact=impact,
                    confidence=confidence,
                    effort=effort,
                )
            )
    return rows


def render(rows: list[Row]) -> None:
    ranked = sorted(rows, key=lambda item: item.rice, reverse=True)
    print("rank\thypothesis\treach\timpact\tconfidence\teffort\trice")
    for idx, row in enumerate(ranked, start=1):
        print(
            f"{idx}\t{row.hypothesis}\t{row.reach:g}\t{row.impact:g}\t"
            f"{row.confidence:g}\t{row.effort:g}\t{row.rice:.2f}"
        )


def main() -> int:
    args = parse_args()
    try:
        rows = load_rows(args.csv_file)
        if not rows:
            print("no rows found", file=sys.stderr)
            return 1
        render(rows)
        return 0
    except Exception as exc:  # noqa: BLE001
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
