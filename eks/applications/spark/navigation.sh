#!/bin/bash

REPOS=(
  "data-lab/spark|/home/roberto/Github/data-lab/eks/applications/spark/"
  "data-lake|/home/roberto/Github/data-lake/"
  "spark/docker|/home/roberto/Github/spark/docker/"
)

echo ""
echo "=== Repo Navigation ==="
for i in "${!REPOS[@]}"; do
  IFS='|' read -r name path <<< "${REPOS[$i]}"
  echo "  $((i+1))) $name  - $path"
done
echo "  0) Cancel"
echo ""

read -rp "Select: " choice
[[ "$choice" == "0" || -z "$choice" ]] && exit 0

idx=$((choice-1))
if [[ $idx -ge 0 && $idx -lt ${#REPOS[@]} ]]; then
  IFS='|' read -r _ dest <<< "${REPOS[$idx]}"
  echo "→ $dest"
  cd "$dest" && exec bash
else
  echo "Invalid option."
fi
