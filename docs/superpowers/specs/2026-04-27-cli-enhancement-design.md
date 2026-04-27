# CLI Enhancement Design

## Summary

Enhance the HCL CLI tool (`moon run cmd/main`) with missing features: multi-file processing, output file, custom indent, JSON input mode, version info, colored error output with source context.

## Options

| Option | Description |
|--------|-------------|
| `--version` | Print version (`hcl-moonbit v0.3.0`) and exit |
| `-o, --output FILE` | Write output to file (error if multi-file) |
| `--indent N` | Indent width (default 2, for JSON pretty + HCL format) |
| `-j, --json-input` | Input is JSON, output as HCL (implies `--format`) |
| `--color` / `--no-color` | Force enable/disable ANSI color |
| `--help` | Updated help with all options |

### Argument parsing changes

- Multiple positional args → multi-file mode
- `--file` / `-f` still works (single file), deprecated in favor of positional

## Multi-file behavior

| Mode | Single file | Multiple files |
|------|-------------|----------------|
| JSON output | Normal JSON | `{ "path": ..., "path2": ... }` |
| `--format` | Formatted HCL | Separated by `/* file: path */\n` headers |
| `--validate` | Exit 0/1 | Per-file results, exit = failure count |
| `--output FILE` | Write to file | Error (refuse) |

## Error formatting

Instead of plain `e.message()`, show:

```
Error: <type> at line L, column C
  | key = value + x
  |              ^
  | Undefined variable: x
```

- Red color for error header (unless `--no-color` or `NO_COLOR` set)
- Source context line from the original HCL input
- `^^^^` underline under the error column

## Internal changes

### `json.mbt`
- `body_to_json_pretty` gains optional `indent` param (backward compatible)

### `cmd/main/main.mbt`
- New `CliConfig` struct to hold parsed args
- `format_error` helper for colored error output with source context
- Restructured main loop for multi-file processing
- Color support via `\u001b[XXm` ANSI codes + `NO_COLOR` check via `@env.get_env_var`

## Files to modify

1. `cmd/main/main.mbt` — main CLI logic, all new options, error formatting, multi-file
2. `cmd/main/moon.pkg` — add `"moonbitlang/core/env"` dependency if not present
3. `json.mbt` — `body_to_json_pretty` indent param

## Non-goals

- stdin support (MoonBit limitation)
- glob patterns (MoonBit limitation)
- subcommands (keep flat flag-based CLI)
