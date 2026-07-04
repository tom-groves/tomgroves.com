#!/usr/bin/env bash
# Deploy the site to S3, rsync-style: upload new/changed files, delete removed ones.
# The bucket is versioned, so deletes are recoverable delete markers.
#
# Usage:
#   ./deploy.sh <bucket>            deploy
#   ./deploy.sh <bucket> --dryrun   show what would change without touching the bucket
#   DEPLOY_BUCKET=my-bucket ./deploy.sh
set -euo pipefail

BUCKET="${1:-${DEPLOY_BUCKET:-}}"
if [[ -z "$BUCKET" ]]; then
  echo "usage: ./deploy.sh <bucket-name> [--dryrun]  (or set DEPLOY_BUCKET)" >&2
  exit 1
fi
shift || true

cd "$(dirname "$0")"

EXCLUDES=(
  --exclude ".git/*"
  --exclude ".claude/*"
  --exclude ".gitignore"
  --exclude ".DS_Store"
  --exclude "*/.DS_Store"
  --exclude "README.md"
  --exclude "deploy.sh"
)

# Everything except HTML: content-addressed enough to cache for a day.
aws s3 sync . "s3://${BUCKET}" \
  --delete \
  "${EXCLUDES[@]}" \
  --exclude "*.html" \
  --cache-control "public, max-age=86400" \
  "$@"

# HTML: always revalidate so copy changes show up immediately.
aws s3 sync . "s3://${BUCKET}" \
  "${EXCLUDES[@]}" \
  --exclude "*" \
  --include "*.html" \
  --cache-control "no-cache" \
  --content-type "text/html; charset=utf-8" \
  "$@"

echo "Deployed to s3://${BUCKET}"
