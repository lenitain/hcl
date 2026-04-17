# Better Error Messages Plan

## Goal
Improve HCL error messages with context information and fix suggestions.

## Requirements
From PROGRESS.md:
- Context information
- Fix suggestions

## Current State
- `HCLError` enum with `ParseError(String, Int, Int, Int)` (msg, line, column, offset)
- Parser generates errors with location info
- `message()` method produces basic messages

## Design

### 1. Enhanced ParseError
Add context line(s) to ParseError:
```moonbit
pub(all) enum HCLError {
  ParseError(String, Int, Int, Int, String)  // last String = context line
  // ... existing variants
}
```

### 2. Context Extraction
When parser encounters error, extract from `Lexer.input`:
- Current line (where error occurred)
- Possibly previous line for context

### 3. Fix Suggestions
Based on error type, suggest common fixes:
- "Expected X, got Y" → suggest checking syntax
- Missing closing bracket/brace → suggest matching pairs
- Unexpected token → suggest valid alternatives

### 4. Enhanced message() Format
```
Parse error at line 5, column 12: Expected '=', got '}'
  |
5 | resource "aws_instance" "example" {
  |            ^
  |
Suggestion: Did you forget '=' after attribute name?
```

## Tasks
1. Modify `HCLError` enum to include context
2. Update `parse_error()` constructor
3. Update `Parser` to extract context lines from lexer input
4. Update `message()` to display context and suggestions
5. Add tests for new error messages
6. Ensure backward compatibility (existing tests pass)

## Constraints
- MoonBit string handling (UTF-16)
- No breaking changes to existing API
- Keep error handling simple and performant