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
    local ignore_raw="${2:-}"
    local out_dir="${OUT_BASE}/${ext}"

    mkdir -p "$out_dir"

    # portable file size helper: tries GNU stat, BSD stat, falls back to wc -c
    file_size() {
        local file="$1"
        if stat --version >/dev/null 2>&1; then
            stat -c%s "$file"
        elif stat -f%z "$file" >/dev/null 2>&1; then
            stat -f%z "$file"
        else
            wc -c <"$file" | awk '{print $1}'
        fi
    }

    find "$ROOT_DIR" -type d -name ".git" -prune -print0 \
    | while IFS= read -r -d '' gitdir; do
        local repo_root repo_name files f base dest
        repo_root="$(dirname "$gitdir")"
        repo_name="$(basename "$repo_root")"

        shopt -s nullglob
        files=("$repo_root"/*."$ext")

        for f in "${files[@]}"; do
            base="$(basename "$f")"
            base_no_ext="${base%.*}"

            # sanitize: lowercase, replace non-alphanum runs with '-', trim
            clean_repo="$(echo "${repo_name,,}" | sed 's/[^a-z0-9]+/-/g' | sed 's/^-*//; s/-*$//')"
            clean_base="$(echo "${base_no_ext,,}" | sed 's/[^a-z0-9]+/-/g' | sed 's/^-*//; s/-*$//')"
            # prepare sanitized ignore name (if provided)
            clean_ignore=""
            if [ -n "$ignore_raw" ]; then
                clean_ignore="$(echo "${ignore_raw,,}" | sed 's/[^a-z0-9]+/-/g' | sed 's/^-*//; s/-*$//')"
            fi

            # fallbacks if sanitization removed everything
            [ -z "$clean_repo" ] && clean_repo="repo"
            [ -z "$clean_base" ] && clean_base="$ext"

            # If an ignore name was provided, skip files that match (raw or sanitized)
            if [ -n "$ignore_raw" ]; then
                lc_base_no_ext="${base_no_ext,,}"
                lc_ignore_raw="${ignore_raw,,}"
                if [[ "$lc_base_no_ext" == "$lc_ignore_raw" ]] || { [ -n "$clean_ignore" ] && [ "$clean_base" == "$clean_ignore" ]; }; then
                    printf "SKIP  (ignored name) %s  %s\n" "${ext^^}" "$f"
                    continue
                fi
            fi

            # avoid redundant "repo-foo" when base already begins with repo name
            if [[ "$clean_base" == "$clean_repo"* ]]; then
                stripped="${clean_base#"$clean_repo"}"
                stripped="${stripped#-}"
                final_name="${stripped:-$clean_repo}"
                dest_name="${final_name}.${ext}"
            else
                dest_name="${clean_repo}-${clean_base}.${ext}"
            fi

            dest="${out_dir}/${dest_name}"

            # If dest exists, compare sizes and decide whether to overwrite or skip.
            if [ -e "$dest" ]; then
                src_size=$(file_size "$f" 2>/dev/null || echo 0)
                dest_size=$(file_size "$dest" 2>/dev/null || echo 0)

                if [ "$dest_size" -gt "$src_size" ]; then
                    printf "SKIP  (existing larger) %s  %s  ->  %s (existing: %s bytes > src: %s bytes)\n" "${ext^^}" "$f" "$dest" "$dest_size" "$src_size"
                    continue
                elif [ "$src_size" -gt "$dest_size" ]; then
                    cp -f "$f" "$dest" 2>/dev/null || true
                    printf "REPLACE %s  %s  ->  %s (src: %s bytes > existing: %s bytes)\n" "${ext^^}" "$f" "$dest" "$src_size" "$dest_size"
                    continue
                else
                    printf "SKIP  (same size) %s  %s  ->  %s (both: %s bytes)\n" "${ext^^}" "$f" "$dest" "$src_size"
                    continue
                fi
            fi

            # if dest doesn't exist, ensure uniqueness (avoid accidental overwrite)
            if [ -e "$dest" ]; then
                # shouldn't happen due to previous branch, but keep uniqueness fallback
                i=1
                while [ -e "${out_dir}/${dest_name%.*}-$i.${ext}" ]; do
                    i=$((i+1))
                done
                dest="${out_dir}/${dest_name%.*}-$i.${ext}"
            fi

            cp -n "$f" "$dest" 2>/dev/null || true
            printf "COPY  %s  %s  ->  %s\n" "${ext^^}" "$f" "$dest"
        done

        shopt -u nullglob
    done
}

# If no args given, process mp3 and mp4. Otherwise process provided extensions.
if [ "$#" -eq 0 ]; then
    collect_ext amv
    collect_ext mp3 track-render
    collect_ext mp4
else
    for ext in "$@"; do
        collect_ext "$ext"
    done
fi