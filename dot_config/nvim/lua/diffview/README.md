# Diffview

Browse a git repo's working-tree changes in an [oil.nvim](https://github.com/stevearc/oil.nvim)
buffer, and view each file side-by-side (HEAD vs working tree) with full
treesitter syntax highlighting.

No `git add` needed: it always diffs the working tree against HEAD, and lists
untracked files too.

## Usage

**Open:** `:GitDiff` — opens a single side-by-side view of every changed file's
hunks at once, mirroring terminal `git diff` (hunks only, tracked changes only,
joint scrolling, per-file `━━━ path ━━━` headers).

From that combined view:
- `<C-p>` — drop into the file-list preview: opens the oil list of changed
  files with live preview beside it.

In the oil list:
- `<CR>` — open the file's full side-by-side diff. `\` returns to the list.
- `<C-p>` — toggle live preview beside the list; moving the cursor updates the
  diff to the file under it.

Each list row shows a status marker (`+` new, `-` deleted, `~` modified) and,
right aligned, the `+A -D` line counts.

## Config

```lua
require("plugin-diffview").setup({
  keymap_open = "<CR>",
  keymap_preview = "<C-p>",
  colors = {
    new = "#2ea043",      -- added / untracked
    deleted = "#da3633",  -- deleted
    modified = "#8b949e", -- modified
  },
})
```

## Architecture

- `git.lua` — git plumbing (status, numstat, HEAD/worktree contents). No UI.
- `ui.lua` — scratch diff buffers, side-by-side layout, status column, count
  virtual text, highlights.
- `oil.lua` — the `oil-diff://` adapter (frontend). Read-only for now;
  `perform_action` is stubbed for future git mutations (unstage, checkout, rm).
- `init.lua` — orchestration: wires the above and exposes the verbs the plugin
  keymaps/commands call.

`plugin-diffview.lua` is the thin entry point: config defaults, dependency
check, and `:GitDiff`. It must run after oil.nvim is set up.
