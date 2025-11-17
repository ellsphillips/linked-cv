#!/bin/bash
#
# Version Consistency Checker for linked-cv (Bash version)
#
# This script ensures all package references in documentation and examples
# match the version specified in typst.toml (source of truth).
#
# Usage:
#   ./scripts/check_version.sh          # Check only
#   ./scripts/check_version.sh --update # Fix mismatches
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

UPDATE_MODE=0

# Parse arguments
if [ "$1" = "--update" ]; then
  UPDATE_MODE=1
  MODE_STR="UPDATE MODE"
else
  MODE_STR="CHECK MODE"
fi

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "========================================================================"
echo "Linked-CV Version Consistency Checker ($MODE_STR)"
echo "========================================================================"
echo ""

# Extract version from typst.toml (source of truth)
SOURCE_VERSION=$(grep '^version = ' typst.toml | sed 's/version = "\(.*\)"/\1/')

if [ -z "$SOURCE_VERSION" ]; then
  echo -e "${RED}❌ Error: Could not extract version from typst.toml${NC}"
  exit 1
fi

PACKAGE_NAME=$(grep '^name = ' typst.toml | sed 's/name = "\(.*\)"/\1/')

echo -e "${GREEN}✓${NC} Source of truth: $PACKAGE_NAME v$SOURCE_VERSION"
echo "  (from typst.toml)"
echo ""

# Files to check
FILES_TO_CHECK=(
  "README.md"
  "example/cv.typ"
)

# Add any .typ files in root
for file in *.typ; do
  if [ -f "$file" ]; then
    FILES_TO_CHECK+=("$file")
  fi
done

ERRORS=0
FILES_UPDATED=()

# Check each file
for file in "${FILES_TO_CHECK[@]}"; do
  if [ ! -f "$file" ]; then
    continue
  fi

  # Find all version references in the format @preview/linked-cv:X.X.X
  # Use sed for portability (works on both BSD and GNU)
  FOUND_VERSIONS=$(grep -o "@preview/$PACKAGE_NAME:[0-9]\+\.[0-9]\+\.[0-9]\+" "$file" 2>/dev/null | sed "s/@preview\/$PACKAGE_NAME://" || true)

  if [ -z "$FOUND_VERSIONS" ]; then
    continue
  fi

  HAS_MISMATCH=0
  MISMATCH_INFO=""

  # Check for mismatches
  while IFS= read -r version; do
    if [ "$version" != "$SOURCE_VERSION" ]; then
      HAS_MISMATCH=1
      LINE_NUM=$(grep -n "@preview/$PACKAGE_NAME:$version" "$file" | cut -d: -f1 | head -1)
      MISMATCH_INFO+="    Line $LINE_NUM: $version → $SOURCE_VERSION"$'\n'
    fi
  done <<< "$FOUND_VERSIONS"

  if [ $HAS_MISMATCH -eq 1 ]; then
    if [ $UPDATE_MODE -eq 1 ]; then
      # Update mode: fix the file
      # Use sed to replace all version references
      sed -i.bak -E "s|(@preview/$PACKAGE_NAME:)[0-9]+\.[0-9]+\.[0-9]+|\1$SOURCE_VERSION|g" "$file"
      rm -f "$file.bak"

      echo -e "✏  Updated $file"
      echo "$MISMATCH_INFO"
      FILES_UPDATED+=("$file")
    else
      # Check mode: report the error
      echo -e "${RED}❌ $file${NC}"
      echo "$MISMATCH_INFO"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${GREEN}✓${NC} $file"
  fi
done

echo ""
echo "========================================================================"

if [ $UPDATE_MODE -eq 1 ]; then
  if [ ${#FILES_UPDATED[@]} -gt 0 ]; then
    echo "VERSION UPDATE COMPLETE"
    echo "========================================================================"
    echo -e "${GREEN}✓${NC} Updated ${#FILES_UPDATED[@]} file(s) to version $SOURCE_VERSION"
    echo ""
    echo "Files updated:"
    for file in "${FILES_UPDATED[@]}"; do
      echo "  - $file"
    done
    exit 0
  else
    echo "VERSION UPDATE - NO CHANGES NEEDED"
    echo "========================================================================"
    echo -e "${GREEN}✓${NC} All package references already match version $SOURCE_VERSION"
    exit 0
  fi
else
  if [ $ERRORS -gt 0 ]; then
    echo "VERSION CONSISTENCY CHECK FAILED"
    echo "========================================================================"
    echo ""
    echo "Expected version: $SOURCE_VERSION"
    echo "Source of truth: typst.toml"
    echo ""
    echo "To automatically fix these issues, run:"
    echo "  ./scripts/check_version.sh --update"
    exit 1
  else
    echo "VERSION CONSISTENCY CHECK PASSED"
    echo "========================================================================"
    echo -e "${GREEN}✓${NC} All package references match version $SOURCE_VERSION"
    exit 0
  fi
fi
