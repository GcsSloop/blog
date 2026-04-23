#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Load .env file (only if env vars not already set) ---
if [ -f ".env" ]; then
    while IFS='=' read -r key value || [ -n "$key" ]; do
        [[ -z "$key" || "$key" =~ ^\s*# ]] && continue
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^"//;s/"$//;s/^'\''//;s/'\''$//')
        var_name=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        if [ -z "${!var_name}" ]; then
            export "$var_name=$value"
        fi
    done < .env
fi

# --- Map env vars to ossutil format ---
OSS_BUCKET="${BUCKET:-${OSS_BUCKET:-}}"
OSS_ENDPOINT="${ENDPOINT:-${OSS_ENDPOINT:-${OSS_URL:-}}}"
OSS_ACCESS_KEY_ID="${ACCESSKEYID:-${OSS_ACCESS_KEY_ID:-${ALIBABA_CLOUD_ACCESS_KEY_ID:-}}}"
OSS_ACCESS_KEY_SECRET="${ACCESSKEYSECRET:-${OSS_ACCESS_KEY_SECRET:-${ALIBABA_CLOUD_ACCESS_KEY_SECRET:-}}}"

# --- Validate ---
if [ -z "$OSS_BUCKET" ]; then
    echo "Error: BUCKET or OSS_BUCKET not set"
    exit 1
fi
if [ -z "$OSS_ENDPOINT" ]; then
    echo "Error: ENDPOINT or OSS_ENDPOINT not set"
    exit 1
fi
if [ -z "$OSS_ACCESS_KEY_ID" ]; then
    echo "Error: ACCESSKEYID or OSS_ACCESS_KEY_ID not set"
    exit 1
fi
if [ -z "$OSS_ACCESS_KEY_SECRET" ]; then
    echo "Error: ACCESSKEYSECRET or OSS_ACCESS_KEY_SECRET not set"
    exit 1
fi

# --- Verify build output ---
if [ ! -d "_site" ]; then
    echo "Error: _site/ directory not found. Run build.sh first."
    exit 1
fi

# --- Check ossutil ---
OSSUTIL=""
for cmd in ossutil64 ossutil; do
    if command -v "$cmd" &>/dev/null; then
        OSSUTIL="$cmd"
        break
    fi
done

if [ -z "$OSSUTIL" ]; then
    echo "Error: ossutil not found"
    echo "Install: https://help.aliyun.com/document_detail/120075.html"
    echo ""
    echo "macOS: brew install aliyun-oss-util"
    echo "Linux: wget https://gosspublic.alicdn.com/ossutil/1.7.18/ossutil64 -O /usr/local/bin/ossutil && chmod +x /usr/local/bin/ossutil"
    exit 1
fi

echo "=== Deploying to Alibaba Cloud OSS ==="
echo "Bucket:   $OSS_BUCKET"
echo "Endpoint: $OSS_ENDPOINT"
echo "Source:   _site/"
echo "Tool:     $OSSUTIL"
echo ""

# --- Upload ---
export ALIBABA_CLOUD_ACCESS_KEY_ID="$OSS_ACCESS_KEY_ID"
export ALIBABA_CLOUD_ACCESS_KEY_SECRET="$OSS_ACCESS_KEY_SECRET"

"$OSSUTIL" config -i "$OSS_ACCESS_KEY_ID" -k "$OSS_ACCESS_KEY_SECRET" -e "$OSS_ENDPOINT"

echo "Uploading..."
"$OSSUTIL" cp -r _site/ "oss://$OSS_BUCKET/" -f

echo ""
echo "Deploy complete!"
echo "Visit: http://$OSS_BUCKET.$OSS_ENDPOINT"
