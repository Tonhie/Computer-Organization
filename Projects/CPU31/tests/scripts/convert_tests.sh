#!/bin/bash

# Convert test .txt files to .hex using MARS 4.5
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$(dirname "$TEST_DIR")"
ASM_DIR="$TEST_DIR/asm"
HEX_DIR="$TEST_DIR/hex"
MARS_JAR="$PROJECT/Mars4_5.jar"

mkdir -p "$HEX_DIR"

for txt in "$ASM_DIR"/*.txt; do
    [ -e "$txt" ] || continue

    filename=$(basename "$txt" .txt)
    # Strip prefix like _1_, _2_, _3.5_, _4_
    base=$(echo "$filename" | sed 's/^_[0-9.]*_//')

    echo "Converting $filename -> $base.hex"
    java -jar "$MARS_JAR" nc a dump .text HexText "$HEX_DIR/$base.hex" "$txt"
done

echo "Done. $(ls "$HEX_DIR"/*.hex 2>/dev/null | wc -l) hex files generated in $HEX_DIR"
