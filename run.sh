#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
exec > >(tee run.log) 2>&1
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi
: "${OPENROUTER_API_KEY:?Set OPENROUTER_API_KEY in .env}"
cd problem

usage() {
  curl -fsS https://openrouter.ai/api/v1/key \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" | jq -er '.data.usage | numbers'
}

before=$(usage)
started=$(date +%s)
status=1
session=
command=(codex exec --color never --skip-git-repo-check
  -m "${MODEL:-openai/gpt-6.1-sol}" "$(cat ../prompt.txt)")
while true; do
  agent_status=0
  "${command[@]}" </dev/null || agent_status=$?
  case "$agent_status" in
    124|130|137|143) status=$agent_status; break ;;
  esac

  status=0
  feedback=$(bash -euc 'lake build; lake env lean Audit.lean' 2>&1) || status=$?
  printf '%s\n' "$feedback"
  if ((status == 0)); then break; fi
  case "$status" in 124|137) break ;; esac
  if ((agent_status != 0)); then status=$agent_status; break; fi
  if (($(date +%s) - started >= 18000)); then
    echo "Five hours elapsed; not starting another follow-up."
    break
  fi

  if [[ -z $session ]]; then
    session=$(sed -n 's/^session id: //p' ../run.log | sed -n '1p')
    if [[ -z $session ]]; then echo "Cannot identify the session to resume." >&2; break; fi
  fi
  continuation="$(cat ../prompt-follup.txt)

Last verification output:
$(printf '%s\n' "$feedback" | tail -n 80)"
  command=(codex exec --color never resume --skip-git-repo-check
    -m "${MODEL:-openai/gpt-6.1-sol}" "$session" "$continuation")
  echo "Audit failed; resuming session $session."
done

elapsed=$(( $(date +%s) - started ))
after=$(usage)
awk -v before="$before" -v after="$after" -v elapsed="$elapsed" -v status="$status" '
  BEGIN {
    cost = after - before
    printf "Elapsed: %ds; OpenRouter: $%.4f ($%.4f -> $%.4f); run exit: %d\n", elapsed, cost, before, after, status
    exit !(status == 0 && elapsed < 18000 && cost >= 0 && cost <= 20)
  }'
