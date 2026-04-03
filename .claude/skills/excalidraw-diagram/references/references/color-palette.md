# Color Palette

Single source of truth for semantic colors. Customize this file to match brand style.

## Semantic Shape Colors

| Semantic Role | Fill | Stroke | Typical Use |
|---|---|---|---|
| Primary/Neutral | `#DBEAFE` | `#1E3A8A` | Core process or default node |
| Secondary | `#E0F2FE` | `#0C4A6E` | Supporting node |
| Start/Trigger | `#FFEDD5` | `#C2410C` | Inputs, entry points |
| End/Outcome | `#DCFCE7` | `#166534` | Results and exits |
| Decision | `#FEF3C7` | `#B45309` | Branching and conditions |
| Warning/Risk | `#FEE2E2` | `#B91C1C` | Faults, resets, risk areas |
| AI/Model | `#EDE9FE` | `#6D28D9` | LLM/AI-specific blocks |
| External System | `#F1F5F9` | `#334155` | Third-party components |

Rule: always pair dark stroke with lighter fill.

## Text Hierarchy Colors

| Text Role | Color | Use |
|---|---|---|
| Title | `#1E3A8A` | Section titles and main labels |
| Subtitle | `#2563EB` | Secondary labels |
| Body | `#475569` | Annotations and detail text |
| Text on light fills | `#1F2937` | Shape labels |
| Text on dark fills | `#FFFFFF` | Evidence artifacts |

## Evidence Artifact Colors

| Artifact | Background | Text |
|---|---|---|
| Code block | `#0F172A` | syntax-colored |
| JSON/data block | `#111827` | `#22C55E` |
| Terminal/log block | `#111827` | `#E2E8F0` |

## Line and Arrow Defaults

| Element | Color |
|---|---|
| Main flow arrows | Source element stroke color |
| Structural lines | `#334155` |
| Divider lines (dashed) | `#64748B` |
| Timeline dots | `#2563EB` |

## Alternate Theme Recipe

If a user requests a new theme, preserve semantic mapping and only swap values:

1. Keep semantic roles unchanged.
2. Replace hex values in role tables.
3. Ensure text contrast remains readable.
4. Re-render one sample diagram before applying broadly.

