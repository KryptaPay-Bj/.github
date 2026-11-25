#!/usr/bin/env bash
# Verifie qu'une PR est liee a une carte Trello ou a une issue GitHub.
# Lance par .github/workflows/pr-ticket.yml ; relit la PR par l'API, donc
# « Re-run » tient compte de la description et des labels du moment.
#
# Accepte (hors commentaires HTML), en debut de ligne :
#   Ticket: https://trello.com/c/<carte>
#   Closes|Fixes|Resolves|Refs|Ticket: #12
#   Closes|Fixes|Resolves|Refs|Ticket: KryptaPay-Bj/<depot>#12   (ou l'URL de l'issue)
#   Ticket: none — <raison>      seulement avec le label `no-ticket`
# Dispense : Dependabot, et les releases test -> main du meme depot.
#
# Usage : REPO=KryptaPay-Bj/kryptapay-api PR=12 check-ticket.sh   (GH_TOKEN pour gh)
set -euo pipefail
: "${REPO:?}" "${PR:?}"
org="${REPO%%/*}"

fail() { echo "::error::$1"; exit 1; }
pass() { echo "OK : $1"; exit 0; }

pr="$(gh api "repos/$REPO/pulls/$PR")"
field() { jq -r "$1" <<< "$pr"; }

[ "$(field .user.login)" = 'dependabot[bot]' ] && pass 'Dependabot, dispense'
[ "$(field .head.ref)" = test ] && [ "$(field .base.ref)" = main ] &&
  [ "$(field .head.repo.full_name)" = "$REPO" ] && pass 'release test -> main, dispensee'

# Sans les commentaires HTML : les exemples du modele ne comptent pas.
body="$(field '.body // ""' | tr -d '\r' | perl -0pe 's/<!--.*?(-->|\z)//gs')"

# Lignes « Ticket: … », « Closes #12 »…, sans puce ni gras eventuels.
lines="$(sed -E 's/^[[:space:]]*([-*][[:space:]]+)?//; s/\*\*//g' <<< "$body" |
  grep -iE '^(ticket|closes|fixes|resolves|refs)([[:space:]]*:|[[:space:]])' || true)"

if grep -qE 'https://trello\.com/c/[A-Za-z0-9]{8}([/?#[:space:]]|$)' <<< "$lines"; then
  pass 'carte Trello'
fi

# Issue d'un depot de l'org : owner/repo#n, URL, ou #n (ce depot).
ref="$(grep -oE "(https://github\.com/$org/[A-Za-z0-9._-]+/issues/[0-9]+|$org/[A-Za-z0-9._-]+#[0-9]+|(^|[[:space:]:])#[0-9]+)" <<< "$lines" | head -n1 | tr -d ' \t:' || true)"
if [ -n "$ref" ]; then
  # tr a retire « : » de https:// ; seul le numero et le depot servent ensuite.
  num="${ref##*[!0-9]}"
  case "$ref" in
    \#*)    issue_repo="$REPO" ;;
    http*)  issue_repo="$(cut -d/ -f4,5 <<< "$ref")" ;;
    *)      issue_repo="${ref%%#*}" ;;
  esac
  # Le jeton de la CI ne lit que ce depot : une issue d'un autre n'est pas verifiee.
  [ "$issue_repo" = "$REPO" ] || pass "issue $issue_repo#$num (autre depot, existence non verifiee)"
  issue="$(gh api "repos/$REPO/issues/$num" 2> /dev/null)" || fail "L'issue #$num n'existe pas dans $REPO."
  [ "$(jq -r 'has("pull_request")' <<< "$issue")" = false ] || fail "#$num est une PR, pas une issue."
  pass "issue #$num"
fi

if grep -qiE '^ticket[[:space:]]*:[[:space:]]*none[[:space:]]*(—|–|-|:)+[[:space:]]*[^[:space:]]{3,}' <<< "$lines"; then
  [ "$(field '[.labels[].name] | index("no-ticket") != null')" = true ] ||
    fail 'Ticket: none demande aussi le label no-ticket (urgence seulement).'
  pass 'urgence sans ticket (label no-ticket)'
fi

fail 'PR sans ticket : ajouter « Ticket: https://trello.com/c/… » ou « Closes #12 » dans la description (urgence : « Ticket: none — raison » et le label no-ticket).'
