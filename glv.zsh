# glv - git log + fzf + nvim
# Browse recent commits (or branch diff), pick changed files with fzf, open in nvim tabs.
# Usage: glv
# Requires: glz.zsh (for _gl_select_files)

glv() {
  _gl_select_files || return 1

  local files=()
  while read -r f; do
    files+=("$f")
  done < "$_GL_RESULT_FILE"
  rm -f "$_GL_RESULT_FILE"

  nvim -p "${files[@]}"
}
