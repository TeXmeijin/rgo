# gdz - git diff + fzf + zed
# Browse recent commits (or branch diff), pick changed files with fzf, open in Zed.
# Usage: gdz

# Shared search logic for gdz/gdv
# Writes selected files (absolute paths) to a temp file, sets _GD_RESULT_FILE
_gd_select_files() {
  # Must be in a git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository." >&2
    return 1
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)

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
    git log --oneline --no-merges -20
  })

  local tmpfile_commits=$(mktemp)
  echo "$commit_list" | fzf --multi \
    --header "Tab: multi-select | Select commit(s) to see changed files" \
    --preview='
      line={};
      if [[ "$line" == "\[branch\]"* ]]; then
        git diff --stat $(git merge-base '"$base_branch"' HEAD)..HEAD 2>/dev/null
      else
        hash=$(echo {} | awk "{print \$1}");
        git show --stat --format="%h %s%n%an | %ar" "$hash" 2>/dev/null
      fi
    ' > "$tmpfile_commits"

  if [[ ! -s "$tmpfile_commits" ]]; then
    rm -f "$tmpfile_commits"
    return 1
  fi

  # Step 2: Collect changed files from selected commits
  local files=()
  while read -r line; do
    if [[ "$line" == "[branch]"* ]]; then
      files+=(${(f)"$(git diff --name-only $(git merge-base "$base_branch" HEAD)..HEAD 2>/dev/null)"})
    else
      local hash="${line%% *}"
      files+=(${(f)"$(git diff-tree --no-commit-id --name-only -r "$hash" 2>/dev/null)"})
    fi
  done < "$tmpfile_commits"
  rm -f "$tmpfile_commits"

  # Deduplicate, resolve to absolute paths, filter to existing files
  files=(${(u)files})
  local existing=()
  for f in "${files[@]}"; do
    local fullpath="$repo_root/$f"
    [[ -f "$fullpath" ]] && existing+=("$fullpath")
  done

  if [[ ${#existing[@]} -eq 0 ]]; then
    echo "No changed files found." >&2
    return 1
  fi

  # Step 3: File selection with fzf
  _GD_RESULT_FILE=$(mktemp)
  printf '%s\n' "${existing[@]}" | fzf --multi \
    --header "Tab: multi-select | Ctrl-A: select all" \
    --bind "ctrl-a:select-all" \
    --preview="bat --color=always --style=numbers {} 2>/dev/null || cat {}" \
    > "$_GD_RESULT_FILE"

  if [[ ! -s "$_GD_RESULT_FILE" ]]; then
    rm -f "$_GD_RESULT_FILE"
    return 1
  fi
}

gdz() {
  _gd_select_files || return 1

  while read -r f; do
    zed "$f"
  done < "$_GD_RESULT_FILE"
  rm -f "$_GD_RESULT_FILE"
}
