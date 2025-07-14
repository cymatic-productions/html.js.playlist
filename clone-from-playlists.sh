#!/bin/bash

prefix="https://github.com/cymatic-productions/mixcraft."
playlist_dir="playlists"
target_dir="target"

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
    song_lines=$(awk '/songs:\s*\[/{flag=1; next} /\]/{flag=0} flag' "$md_file" | sed 's/[",]//g' | sed 's/#.*//g' | tr -d ' ')

    # Process each song line
    while IFS= read -r song; do
        [[ -z "$song" ]] && continue
        song_clean=$(echo "$song" | sed 's/[[:space:],]*$//')

        repo_url="${prefix}${song_clean}"
        song_path="$category_path/$song_clean"

        if [ -d "$song_path/.git" ]; then
            echo "⚠️  Already cloned: $song_clean"
            continue
        fi

        echo "🔽 Cloning $repo_url into $song_path ..."
        git clone "$repo_url".git "$song_path"
    done <<< "$song_lines"

done

echo ""
echo "✅ Done! All projects cloned into './$target_dir/'"
