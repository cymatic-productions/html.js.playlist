# ...existing code...
#!/usr/bin/env bash
set -euo pipefail

# Scans for git repos under the current directory.
# For each repo found, copies any root-level *.<ext> into:
#   ./target/media/<ext> (relative to where you ran the script)
#
# Name collisions are avoided by prefixing the repo folder name.

ROOT_DIR="$(pwd)"
OUT_BASE="${ROOT_DIR}/target/media"

collect_ext() {
    local ext="$1"
    local out_dir="${OUT_BASE}/${ext}"

    mkdir -p "$out_dir"

    find "$ROOT_DIR" -type d -name ".git" -prune -print0 \
    | while IFS= read -r -d '' gitdir; do
        local repo_root repo_name files f base dest
        repo_root="$(dirname "$gitdir")"
        repo_name="$(basename "$repo_root")"

        shopt -s nullglob
        files=("$repo_root"/*."$ext")

        for f in "${files[@]}"; do
            base="$(basename "$f")"
            dest="${out_dir}/${repo_name}__${base}"
            cp -n "$f" "$dest" 2>/dev/null || true
            printf "%s  %s  ->  %s\n" "${ext^^}" "$f" "$dest"
        done

        shopt -u nullglob
    done
}

# If no args given, process mp3 and mp4. Otherwise process provided extensions.
if [ "$#" -eq 0 ]; then
    collect_ext mp3
    collect_ext mp4
else
    for ext in "$@"; do
        collect_ext "$ext"
    done
fi