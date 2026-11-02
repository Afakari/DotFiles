; inherits: jinja

; The text between Jinja tags is SQL. Combined, so the pieces parse as one query.
((content) @injection.content
  (#set! injection.language "sql")
  (#set! injection.combined))
