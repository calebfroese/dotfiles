# Ethereal Annotations

Ephemeral code annotations for AI. Highlight lines, add comments visible only in nvim, read via CLI.

Annotations are tied to file content hash—any edit invalidates all annotations.

## Neovim

**Add:** Select lines (visual mode) → `"`  
**Delete:** Place cursor on annotated line → `<leader>d"`  
**Clear file:** `:EtherealClear`  
**Clear all:** `:EtherealClearAll`

Input: `Enter` submits, `Ctrl-j` for newline, `Esc` cancels.

## CLI

```bash
ethereal list                    # all annotations
ethereal list --file foo.lua     # filter by file
ethereal clear --file foo.lua    # clear file
ethereal clear --all             # clear all
```

Output: `/path/file.lua:10-15: comment text`

## Storage

`~/.local/share/nvim/ethereal-annotations/<sha256>.txt`

```
/absolute/path/to/file.lua
5:single line comment
10-15:multi-line comment
```

Stale annotations auto-cleanup on CLI read.

## Config

```lua
require("plugin-ethereal-annotations").setup({
  keymap_add = '"',
  keymap_delete = '<leader>d"',
  highlight_bg = "#3d2800",
  comment_fg = "#ff8800",
  storage_path = nil,  -- default: stdpath("data")/ethereal-annotations
})
```
