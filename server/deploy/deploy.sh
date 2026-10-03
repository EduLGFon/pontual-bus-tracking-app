#!/usr/bin/env bash
# Pontual server deploy (T05). Tagged release unpack, checksum verify,
# backward-compatible migrations, symlink swap, restart, health check,
# instant rollback. Runs on the VPS as the admin user, never as root
# for the app itself. See PLAN.md 17.5 and docs/runbooks/ops.md.
#
# Usage:
#   deploy.sh deploy <tag> <artifact-dir>   # install and activate <tag>
#   deploy.sh rollback                        # reactivate the previous release
#
# Layout: /opt/pontual/releases/<tag>/, /opt/pontual/current symlink,
# /opt/pontual/previous symlink. Artifact dir holds the release files
# plus SHA256SUMS (source + deno.lock + built data bundle + checksums
# per PLAN 17.5). Deploy off-peak: a restart drops live state (KL6)
# and clients resume within one ping interval.
set -euo pipefail

ROOT="/opt/pontual"
SERVICE="pontual.service"
HEALTH="http://127.0.0.1:8080/v1/health"

cmd="${1:-}"
case "$cmd" in
  deploy)
    TAG="${2:-}"
    ARTIFACT="${3:-}"
    test -n "$TAG" || { echo "usage: deploy.sh deploy <tag> <artifact-dir>"; exit 2; }
    test -n "$ARTIFACT" || { echo "usage: deploy.sh deploy <tag> <artifact-dir>"; exit 2; }
    DEST="$ROOT/releases/$TAG"
    test ! -e "$DEST" || { echo "release $TAG already installed"; exit 1; }
    mkdir -p "$DEST"
    cp -r "$ARTIFACT"/. "$DEST"/
    (cd "$DEST" && sha256sum -c SHA256SUMS)
    if test -L "$ROOT/current"; then
      cp -P "$ROOT/current" "$ROOT/previous"
    fi
    ln -sfn "$DEST" "$ROOT/current"
    # Migrations are backward compatible by rule (add, never remove).
    DATABASE_URL="$(grep -E '^DATABASE_URL=' /etc/pontual/env | cut -d= -f2-)"
    export DATABASE_URL
    /usr/local/bin/dbmate -d "$DEST/server/db/migrations" up
    systemctl restart "$SERVICE"
    for i in $(seq 1 30); do
      if curl -fsS "$HEALTH" >/dev/null 2>&1; then
        echo "deploy $TAG live"
        exit 0
      fi
      sleep 2
    done
    echo "health check failed, rolling back"
    "$0" rollback
    exit 1
    ;;
  rollback)
    test -L "$ROOT/previous" || { echo "no previous release"; exit 1; }
    ln -sfn "$(readlink "$ROOT/previous")" "$ROOT/current"
    systemctl restart "$SERVICE"
    for i in $(seq 1 30); do
      if curl -fsS "$HEALTH" >/dev/null 2>&1; then
        echo "rollback live"
        exit 0
      fi
      sleep 2
    done
    echo "rollback health check failed"
    exit 1
    ;;
  *)
    echo "usage: deploy.sh deploy <tag> <artifact-dir> | rollback"
    exit 2
    ;;
esac
