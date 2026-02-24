# rgo

A collection of fzf-powered commands that search your codebase and open results in your editor. Designed for multi-repo workspaces but works in single repos too.

## Commands

### `rgz` / `rgv` — Search by content (ripgrep)

Search file contents across repositories, pick with fzf, open at the matching line.

```bash
rgz "pattern"              # search → fzf → Zed (at matching line)
rgv "pattern"              # search → fzf → Neovim (tabs, at matching line)

rgz "TODO" -i              # case insensitive
rgz "pattern" -g '*.tsx'   # only .tsx files
rgv "className" -t js      # only JavaScript files
```

**Multi-repo aware**: In a workspace with multiple git repos side by side, `rg` ignores sub-repositories' `.gitignore` files. `rgz`/`rgv` run ripgrep inside each sub-repo independently, so each repo's own `.gitignore` is properly respected.

```
workspace/
├── repo-a/       # ← searched independently (.gitignore respected)
├── repo-b/       # ← searched independently (.gitignore respected)
└── notes.md      # ← also searched
```

### `gdz` / `gdv` — Browse by git commits

Browse recent commits, select changed files, and open them in your editor.

```bash
gdz                        # commits → files → Zed
gdv                        # commits → files → Neovim (tabs)
```

**Flow:**

1. Recent 20 commits are shown (plus a "branch diff" option at the top)
2. Select one or more commits with `Tab`, or pick the branch option to get all changes since the base branch
3. Changed files from those commits are shown
4. Select files with `Tab` (or `Ctrl-A` to select all)
5. `Enter` to open in your editor

The base branch (`main`, `master`, or `develop`) is auto-detected.

## Summary

| Command | Source  | Editor | Open style |
|---------|---------|--------|------------|
| `rgz`   | ripgrep | Zed    | Each file at `file:line` |
| `rgv`   | ripgrep | Neovim | All files in tabs |
| `gdz`   | git log | Zed    | All files |
| `gdv`   | git log | Neovim | All files in tabs |

## Requirements

- [fzf](https://github.com/junegunn/fzf)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for `rgz`/`rgv`)
- [Zed](https://zed.dev) and/or [Neovim](https://neovim.io)
- zsh
- [bat](https://github.com/sharkdp/bat) (optional, for file preview in `gdz`/`gdv`)

## Installation

Source only the ones you need:

```bash
# Add to your .zshrc
source /path/to/rgo/rgz.zsh   # ripgrep → Zed
source /path/to/rgo/rgv.zsh   # ripgrep → Neovim
source /path/to/rgo/gdz.zsh   # git diff → Zed (also provides gdv's dependency)
source /path/to/rgo/gdv.zsh   # git diff → Neovim
```

Or copy to your zsh functions directory:

```bash
cp *.zsh ~/.zsh/functions/
```

> **Note:** `gdv.zsh` depends on `_gd_select_files` defined in `gdz.zsh`. Make sure `gdz.zsh` is loaded first.

## fzf Controls

| Key     | Action |
|---------|--------|
| `Enter` | Confirm selection |
| `Tab`   | Toggle multi-select |
| `Ctrl-A`| Select all (in file selection) |

## License

MIT
