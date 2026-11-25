<!--
Titre : type(portee): resume court — ex. fix(payouts): ...
Base : test pour api et web, main pour les autres depots.
Merger = deployer : sur test pour api et web, en prod directement pour les autres.
-->

## Ticket

<!--
Obligatoire, une des deux formes :
  Ticket: https://trello.com/c/...
  Closes #12   (ou Refs KryptaPay-Bj/kryptapay-api#12 pour une issue d'un autre depot)
Urgence sans ticket : « Ticket: none — raison » et le label no-ticket.
-->

Ticket:

## Quoi

<!-- Ce que la PR change, en 2-3 phrases. -->

## Pourquoi

<!-- Le probleme ou la demande d'origine. -->

## Comment tester

<!-- Etapes pour verifier le changement en local ou sur test. -->

- [ ] Tests ajoutes ou mis a jour
- [ ] Verifie en local (ou sur test)

## Points sensibles

<!-- Cocher tout ce qui s'applique ; en cas de doute, cocher et expliquer. -->

- [ ] Argent : ledger, soldes, payouts, frais, FX, limites
- [ ] Migration de base : retro-compatible (l'ancienne et la nouvelle version tournent ensemble pendant le deploiement)
- [ ] Conformite : AML, KYC/KYB, screening
- [ ] Securite : authentification, roles et permissions, cles API, secrets
- [ ] API publique ou webhooks : reponse, champ ou comportement modifie (documentation a mettre a jour)
- [ ] Configuration : variable d'environnement nouvelle ou modifiee (`.env.example` et kryptapay-infra)
- [ ] Ordre de deploiement entre depots (ex. api avant web)
- [ ] Aucun de ces points

## Avant de demander la review

- [ ] Une seule intention par PR, diff relu
- [ ] Ni secret, ni donnee client, ni log de prod dans le diff ou la description
- [ ] Capture d'ecran si l'interface change
