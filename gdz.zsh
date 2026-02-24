# gdz - git diff + fzf + zed
# Browse recent commits (or branch diff), pick changed files with fzf, open in Zed.
# Usage: gdz

# Shared search logic for gdz/gdv
_gd_select_files() {
  # Detect base branch
  local base_branch=""
  for b in main master develop; do
    if git rev-parse --verify "$b" &>/dev/null; then
      base_branch="$b"
      break
    fi
  done

  # Step 1: Show commits with fzf multi-select
  local commit_list
  commit_list=$({
    [[ -n "$base_branch" ]] && echo "[branch] All changes since $base_branch"
    git log --oneline -20
  })

  local selected_commits
  selected_commits=$(echo "$commit_list" | fzf --multi \
    --header "Tab: multi-select | Select commit(s) to see changed files" \
    --preview='
      line={};
      if [[ "$line" == "\[branch\]"* ]]; then
        git diff --stat $(git merge-base '"$base_branch"' HEAD)..HEAD
      else
        hash=$(echo {} | awk "{print \$1}");
        git show --stat --format="%h %s%n%an | %ar" "$hash"
      fi
    ')

  [[ -z "$selected_commits" ]] && return 1

  # Step 2: Collect changed files from selected commits
  local files=()
  while read -r line; do
    if [[ "$line" == "[branch]"* ]]; then
      files+=(${(f)"$(git diff --name-only $(git merge-base "$base_branch" HEAD)..HEAD 2>/dev/null)"})
    else
      local hash="${line%% *}"
      files+=(${(f)"$(git diff-tree --no-commit-id --name-only -r "$hash" 2>/dev/null)"})
    fi
  done <<< "$selected_commits"

  # Deduplicate and filter to existing files
  files=(${(u)files})
  local existing=()
  for f in "${files[@]}"; do
    [[ -f "$f" ]] && existing+=("$f")
  done

  if [[ ${#existing[@]} -eq 0 ]]; then
    echo "No changed files found."
    return 1
  fi

  # Step 3: File selection with fzf
  printf '%s\n' "${existing[@]}" | fzf --multi \
    --header "Tab: multi-select | Ctrl-A: select all" \
    --bind "ctrl-a:select-all" \
    --preview="bat --color=always --style=numbers {} 2>/dev/null || cat {}"
}

gdz() {
  local selected
  selected=$(_gd_select_files)
  [[ -z "$selected" ]] && return 1

  echo "$selected" | xargs zed
}
