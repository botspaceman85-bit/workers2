#!/usr/bin/env bash
set -euo pipefail
SRC="${1:?source dir required}"
DEST="${2:?destination dir required}"
rm -rf "$DEST"
mkdir -p "$DEST"

# Remove macOS metadata and Git internals.
find "$SRC" -type f \
  ! -path '*/__MACOSX/*' \
  ! -name '.DS_Store' \
  ! -path '*/.git/*' \
  -print0 | while IFS= read -r -d '' f; do
    rel="${f#"$SRC"/}"
    mkdir -p "$DEST/$(dirname "$rel")"
    cp -p "$f" "$DEST/$rel"
  done

# If the ZIP had one wrapper directory, flatten it.
if [ ! -f "$DEST/pubspec.yaml" ]; then
  candidates=()
  while IFS= read -r -d '' f; do
    rel="${f#"$DEST"/}"
    first="${rel%%/*}"
    [ "$first" != "$rel" ] && candidates+=("$first")
  done < <(find "$DEST" -type f -print0)

  uniq="$(printf '%s\n' "${candidates[@]:-}" | sort -u | sed '/^$/d')"
  if [ "$(printf '%s\n' "$uniq" | wc -l)" = "1" ]; then
    root="$(printf '%s\n' "$uniq")"
    if [ -f "$DEST/$root/pubspec.yaml" ]; then
      tmp="${DEST}.flat"
      mkdir -p "$tmp"
      cp -a "$DEST/$root/." "$tmp/"
      rm -rf "$DEST"
      mv "$tmp" "$DEST"
    fi
  fi
fi

test -f "$DEST/pubspec.yaml" || {
  echo "pubspec.yaml tidak ditemukan setelah ekstraksi."
  find "$DEST" -maxdepth 3 -type f | head -100
  exit 1
}
