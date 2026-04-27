# CLI Enhancement Implementation Plan

## Branch
`lenitain/feat/cli-enhancement`

## Tasks

### Task 1: `json.mbt` — Add indent param to `body_to_json_pretty`
- Add optional `indent? : Int = 2` param to `body_to_json_pretty`
- Replace all hardcoded `"  "` with `repeat_string(" ", indent)`
- Keep backward compatibility

### Task 2: `cmd/main/main.mbt` — Restructure arg parsing
- Add `CliConfig` struct with all flags
- Add `--version`, `-o/--output`, `--indent N`, `-j/--json-input`, `--color`/`--no-color`
- Support multiple positional args
- Track original source string per file for error context

### Task 3: `cmd/main/main.mbt` — Error formatting with source context
- `format_error(err, source, no_color)` function
- Show line:column, context line, `^^^^` underline
- ANSI red for error header

### Task 4: `cmd/main/main.mbt` — Multi-file processing
- Loop over files
- JSON mode: combine results into object
- Format mode: headers between files
- Validate mode: per-file results

### Task 5: `cmd/main/main.mbt` — Output file + color support
- `-o` writes to file via `@fs.write_string_to_file`
- Color via ANSI codes, respect `NO_COLOR`
- `--color`/`--no-color` override

### Task 6: Update `moon.pkg` deps if needed
- Ensure `@env` import for `NO_COLOR`

### Task 7: Verify
- `moon check && moon test && moon fmt && moon info`

### Task 8: Update docs
- PROGRESS.md
- README.md / README.mbt.md (CLI section)

## Verification
- `moon check` — 0 errors
- `moon test` — all pass
- `moon fmt` — clean
- `moon info` — clean
- Manual: `moon run cmd/main -- --help`, `--version`, `--indent 4`, etc.
