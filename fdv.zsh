# fdv - fd + fzf + nvim
# Search filenames across sub-repositories (respecting each repo's .gitignore), pick with fzf, open in nvim tabs.
# Works both in multi-repo workspaces and inside a single repo.
# Usage: fdv [pattern] [fd options...]
fdv() {
  local results=()
  local has_subrepos=false

  # Search in sub-repos (directories with their own .git)
  for d in */; do
    if [[ -d "$d/.git" ]]; then
      has_subrepos=true
      results+=(${(f)"$(fd --type f "$@" "$d" 2>/dev/null)"})
    fi
  done

  if $has_subrepos; then
    # Also search current directory's own files (depth 1)
    results+=(${(f)"$(fd --type f --max-depth 1 "$@" 2>/dev/null)"})
  else
    # Single repo — just run fd normally
    results+=(${(f)"$(fd --type f "$@" 2>/dev/null)"})
  fi

  if [[ ${#results[@]} -eq 0 ]]; then
    echo "No matches found."
    return 1
  fi

  local preview_cmd="bat --style=numbers --color=always {} 2>/dev/null || cat {}"

  local selected
  selected=$(printf '%s\n' "${results[@]}" | fzf --multi \
    --preview="$preview_cmd" \
    --preview-window=right:60%)

  if [[ -n "$selected" ]]; then
    local files=()
    while read -r item; do
      files+=("$item")
    done <<< "$selected"

    # Open all files in tabs
    nvim -p "${files[@]}"
  fi
}
