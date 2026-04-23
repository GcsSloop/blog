#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prefer Homebrew Ruby (x86_64) over system Ruby (broken FFI on Apple Silicon)
if [ -f "/usr/local/opt/ruby/bin/ruby" ]; then
    export PATH="/usr/local/opt/ruby/bin:$PATH"
    export GEM_HOME="$HOME/.gem/ruby"
    export PATH="$GEM_HOME/bin:$PATH"
fi

echo "=== Building Jekyll site ==="
cd "$SCRIPT_DIR"

if command -v bundle &>/dev/null && [ -f "Gemfile" ]; then
    echo "Running: bundle install"
    bundle install --quiet 2>/dev/null || bundle install
    BUILD_CMD="bundle exec jekyll"
else
    BUILD_CMD="jekyll"
fi

JEKYLL_VERSION=$($BUILD_CMD --version 2>/dev/null | awk '{print $2}' || echo "unknown")
echo "Jekyll version: $JEKYLL_VERSION"

echo "Running: $BUILD_CMD build"
$BUILD_CMD build

echo "Build complete: _site/"
ls -la _site/ | head -20
