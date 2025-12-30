#!/usr/bin/env bash

################################################################################
# Go Lesson File Structure Script
#
# Purpose:
#   I want to avoid adding files by hand. And when I'm learning a bunch of
#   topics, separating them out is good.
#
# Philosophy:
#   - Robustness
#   - Fail fast
#   - Never overwrite previous work
#   - Print every meaningful action
#   - Future-me should not have to reverse-engineer anything, I don't trust him.
################################################################################

# ======================================
# Safety switches
# ====================================== 
# -e : exit immediately on command failure
# -u : error on unset variables
# -o pipefail : fail if any part of a pipeline fails
set -euo pipefail

# ---------------⇓---------------
# Bash not sh needed to run.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "Error: This is a __bash__ script, please use bash, or chmod +x and direct execution."
  exit 1
fi
# ---------------⇑---------------

# ====================================== 
# Script name, used in printing
# ====================================== 
SCRIPT_NAME="$(basename "$0")"

# ====================================== 
# Helper: print usage
# ====================================== 
usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME course <Name> <NumChapters>
  $SCRIPT_NAME add    <Course> <ChapterNum> <LessonNum>
EOF
  exit "${1:-1}"
}

# ---------------⇓---------------
# Help flag
case "${1:-}" in
  -h|--help)
    usage 0
    ;;
esac
# ---------------⇑---------------

# ====================================== 
# Go environment checks
# ====================================== 

# ---------------⇓---------------
# Ensure Go exists
command -v go >/dev/null || {
  echo "Error: Go is not installed"
  exit 1
}
# ---------------⇑---------------

# ---------------⇓---------------
#  Set go to current version
GO_VERSION="$(go env GOVERSION | sed 's/^go//')"
# ---------------⇑---------------

# ---------------⇓---------------
# Use go to check where the directory should be
GOMOD_PATH="$(go env GOMOD)"

if [[ "$GOMOD_PATH" == "/dev/null" ]]; then
  echo "Error: not inside a Go module

  try `go mod init` to setup"
  exit 1
fi

ROOT="$(dirname "$GOMOD_PATH")"
# ---------------⇑---------------


# ====================================== 
# Helper functions
# ====================================== 

# ---------------⇓---------------
# Pads an int to 2 digits (e.g. 05)
pad2() {
  printf "%02d" "$1"
}
# ---------------⇑---------------

# ---------------⇓---------------
# Prints info while running
info() {
  echo "[INFO] $*"
}
# ---------------⇑---------------

# ---------------⇓---------------
# Prints to stderr, allows for logging
warn() {
  echo "[WARN] $*" >&2
}
# ---------------⇑---------------

# ====================================== 
# Parse the command `course` vs `add`
# ====================================== 
COMMAND="${1:-}"
[[ -z "$COMMAND" ]] && usage 1
shift

################################################################################
# COURSE COMMAND
# Here we're making a course directory
################################################################################

if [[ "$COMMAND" == "course" ]]; then
  [[ $# -eq 2 ]] || usage 1

  COURSE_NAME="$1"
  NUM_CHAPTERS="$2"

# ---------------⇓---------------
  # Validate chapter count
  if ! [[ "$NUM_CHAPTERS" =~ ^[0-9]+$ ]] || [[ "$NUM_CHAPTERS" -le 0 ]]; then
    echo "Chapter count must be a positive integer."
    exit 1
  fi
# ---------------⇑---------------

  info "Creating course folder '$COURSE_NAME'"

  COURSE_DIR="$ROOT/$COURSE_NAME"

# ---------------⇓---------------
  # Create module directory if missing
  if [[ -d "$COURSE_DIR" ]]; then
    warn "Course directory already exists: $COURSE_NAME"
  else
    mkdir -p "$COURSE_DIR"
    info "Created course directory $COURSE_NAME"
  fi
# ---------------⇑---------------

# ---------------⇓---------------
  # Create chapter directories
  for ((i=1; i<=NUM_CHAPTERS; i++)); do
    CHAPTER_DIR="$COURSE_DIR/$(pad2 "$i")"
    mkdir -p "$CHAPTER_DIR"
    info "Ensured chapter directory: $(basename "$CHAPTER_DIR")"
  done
# ---------------⇑---------------

  info "Chapter setup complete."
  exit 0
fi
# ---------------⇑---------------

################################################################################
# ADD COMMAND
# Here we add an individual lesson
################################################################################
if [[ "$COMMAND" == "add" ]]; then
  [[ $# -eq 3 ]] || usage 1

  COURSE_NAME="$1"
  CHAPTER_NUM="$2"
  LESSON_NUM="$3"

# ---------------⇓---------------
  # Validate numeric inputs
  for v in "$CHAPTER_NUM" "$LESSON_NUM"; do
    if ! [[ "$v" =~ ^[0-9]+$ ]] || [[ "$v" -le 0 ]]; then
      echo "Chapter and lesson numbers must be positive integers."
      exit 1
    fi
  done
# ---------------⇑---------------

# ---------------⇓---------------
# Constants
  PADDED_CHAPTER="$(pad2 "$CHAPTER_NUM")"
  PADDED_LESSON="$(pad2 "$LESSON_NUM")"

  COURSE_DIR="$ROOT/$COURSE_NAME"
  CHAPTER_DIR="$COURSE_DIR/$PADDED_CHAPTER"
  LESSON_DIR="$CHAPTER_DIR/$PADDED_LESSON"
# ---------------⇑---------------

# ---------------⇓---------------
  # Safeguards
  [[ -d "$COURSE_DIR" ]] || { echo "Course not found."; exit 1; }
  [[ -d "$CHAPTER_DIR" ]] || { echo "Chapter not found."; exit 1; }

  info "Adding lesson $PADDED_LESSON to $COURSE_NAME chapter $PADDED_CHAPTER"

  if [[ -d "$LESSON_DIR" ]]; then
    warn "Lesson directory already exists, ensuring files (non-destructive)"; 
  else
    mkdir -p "$LESSON_DIR"
    info "Made lesson directory $LESSON_NUM"
  fi


# ---------------⇑---------------

# ---------------⇓---------------
  # Names for things
  PACKAGE_NAME="ch${PADDED_CHAPTER}ls${PADDED_LESSON}"
  TEST_NAME="TestCh${PADDED_CHAPTER}Ls${PADDED_LESSON}"

  GO_FILE="$LESSON_DIR/lesson${PADDED_LESSON}.go"
  TEST_FILE="$LESSON_DIR/lesson${PADDED_LESSON}_test.go"
  MD_FILE="$LESSON_DIR/lesson${PADDED_LESSON}.md"
# ---------------⇑---------------

# ---------------⇓---------------
  # Create Go file
  if [[ -f "$GO_FILE" ]]; then
    warn "Lesson file already exists, skipping"
  else
    cat >"$GO_FILE" <<EOF
package $PACKAGE_NAME

func Placeholder() {
    // TODO: implement lesson $PADDED_LESSON
}
EOF
    info "Created $GO_FILE"
  fi
# ---------------⇑---------------

# ---------------⇓---------------
  # Create test file
  if [[ -f "$TEST_FILE" ]]; then
    warn "Test file already exists, skipping"
  else
    cat >"$TEST_FILE" <<EOF
package $PACKAGE_NAME

import "testing"

func $TEST_NAME(t *testing.T) {
    // TODO: write tests
}
EOF
    info "Created $TEST_FILE"
  fi
# ---------------⇑---------------

# ---------------⇓---------------
  # Create markdown
  if [[ -f "$MD_FILE" ]]; then
    warn "Markdown file already exists, skipping"
  else
    echo "# $COURSE_NAME
## Chapter $CHAPTER_NUM, Lesson $PADDED_LESSON" >"$MD_FILE"
    info "Created $MD_FILE"
  fi
# ---------------⇑---------------

  info "Lesson added successfully."
  exit 0
fi
# ---------------⇑---------------

################################################################################
# FALLBACK COMMAND
# This is called if all else fails.
################################################################################
usage 1
