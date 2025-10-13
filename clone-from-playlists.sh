#!/usr/bin/env bash

set -euo pipefail

prefix="https://github.com/cymatic-productions/mixcraft."
playlist_dir="playlists"
target_dir="target"

force=false
dry_run=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [--force] [--dry-run]

Options:
  --force     Re-clone repositories even if they already exist (removes existing folder first)
  --dry-run   Show what would be done without performing git clone or rm
  -h, --help  Show this help message
EOF
}

while [[ ${#} -gt 0 ]]; do
    case "$1" in
        --force)
            force=true; shift ;;
        --dry-run)
            dry_run=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        --)
            shift; break ;;
        -*)
            echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *)
            break ;;
    esac
done

mkdir -p "$target_dir"
echo "🚀 Starting project clone from playlist .md files in '$playlist_dir'..."

# Loop through all .md files in the playlists folder
for md_file in "$playlist_dir"/*.md; do
    category=$(basename "$md_file" .md)
    echo ""
    echo "📂 Processing category: $category"

    category_path="$target_dir/$category"
    mkdir -p "$category_path"

    # Extract song list using grep/sed/awk (assumes YAML-style 'songs: [ ... ]' format)
    # Collect lines between 'songs: [' and closing ']'
    song_lines=$(awk '/songs:\s*\[/{flag=1; next} /\]/{flag=0} flag' "$md_file" | sed 's/[\",]//g' | sed 's/#.*//g' | tr -d ' ')

    # Process each song line
    while IFS= read -r song; do
        [[ -z "$song" ]] && continue
        song_clean=$(echo "$song" | sed 's/[[:space:],]*$//')

        repo_url="${prefix}${song_clean}"
        song_path="$category_path/$song_clean"

        if [ -d "$song_path/.git" ]; then
            if [ "$force" = true ]; then
                echo "🔁 Force re-clone requested for: $song_clean"
                if [ "$dry_run" = true ]; then
                    echo " (dry-run) would remove: $song_path"
                else
                    echo "Removing existing folder: $song_path"
                    rm -rf "$song_path"
                fi
            else
                echo "⚠️  Already cloned: $song_clean — skipping"
                continue
            fi
        fi

        echo "🔽 Cloning $repo_url into $song_path ..."
        if [ "$dry_run" = true ]; then
            echo " (dry-run) would run: git clone ${repo_url}.git ${song_path}"
        else
            git clone "${repo_url}.git" "$song_path"
        fi
    done <<< "$song_lines"

done

echo ""
echo "✅ Done! All projects cloned into './$target_dir/'"
