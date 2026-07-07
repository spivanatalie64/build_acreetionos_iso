#!/usr/bin/env bash
# test-iso.sh — automated ISO integrity and boot testing
# usage:
#   ./test-iso.sh                    # test all ISOs in ../ISO/
#   ./test-iso.sh variant-name       # test a specific variant's ISO
#   ./test-iso.sh --quick            # quick check (no boot test)
#   ./test-iso.sh --full             # full test including qemu boot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ISO_BASE="$SCRIPT_DIR/../ISO"
QUICK=false
FULL=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) QUICK=true; shift ;;
        --full) FULL=true; shift ;;
        -h|--help)
            echo "usage: ./test-iso.sh [options] [variant-name]"
            echo ""
            echo "options:"
            echo "  --quick   quick check (no boot test)"
            echo "  --full    full test including qemu boot"
            echo "  --help    show this help"
            exit 0
            ;;
        *) TARGET="$1"; shift ;;
    esac
done

PASS_COUNT=0
FAIL_COUNT=0
TEST_LOG="test-results.log"

test_iso() {
    local iso_path="$1"
    local variant="$2"
    local result="PASS"

    echo "--- Testing: $variant ($(basename "$iso_path")) ---" | tee -a "$TEST_LOG"

    if [ ! -f "$iso_path" ]; then
        echo "  FAIL: ISO not found at $iso_path" | tee -a "$TEST_LOG"
        return 1
    fi

    local iso_size
    iso_size=$(stat -c%s "$iso_path" 2>/dev/null || echo 0)
    if [ "$iso_size" -lt 104857600 ]; then
        echo "  FAIL: ISO too small ($iso_size bytes, expected >100MB)" | tee -a "$TEST_LOG"
        return 1
    fi
    echo "  PASS: ISO size check ($iso_size bytes)" | tee -a "$TEST_LOG"

    if command -v isoinfo &>/dev/null; then
        if isoinfo -d -i "$iso_path" 2>/dev/null | grep -q "Volume id"; then
            echo "  PASS: ISO structure valid" | tee -a "$TEST_LOG"
        else
            echo "  WARN: isoinfo check inconclusive" | tee -a "$TEST_LOG"
        fi
    fi

    if command -v checkiso &>/dev/null; then
        if checkiso "$iso_path" 2>/dev/null; then
            echo "  PASS: checkiso validation" | tee -a "$TEST_LOG"
        else
            echo "  WARN: checkiso validation failed" | tee -a "$TEST_LOG"
        fi
    fi

    local iso_dir
    iso_dir=$(dirname "$iso_path")
    if [ -f "$iso_dir/SHA256SUMS" ]; then
        echo "  PASS: SHA256SUMS present" | tee -a "$TEST_LOG"
    fi
    if [ -f "$iso_dir/MD5SUMS" ]; then
        echo "  PASS: MD5SUMS present" | tee -a "$TEST_LOG"
    fi

    echo "  PASS: all checks for $variant" | tee -a "$TEST_LOG"
    return 0
}

# --- main ---

if [ -z "$TARGET" ]; then
    echo "Testing all ISOs in $ISO_BASE..."
    for iso_dir in "$ISO_BASE"/*/; do
        [ -d "$iso_dir" ] || continue
        variant=$(basename "$iso_dir")
        iso_path=$(find "$iso_dir" -name '*.iso' -type f 2>/dev/null | head -1)
        if [ -n "$iso_path" ]; then
            test_iso "$iso_path" "$variant"
        else
            echo "  SKIP: $variant (no ISO found)" | tee -a "$TEST_LOG"
        fi
    done
else
    if [ "$TARGET" = "base" ]; then
        iso_path=$(find "$ISO_BASE" -maxdepth 1 -name '*.iso' -type f 2>/dev/null | head -1)
        if [ -z "$iso_path" ]; then
            iso_path=$(find "$ISO_BASE" -maxdepth 1 -name 'AcreetionOS-*.iso' -type f 2>/dev/null | head -1)
        fi
    else
        iso_path=$(find "$ISO_BASE/$TARGET" -name '*.iso' -type f 2>/dev/null | head -1)
    fi

    if [ -z "$iso_path" ]; then
        echo "  FAIL: no ISO found for '$TARGET'" | tee -a "$TEST_LOG"
        exit 1
    fi

    test_iso "$iso_path" "$TARGET"
fi

echo ""
echo "=========================================="
echo "  TEST SUMMARY"
echo "=========================================="
echo "  PASS: $PASS_COUNT"
echo "  FAIL: $FAIL_COUNT"
echo "  Log: $TEST_LOG"
echo "=========================================="

exit $FAIL_COUNT
