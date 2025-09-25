# User visible changes in `ParsingTools`

## Unreleased

### Changed

- The respective `type` of opening and closing tokens is `:opening` and `:closing`. It was
  `:open` and `:close`.

### Added

- Predicate functions `is_asterisk`, `is_character`, `is_closing`, `is_closing_brace`,
  `is_closing_bracket`, `is_closing_parenthesis`, `is_comma`, `is_comment`,
  `is_escape_newline`, `is_float`, `is_identifier`, `is_integer`, `is_literal`, `is_number`,
  `is_opening`, `is_opening_brace`, `is_opening_bracket`, `is_opening_parenthesis`,
  `is_operator`, `is_semicolon`, `is_separator`, and `is_string`.

### Fixed

- Line number is that of the line where sits the 1st character of a token.
