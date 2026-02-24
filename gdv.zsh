# gdv - git diff + fzf + nvim
# Browse recent commits (or branch diff), pick changed files with fzf, open in nvim tabs.
# Usage: gdv
# Requires: gdz.zsh (for _gd_select_files)

gdv() {
  local selected
  selected=$(_gd_select_files)
  [[ -z "$selected" ]] && return 1

  local files=()
  while read -r f; do
    files+=("$f")
  done <<< "$selected"

  nvim -p "${files[@]}"
}
