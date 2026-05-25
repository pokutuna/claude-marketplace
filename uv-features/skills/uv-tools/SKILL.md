---
name: uv-tools
description: Guide uvx and uv tool install usage. Use when running Python CLI tools via uv.
---

# Python CLI Tools with uvx

`uvx` runs Python CLI tools in an isolated, cached environment without installing them into the project or globally.

## Usage

```bash
uvx ruff check .                           # Run without installing
uvx ruff@0.8.0 check .                     # Pin a version
uvx ruff@latest check .                    # Force latest
uvx --from='httpie' http GET example.com   # Package name ≠ command name
uvx --with='mkdocs-material' mkdocs serve  # Additional plugin
```

## Persistent Installation

For frequently used tools:

```bash
uv tool install ruff    # Install permanently
uv tool list            # List installed tools
uv tool upgrade ruff    # Upgrade a tool
uv tool upgrade --all   # Upgrade all tools
uv tool uninstall ruff  # Remove a tool
```

## Reference

If more detail is needed, consult: https://docs.astral.sh/uv/guides/tools/
