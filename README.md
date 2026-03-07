> [!WARNING]
> 🚧 **Work in Progress**
>
> This plugin is currently under active development.
>
> - APIs and configuration may change
> - Breaking changes can occur without notice
>
> Use with caution until a stable release is announced.
> Issues, suggestions, and contributions are welcome while the project evolves.

# loop-marks.nvim

Workspace bookmarks and notes for [loop.nvim](https://github.com/mbfoss/loop.nvim). Per-workspace marks and inline notes that persist with your Loop workspace.

## Requirements

- **Neovim** ≥ 0.10  
- **[loop.nvim](https://github.com/mbfoss/loop.nvim)**

## Features

- **Bookmarks** — Named marks with a sign in the sign column. Jump to any bookmark via a picker.
- **Notes** — Inline notes at the end of lines (extmarks). Add text annotations to specific lines.
- **Persistence** — Marks and notes are stored per workspace and restored when you reopen.
- **Signs** — Bookmarks use a sign column symbol; notes are shown as virtual text at end-of-line.

## Installation

**lazy.nvim**

```lua
{
    "mbfoss/loop-marks.nvim",
    dependencies = { "mbfoss/loop.nvim" },
}
```

## Quick Start

1. Install loop.nvim and loop-marks.nvim.
2. Open a loop workspace (`:Loop workspace open`).
3. Add a bookmark: `:Loop mark set` or `:Loop mark` — Prompts for a name at the current line.
4. Add a note: `:Loop note set` or `:Loop note` — Prompts for note text at the current line.
5. Jump to a bookmark: `:Loop mark list` — Opens a picker to select and jump.
6. Jump to a note: `:Loop note list` — Opens a picker to select and jump.

## Commands

### Bookmarks (`:Loop mark ...`)

| Command | Description |
|--------|-------------|
| `:Loop mark set` | Set a bookmark at the current line (prompts for name) |
| `:Loop mark list` | Open picker to jump to a bookmark |
| `:Loop mark delete` | Remove bookmark at current line |
| `:Loop mark clear_file` | Clear all bookmarks in current file |
| `:Loop mark clear_all` | Clear all bookmarks in current workspace |

### Notes (`:Loop note ...`)

| Command | Description |
|--------|-------------|
| `:Loop note set` | Set a note at the current line (prompts for text) |
| `:Loop note list` | Open picker to jump to a note |
| `:Loop note delete` | Remove note at current line |
| `:Loop note clear_file` | Clear all notes in current file |
| `:Loop note clear_all` | Clear all notes in current workspace |

## Configuration

```lua
require("loop-marks").setup({
    mark_sign_priority = 50,
    note_sign_priority = 50,
    mark_symbol = "*",
    note_symbol = "✎",
})
```

| Option | Type | Description |
|--------|------|-------------|
| `mark_sign_priority` | number | Sign priority for bookmark signs |
| `note_sign_priority` | number | Sign priority for note extmarks |
| `mark_symbol` | string | Symbol shown in sign column for bookmarks |
| `note_symbol` | string | Symbol shown in note text for notes |

## License

MIT
