#!/usr/bin/env bash
# Status line: dir · git branch · model+effort · tokens · ctx% · 5h% · 7d%
input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")
model=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
ctx=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
tok_in=$(jq -r '.context_window.total_input_tokens // empty' <<<"$input")
tok_out=$(jq -r '.context_window.total_output_tokens // empty' <<<"$input")
rl5h=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
rl5h_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
rl7d=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
rl7d_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$input")

dim=$'\033[2m'; bold=$'\033[1m'; wht=$'\033[1m\033[97m'
cyan=$'\033[96m'; mag=$'\033[95m'; yel=$'\033[93m'; grn=$'\033[92m'; red=$'\033[91m'; orn=$'\033[38;5;214m'
rst=$'\033[0m'

effort_color() {
  case "$1" in
    low|medium) echo "$grn" ;;
    high)       echo "$yel" ;;
    xhigh)      echo "$orn" ;;
    max)        echo "$red" ;;
    *)          echo ""     ;;
  esac
}

pct_color() {
  local pct=$1
  if   [ "$pct" -ge 80 ]; then echo "${red}"
  elif [ "$pct" -ge 60 ]; then echo "${yel}"
  else echo "${grn}"; fi
}

fmt_remaining() {
  local ts=$1 now delta
  now=$(date +%s)
  delta=$(( ts - now ))
  [ "$delta" -le 0 ] && echo "now" && return
  local days=$(( delta / 86400 ))
  local hours=$(( (delta % 86400) / 3600 ))
  local mins=$(( (delta % 3600) / 60 ))
  if   [ "$days" -gt 0 ]; then printf "%dd%dh" "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then printf "%dh%02d" "$hours" "$mins"
  else printf "%dm" "$mins"; fi
}

pct_bar() {
  local pct=$1 width=8
  local filled=$(( pct * width / 100 ))
  local c; c=$(pct_color "$pct")
  local label="${pct}%"
  local llen=${#label}
  local lstart=$(( (width - llen) / 2 ))
  local bar="" lpos=0 i
  for ((i=0; i<width; i++)); do
    if [ "$i" -ge "$lstart" ] && [ "$lpos" -lt "$llen" ]; then
      bar+="${wht}${label:$lpos:1}${rst}"
      lpos=$(( lpos + 1 ))
    elif [ "$i" -lt "$filled" ]; then
      bar+="${c}█${rst}"
    else
      bar+="${dim}░${rst}"
    fi
  done
  echo "$bar"
}

branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)

if [ -n "$branch" ]; then
  out="${mag}${branch}${rst}"
else
  out="${cyan}$(basename "${dir:-?}")${rst}"
fi

# model + effort as one bold colored block
ec=$(effort_color "$effort")
out+=" ${dim}·${rst} ${bold}${ec}${model}"
[ -n "$effort" ] && out+=" ${effort}"
out+="${rst}"

if [ -n "$ctx" ] && [ -n "$tok_in" ] && [ -n "$tok_out" ]; then
  pct=${ctx%.*}
  c=$(pct_color "$pct")
  total=$(( tok_in + tok_out ))
  if [ "$total" -ge 1000 ]; then
    tok_fmt="$(( total / 1000 ))k"
  else
    tok_fmt="$total"
  fi
  out+=" ${dim}·${rst} ${c}${pct}% (${tok_fmt})${rst}"
fi

if [ -n "$rl5h" ]; then
  pct=${rl5h%.*}
  c=$(pct_color "$pct")
  remain=""
  [ -n "$rl5h_reset" ] && remain=" ${dim}($(fmt_remaining "$rl5h_reset"))${rst}"
  out+=" ${dim}·${rst} ${c}${pct}%${rst}${remain}"
fi

if [ -n "$rl7d" ]; then
  pct=${rl7d%.*}
  c=$(pct_color "$pct")
  remain=""
  [ -n "$rl7d_reset" ] && remain=" ${dim}($(fmt_remaining "$rl7d_reset"))${rst}"
  out+=" ${dim}·${rst} ${c}${pct}%${rst}${remain}"
fi

printf '%s' "$out"
