#!/usr/bin/env bash
# Desktop notification for fresh jukkai staging deployments. Polled by the
# coolify-staging-notify systemd user timer; fires notify-send (SwayNC) when
# a staging app finishes a deployment.
#
# Freshness rules (so booting after a day away never dumps a pile of stale
# notifs): a deployment is only announced if it is NEW since the last poll
# AND finished within MAX_AGE_S. Everything seen is recorded as seen, fresh
# or not — first run after boot just catches up state silently.
#
# Auth: COOLIFY_TOKEN from ~/.config/coolify-promote.env (quoted — the token
# contains a `|`). Reaches the API through the Cloudflare Access bypass.
set -euo pipefail

COOLIFY_URL=https://coolify.martinmoradi.com
ENV_FILE="$HOME/.config/coolify-promote.env"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/coolify-notify"
MAX_AGE_S=600

# name:uuid of the staging apps to watch
APPS=(
  "studio-staging:mfvt9mp82wzq4ge4vo7i0bip"
  "studio-api-staging:x12ltuximsj3cry7jsam5z20"
  "wordmark-svc-staging:t108mzhkyvrfrrr95h2chfgw"
)

source "$ENV_FILE"
: "${COOLIFY_TOKEN:?COOLIFY_TOKEN missing from $ENV_FILE}"
mkdir -p "$STATE_DIR"

now=$(date +%s)

for entry in "${APPS[@]}"; do
  name="${entry%%:*}" uuid="${entry#*:}"
  state_file="$STATE_DIR/$name"

  latest=$(curl -sf -m 20 -H "Authorization: Bearer $COOLIFY_TOKEN" \
    "$COOLIFY_URL/api/v1/deployments/applications/$uuid?take=1" \
    | jq -r '.deployments[0] | "\(.deployment_uuid) \(.status) \(.updated_at) \(.commit)"') || continue
  read -r dep_uuid status updated_at commit <<<"$latest"
  [ "$dep_uuid" != "null" ] || continue

  # Still building: leave state untouched so the finished state is a change.
  case "$status" in finished|failed) ;; *) continue ;; esac

  seen=$(cat "$state_file" 2>/dev/null || true)
  echo "$dep_uuid:$status" > "$state_file"
  [ "$dep_uuid:$status" != "$seen" ] || continue
  [ -n "$seen" ] || continue   # first run: record silently

  age=$(( now - $(date -d "$updated_at" +%s) ))
  [ "$age" -le "$MAX_AGE_S" ] || continue

  if [ "$status" = finished ]; then
    notify-send -a coolify -i emblem-default \
      "🟢 $name deployed" "${commit:0:8} is live on staging"
  else
    notify-send -a coolify -u critical -i emblem-important \
      "🔴 $name deploy failed" "commit ${commit:0:8} — check Coolify"
  fi
done
