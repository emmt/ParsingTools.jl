# User visible changes in `ParsingTools`

## Unreleased

### Added

- Predicate functions `is_asterisk`, `is_closing`, `is_closing_brace`, `is_closing_bracket`,
  `is_closing_parenthesis`, `is_comma`, `is_comment`, `is_escape_newline`, `is_identifier`,
  `is_opening`, `is_opening_brace`, `is_opening_bracket`, `is_opening_parenthesis`,
  `is_operator`, `is_semicolon`, and `is_separator`.

### Fixed

- Line number is that of the line where sits the 1st character of a token.
