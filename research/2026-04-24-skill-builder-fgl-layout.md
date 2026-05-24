# Skill Research: fgl-layout

## Use Cases
1. **Design a new ticket layout from a description** — "I need a 2x5.5 ticket with a logo top-left, event title centered, seat block on the right, and a code-128 barcode along the bottom edge." Skill produces a working `.fgl` file.
2. **Embed an image as an FGL logo** — user supplies a PNG path; skill converts it to FGL hex (`<RC{r,c}><g{n}>...`) and either drops it inline in a layout or saves it as a standalone snippet for `<LD#>` printing.
3. **Iterate on an existing `.fgl` artifact** — user pastes a layout, asks to "move the seat row up by 30 dots" or "make the title 3x size"; skill edits in place.
4. **Anti-pattern**: not a printer driver. Skill produces FGL text and (optionally) a sample sender script — it does not own the host-to-printer transport.

## Category
Document & Asset Creation (FGL stream is the asset; the printer guide is the style guide).

## Requirements
- **Trigger**: `/fgl-layout [description-or-fgl-path]`. Auto-load on phrases like "FGL ticket", "BOCA layout", "Friendly Ghost Language", "convert PNG to FGL".
- **Input**: free-form ticket description, OR path to an existing `.fgl` file to edit, OR path to an image to convert.
- **Output**: `thoughts/shared/fgl/<slug>.fgl` (the layout) and optionally `thoughts/shared/fgl/<slug>.png-snippet.fgl` for image-only conversions. A companion `send.py` may be co-written when the user asks for one.
- **Tools**: `Read, Grep, Glob, Write, Edit, AskUserQuestion, TodoWrite, Bash(python3 *), Bash(ls *), Bash(file *)` — Bash is needed to invoke the bundled `scripts/png_to_fgl.py` converter and to inspect image files.
- **Interactions**: confirm printer/dpi/dimensions; confirm layout regions before emitting; for image conversion, confirm threshold and dither.

## Defaults (per user)
- Printer: BOCA FGL46 R2/8 SB07
- DPI: 300 (dot size .00328" → ~304.9 dpi; ticket area ≈ **600 dot rows × 1650 dot columns** for a 2"×5.5" ticket)
- Default font: `<F3>` (17×31 at 200 dpi, scales on 300 dpi).
- Termination: `<p>` (preferred over `<FF>` per the host-to-printer supplement, since some hosts strip 0x0C).

## Key FGL knowledge to encode
- Coordinate system: `(0,0)` top-left; `<RCr,c>`; rotation `<NR/RR/RU/RL>` and how it changes the *next character's* origin.
- Sizing: `<HWw,h>` (max 16 with soft fonts), `<BSw,h>` (box size), `<F1>..<F13>` resident fonts, `<TTF#,pt>` for TrueType.
- Drawing: `<BXr,c>`, `<VXr>`, `<HXc>`, `<LT#>` (line thickness — must be re-sent before each shape).
- Bar codes: old uppercase select (`<NL5>123456`) vs new lowercase (`<nL5>` respects rotation); `<X2>` width expand; `<BI>` adds human-readable.
- Graphics: `<G#>byte1,byte2,...byte#` raw decimal OR `<g#>HEXHEXHEX` ASCII hex (# = 2× the byte count). One byte = 8 vertical dots, MSB on top.
- Image conversion algorithm (per rsmck.co.uk + guide page 37):
  1. 1-bit threshold the input.
  2. For each strip of 8 vertical pixels, pack MSB-top into one byte.
  3. Emit `<RC{strip_top},{x_start}><g{2*bytes}>HEXHEX...` per row strip.
  4. Bracket the whole logo download in `ESC` (0x1B) characters when storing as a downloadable logo (`<ID#>...esc<RC0,0><g#>...esc`).
- Termination: `<p>` to print without cut, `<p>` is also safest with hosts that strip FF.

## Similar Skills (patterns to borrow)
- `tech-spec`: frontmatter style, "Brief-then-Ask" Context Principle for AskUserQuestion, current-context backtick block.
- `write-artifact`: artifact slugging and `thoughts/shared/<topic>/` output convention.
- `research-codebase`: progressive disclosure into `references/`.

## Output Layout
```
skills/fgl-layout/
  SKILL.md
  references/
    commands.md          # complete FGL command tables
    image-to-fgl.md      # conversion algorithm + script usage
    coordinate-math.md   # 200/300 dpi sizing, ticket geometry
  templates/
    basic-ticket.fgl
    event-ticket.fgl
  scripts/
    png_to_fgl.py        # working PNG/BMP -> FGL hex converter
```

## Conventions to Follow
- `model: opus`, `user-invocable: true`, no `context: fork` (uses AskUserQuestion).
- Current Context with `!`backtick git commands.
- Initial Response handles with-args and no-args.
- Output to `thoughts/shared/fgl/`.
