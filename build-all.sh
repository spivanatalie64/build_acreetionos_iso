#!/usr/bin/env bash
# build-all.sh — non-interactive multi-variant ISO builder
# usage:
#   ./build-all.sh                          # build all variants
#   ./build-all.sh cinnamon gnome plasma    # build specific variants only
#   ./build-all.sh --list                   # list available variants
#   ./build-all.sh --only-unofficial        # build only unofficial variants
#   ./build-all.sh --only-official          # build only official variants
#   ./build-all.sh --parallel               # build variants in parallel (max 2)
#   ./build-all.sh --skip-base              # skip base build
#   ./build-all.sh --skip-test              # skip ISO testing after build

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$SCRIPT_DIR"

# ───────────────────────────────────────────────────────────────────
# OFFICIAL REMOTE BUILDS — cloned from GitHub and built independently
# ───────────────────────────────────────────────────────────────────
declare -A OFFICIAL_REPOS
OFFICIAL_REPOS["cinnamon-x11"]="https://github.com/acreetionos-code/acreetionos.git"
OFFICIAL_REPOS["cinnamon-xlibre"]="https://github.com/acreetionos-code/acreetionos-xlibre.git"

OFFICIAL_BUILD_DIR="$SCRIPT_DIR/../_official_builds"

PARALLEL=false
SKIP_BASE=false
SKIP_TEST=false
SKIP_OFFICIAL=false
FILTER_TIER=""
BUILD_LIST=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --parallel) PARALLEL=true; shift ;;
        --skip-base) SKIP_BASE=true; shift ;;
        --skip-test) SKIP_TEST=true; shift ;;
        --skip-official) SKIP_OFFICIAL=true; shift ;;
        --only-official) FILTER_TIER="official"; shift ;;
        --only-unofficial) FILTER_TIER="unofficial"; shift ;;
        --list)
            echo "=== official remote builds (cloned from GitHub) ==="
            for name in "${!OFFICIAL_REPOS[@]}"; do
                echo "  $name  (${OFFICIAL_REPOS[$name]})"
            done
            echo ""
            echo "=== official local variants ==="
            find variants/official -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|variants/official/||' || echo "  (none)"
            echo ""
            echo "=== unofficial variants ==="
            find variants/unofficial -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|variants/unofficial/||' || echo "  (none)"
            exit 0
            ;;
        -h|--help)
            echo "usage: ./build-all.sh [options] [variant1 variant2 ...]"
            echo ""
            echo "options:"
            echo "  --list              list available variants"
            echo "  --skip-base         skip base build"
            echo "  --skip-test         skip ISO testing after build"
            echo "  --skip-official     skip official remote builds (cinnamon-x11, cinnamon-xlibre)"
            echo "  --only-official     build only official variants"
            echo "  --only-unofficial   build only unofficial variants"
            echo "  --parallel          build variants in parallel (max 2)"
            echo "  -h, --help          show this help"
            echo ""
            echo "examples:"
            echo "  ./build-all.sh                     # build base + all variants"
            echo "  ./build-all.sh cinnamon gnome       # build specific variants"
            echo "  ./build-all.sh --only-unofficial    # build all unofficial"
            echo "  ./build-all.sh --skip-base           # variants only"
            exit 0
            ;;
        -*)
            echo "unknown option: $1"
            echo "use --help for usage"
            exit 1
            ;;
        *)
            BUILD_LIST+=("$1")
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$SCRIPT_DIR"

detect_variants() {
    local tier="$1"
    find "variants/$tier" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
        basename "$dir"
    done
}

if [ ${#BUILD_LIST[@]} -eq 0 ]; then
    if [ -z "$FILTER_TIER" ] || [ "$FILTER_TIER" = "unofficial" ]; then
        while IFS= read -r v; do
            BUILD_LIST+=("$v")
        done < <(detect_variants "unofficial")
    fi
    if [ -z "$FILTER_TIER" ] || [ "$FILTER_TIER" = "official" ]; then
        while IFS= read -r v; do
            BUILD_LIST+=("$v")
        done < <(detect_variants "official")
    fi
fi

RESULTS=()
FAILED=()

build_variant() {
    local variant="$1"
    local tier="$2"
    local logfile="build-${variant}.log"

    echo "=== [$(date '+%H:%M:%S')] Building: $variant ($tier) ===" | tee -a "$logfile"

    if ./build.sh "$variant" "$tier" >> "$logfile" 2>&1; then
        echo "  PASS: $variant" | tee -a "$logfile"
        RESULTS+=("PASS:$variant")
    else
        echo "  FAIL: $variant" | tee -a "$logfile"
        RESULTS+=("FAIL:$variant")
    fi
}

build_base() {
    local logfile="build-base.log"
    echo "=== [$(date '+%H:%M:%S')] Building: base ===" | tee -a "$logfile"

    if ./build.sh >> "$logfile" 2>&1; then
        echo "  PASS: base" | tee -a "$logfile"
        RESULTS+=("PASS:base")
    else
        echo "  FAIL: base" | tee -a "$logfile"
        RESULTS+=("FAIL:base")
    fi
}

build_official_remote() {
    local name="$1"
    local repo_url="$2"
    local logfile="build-${name}.log"
    local clone_dir="$OFFICIAL_BUILD_DIR/$name"

    echo "=== [$(date '+%H:%M:%S')] Building official remote: $name ===" | tee -a "$logfile"

    if [ -d "$clone_dir" ]; then
        echo "  pulling latest from $repo_url ..." | tee -a "$logfile"
        git -C "$clone_dir" pull --ff-only >> "$logfile" 2>&1 || {
            echo "  git pull failed, re-cloning..." | tee -a "$logfile"
            rm -rf "$clone_dir"
            git clone "$repo_url" "$clone_dir" >> "$logfile" 2>&1
        }
    else
        echo "  cloning $repo_url ..." | tee -a "$logfile"
        git clone "$repo_url" "$clone_dir" >> "$logfile" 2>&1
    fi

    if [ ! -d "$clone_dir" ]; then
        echo "  FAIL: $name (clone failed)" | tee -a "$logfile"
        RESULTS+=("FAIL:$name")
        return 1
    fi

    echo "  building $name from $clone_dir ..." | tee -a "$logfile"
    cd "$clone_dir"

    if [ -f build.sh ]; then
        if ./build.sh >> "$logfile" 2>&1; then
            echo "  PASS: $name" | tee -a "$logfile"
            RESULTS+=("PASS:$name")
        else
            echo "  FAIL: $name" | tee -a "$logfile"
            RESULTS+=("FAIL:$name")
        fi
    elif [ -f Makefile ]; then
        if make build-base >> "$logfile" 2>&1; then
            echo "  PASS: $name" | tee -a "$logfile"
            RESULTS+=("PASS:$name")
        else
            echo "  FAIL: $name" | tee -a "$logfile"
            RESULTS+=("FAIL:$name")
        fi
    else
        echo "  FAIL: $name (no build.sh or Makefile found)" | tee -a "$logfile"
        RESULTS+=("FAIL:$name")
    fi

    cd "$SCRIPT_DIR"
}

if ! $SKIP_BASE; then
    build_base
fi

for variant in "${BUILD_LIST[@]}"; do
    tier="unofficial"
    if [ -d "variants/official/$variant" ]; then
        tier="official"
    fi
    build_variant "$variant" "$tier"
done

# build official remote repos (cinnamon-x11, cinnamon-xlibre)
if ! $SKIP_OFFICIAL && ( [ -z "$FILTER_TIER" ] || [ "$FILTER_TIER" = "official" ] ); then
    for name in "${!OFFICIAL_REPOS[@]}"; do
        build_official_remote "$name" "${OFFICIAL_REPOS[$name]}"
    done
fi
echo "=========================================="
for r in "${RESULTS[@]}"; do
    status="${r%%:*}"
    name="${r#*:}"
    if [ "$status" = "PASS" ]; then
        echo "  [PASS] $name"
    else
        echo "  [FAIL] $name"
    fi
done
echo "=========================================="

FAIL_COUNT=0
for r in "${RESULTS[@]}"; do
    if [[ "$r" == FAIL:* ]]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

if [ $FAIL_COUNT -gt 0 ]; then
    echo "  $FAIL_COUNT build(s) FAILED"
    exit 1
fi

if ! $SKIP_TEST; then
    echo ""
    echo "=== Running ISO tests ==="
    for r in "${RESULTS[@]}"; do
        if [[ "$r" == PASS:* ]]; then
            name="${r#PASS:}"
            ./test-iso.sh "$name" || true
        fi
    done
fi

echo ""
echo "All builds complete."
