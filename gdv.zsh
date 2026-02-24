# gdv - git diff + fzf + nvim
# Browse recent commits (or branch diff), pick changed files with fzf, open in nvim tabs.
# Usage: gdv
# Requires: gdz.zsh (for _gd_select_files)

gdv() {
  _gd_select_files || return 1

  local files=()
  while read -r f; do
    files+=("$f")
  done < "$_GD_RESULT_FILE"
  rm -f "$_GD_RESULT_FILE"

  nvim -p "${files[@]}"
}
