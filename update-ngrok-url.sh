#!/bin/bash
# Update the ngrok URL across all project files

# Check if a new URL was provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <new-ngrok-url>"
  echo "Example: $0 https://abc123.ngrok-free.app"
  exit 1
fi

NEW_URL=$1
OLD_URL="https://83bc16e00594.ngrok-free.app"

# Validate the new URL
if [[ ! $NEW_URL =~ ^https://.*\.ngrok-free\.app$ ]]; then
  echo "⚠️  Warning: URL '$NEW_URL' doesn't look like a valid ngrok.io URL"
  echo "Expected format: https://abc123.ngrok-free.app"
  
  read -p "Continue anyway? (y/n): " CONTINUE
  if [[ "$CONTINUE" != "y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

echo "=== Updating ngrok URL ==="
echo "Old URL: $OLD_URL"
echo "New URL: $NEW_URL"
echo ""

# Function to update file and report results
update_file() {
  local file=$1
  local old_url=$2
  local new_url=$3
  local count=0
  
  # Make backup
  cp "$file" "${file}.bak"
  
  # Count occurrences before replacement
  count=$(grep -c "$old_url" "$file")
  
  if [ $count -gt 0 ]; then
    # Perform replacement
    sed -i '' "s|$old_url|$new_url|g" "$file"
    echo "✅ Updated $file ($count replacements)"
  else
    echo "ℹ️  No occurrences found in $file"
  fi
}

# Update critical files
update_file "public/history.html" "$OLD_URL" "$NEW_URL"
update_file "public/config.js" "$OLD_URL" "$NEW_URL"
update_file "vercel.json" "$OLD_URL" "$NEW_URL"
update_file "public/error-handler.js" "$OLD_URL" "$NEW_URL"

# Update other files that might contain the URL
echo ""
echo "Checking other files..."

# Find all files containing the old URL
other_files=$(grep -l "$OLD_URL" --include="*.js" --include="*.html" --include="*.md" --include="*.sh" --exclude="*.bak" -r .)

if [ -n "$other_files" ]; then
  echo "Found references in other files:"
  echo "$other_files"
  echo ""
  
  read -p "Update these files too? (y/n): " UPDATE_OTHERS
  if [[ "$UPDATE_OTHERS" == "y" ]]; then
    for file in $other_files; do
      update_file "$file" "$OLD_URL" "$NEW_URL"
    done
  fi
fi

echo ""
echo "=== Update Complete ==="
echo "Remember to restart any servers and redeploy to Vercel!"
echo ""
echo "To test the new URL:"
echo "  curl $NEW_URL/api/cors-test"
echo ""
echo "To restore from backups if needed:"
echo "  find . -name '*.bak' | xargs -I{} bash -c 'cp \"{}\" \"\${0%.bak}\"' {}"
