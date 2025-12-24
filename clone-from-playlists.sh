#!/usr/bin/env bash

set -euo pipefail

prefix="https://github.com/cymatic-productions/mixcraft."
playlist_dir="playlists"
target_dir="target"

force=false
dry_run=false
jobs_max=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [--force] [--dry-run] [-j N|--jobs N]

Options:
  --force        Re-clone repositories even if they already exist (removes existing folder first)
  --dry-run      Show what would be done without performing git clone or rm
  -j, --jobs N   Number of concurrent clones (defaults to CPU count or 4)
  -h, --help     Show this help message
EOF
}

# default jobs: try nproc, fallback to 4
default_jobs() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    else
        echo 4
    fi
}

# parse args
while [[ ${#} -gt 0 ]]; do
    case "$1" in
        --force)
            force=true; shift ;;
        --dry-run)
            dry_run=true; shift ;;
        -j|--jobs)
            shift
            if [[ -z "${1:-}" || "$1" == -* ]]; then
                echo "Error: --jobs requires a numeric argument" >&2; usage; exit 1
            fi
            jobs_max="$1"; shift ;;
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

if [ -z "$jobs_max" ] || [ "$jobs_max" -eq 0 ]; then
    jobs_max=$(default_jobs)
fi

# Ensure jobs_max is a positive integer
if ! [[ "$jobs_max" =~ ^[0-9]+$ ]] || [ "$jobs_max" -le 0 ]; then
    echo "Invalid jobs count: $jobs_max" >&2; exit 1
fi

echo "🚀 Starting project clone from playlist .md files in '$playlist_dir'..."
echo "Concurrency: $jobs_max jobs"
echo ""

# Job management
job_pids=()

# detect wait -n availability (Bash >= 4.3)
have_wait_n=0
if ((BASH_VERSINFO[0] > 4)) || { ((BASH_VERSINFO[0] == 4)) && ((BASH_VERSINFO[1] >= 3)); }; then
    have_wait_n=1
fi

prune_pids() {
    local new=()
    for pid in "${job_pids[@]:-}"; do
        if kill -0 "$pid" 2>/dev/null; then
            new+=("$pid")
        fi
    done
    job_pids=("${new[@]:-}")
}

wait_for_slot() {
    while [ "${#job_pids[@]}" -ge "$jobs_max" ]; do
        if [ "$have_wait_n" -eq 1 ]; then
            wait -n
        else
            # wait for the first PID in the list
            wait "${job_pids[0]}" || true
        fi
        prune_pids
    done
}

# Do the actual clone work inside a function so we can background it
do_clone() {
    local repo_url="$1"
    local song_path="$2"
    local song_clean="$3"

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
            return 0
        fi
    fi

    echo "🔽 Cloning $repo_url into $song_path ..."
    if [ "$dry_run" = true ]; then
        echo " (dry-run) would run: git clone ${repo_url}.git ${song_path}"
    else
        git clone "${repo_url}.git" "$song_path"
    fi
}

mkdir -p "$target_dir"

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

        # Wait for a free slot if needed
        wait_for_slot

        # Start the clone in background
        (
            do_clone "$repo_url" "$song_path" "$song_clean"
        ) &
        job_pids+=($!)
    done <<< "$song_lines"

done

# wait for all remaining background jobs
if [ "${#job_pids[@]}" -gt 0 ]; then
    echo ""
    echo "⏳ Waiting for ${#job_pids[@]} running job(s) to finish..."
    if [ "$have_wait_n" -eq 1 ]; then
        while [ "${#job_pids[@]}" -gt 0 ]; do
            wait -n || true
            prune_pids
        done
    else
        for pid in "${job_pids[@]}"; do
            wait "$pid" || true
        done
    fi
fi

echo ""
echo "✅ Done! All projects cloned into './$target_dir/'"