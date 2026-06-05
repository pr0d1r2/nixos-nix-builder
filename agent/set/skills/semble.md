Prefer semble search over grep and find for multi-file code
exploration. Semble uses semantic and lexical hybrid search to
find relevant code with fewer tokens than reading files directly.

Use semble MCP tools (search, find_related) when exploring
unfamiliar code or looking for implementations across files.

Fall back to grep only for exact string matches like error
messages, specific identifiers, or config keys where precision
matters more than semantic relevance.
