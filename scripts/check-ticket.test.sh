#!/usr/bin/env bash
# Tests de check-ticket.sh, avec un faux `gh` (aucun appel reseau).
# Usage : bash scripts/check-ticket.test.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Faux gh : PR dans $tmp/pr.json ; issue 12 existe, 13 est une PR, le reste 404.
cat > "$tmp/gh" <<'GH'
#!/usr/bin/env bash
case "$2" in
  */pulls/*)    cat "$FAKE/pr.json" ;;
  */issues/12)  echo '{"number":12}' ;;
  */issues/13)  echo '{"number":13,"pull_request":{}}' ;;
  *)            exit 1 ;;
esac
GH
chmod +x "$tmp/gh"

failed=0
t() { # t <ok|ko> <nom> <description> [auteur] [head] [base] [label] [depot head]
  jq -n --arg b "$3" --arg u "${4:-dev}" --arg h "${5:-feat/x}" --arg m "${6:-test}" --arg l "${7:-}" \
    --arg r "${8:-KryptaPay-Bj/kryptapay-api}" \
    '{body:$b,user:{login:$u},head:{ref:$h,repo:{full_name:$r}},base:{ref:$m},
      labels:(if $l=="" then [] else [{name:$l}] end)}' > "$tmp/pr.json"
  local got=ok out
  out="$(FAKE="$tmp" PATH="$tmp:$PATH" REPO=KryptaPay-Bj/kryptapay-api PR=1 bash "$here/check-ticket.sh" 2>&1)" || got=ko
  if [ "$got" = "$1" ]; then echo "ok   $2"; else echo "FAIL $2 : attendu $1, obtenu $got ($out)"; failed=1; fi
}

t ok 'carte Trello'               $'## Ticket\n\nTicket: https://trello.com/c/AbCd1234/5-titre'
t ok 'carte Trello, CRLF et puce' $'- **Ticket:** https://trello.com/c/AbCd1234\r\n'
t ko 'tableau Trello'             'Ticket: https://trello.com/b/AbCd1234/tableau'
t ko 'autre domaine'              'Ticket: https://trello.com.evil.io/c/AbCd1234'
t ok 'Closes #12'                 'Closes #12'
t ok 'Ticket: #12'                'Ticket: #12'
t ok 'URL issue, meme depot'      'Refs https://github.com/KryptaPay-Bj/kryptapay-api/issues/12'
t ko 'URL issue inexistante'      'Refs https://github.com/KryptaPay-Bj/kryptapay-api/issues/99'
t ok 'issue autre depot'          'Refs KryptaPay-Bj/kryptapay-web#7'
t ok 'URL issue autre depot'      'Ticket: https://github.com/KryptaPay-Bj/kryptapay-web/issues/7'
t ko 'issue autre org'            'Refs autre-org/kryptapay-web#7'
t ko 'issue inexistante'          'Closes #99'
t ko 'PR et non issue'            'Closes #13'
t ko 'reference hors ligne ticket' 'voir #12 pour le contexte'
t ko 'vide'                       ''
t ko 'modele non rempli'          "$(cat "$here/../.github/pull_request_template.md")"
t ko 'ticket en commentaire'      '<!-- Ticket: https://trello.com/c/AbCd1234 -->'
t ko 'commentaire non ferme'      $'<!--\nCloses #12'
t ok 'urgence avec label'         'Ticket: none — paiements bloques' dev feat/x test no-ticket
t ko 'urgence sans label'         'Ticket: none — paiements bloques'
t ko 'urgence sans raison'        'Ticket: none' dev feat/x test no-ticket
t ko 'label seul'                 'rien' dev feat/x test no-ticket
t ok 'Dependabot'                 'Bumps x' 'dependabot[bot]'
t ok 'release'                    'release' dev test main
t ko 'release depuis un fork'     'release' dev test main '' pirate/kryptapay-api

exit "$failed"
