# Déploiement d'un cœur IMS sur Kamailio

Projet du module **Réseaux Télécoms Multiservices** — Master Réseaux et Télécommunications, ESMT.
Auteur : **Sylla Abdoul Aziz**

Réalisation : du 11 au 22 novembre 2026 — publication sur GitHub : 27 novembre 2026.

## Objectif

Déployer un cœur **IMS** (IP Multimedia Subsystem) complet sur une seule machine **Ubuntu 24.04**, en installation native (sans Docker), puis vérifier qu'un REGISTER traverse toute la chaîne P-CSCF → I-CSCF → HSS → S-CSCF et reçoit un défi d'authentification **401 IMS-AKA**.

## Architecture

Toutes les fonctions tournent sur la machine `192.168.1.121`, domaine `ims.mnc001.mcc001.3gppnetwork.org`.

| Fonction | Logiciel | Ports |
|---|---|---|
| P-CSCF | Kamailio 6.1.5 (instance 1) | SIP 5060, Diameter 3871 |
| I-CSCF | Kamailio 6.1.5 (instance 2) | SIP 4060, Diameter 3869 |
| S-CSCF | Kamailio 6.1.5 (instance 3) | SIP 6060, Diameter 3870 |
| HSS | PyHSS | Diameter 3868, API REST 8080 |
| DNS | bind9 | 53 |
| Bases de données | MariaDB | 3306 |
| Relais média | RTPEngine | contrôle 2223, RTP 30000-40000 |

Interfaces : **SIP** entre le terminal et les CSCF, **Diameter (Cx)** entre l'I-CSCF / le S-CSCF et le HSS.

## Contenu du dépôt

- `config/kamailio_pcscf/` : configuration du P-CSCF (Rx et IPsec désactivés)
- `config/kamailio_icscf/` : configuration de l'I-CSCF
- `config/kamailio_scscf/` : configuration du S-CSCF (dispatcher.list vidé)
- `config/bind/` : zone DNS (enregistrements A et SRV) et options de bind9
- `config/pyhss/` : config.yaml de PyHSS
- `config/rtpengine/` : configuration de RTPEngine
- `config/systemd/` : services kamailio-ims@ et pyhss@, règle tmpfiles.d
- `sql/` : déclaration du S-CSCF et comptes MariaDB
- `scripts/` : création des abonnés Alice et Bob via l'API de PyHSS
- `tests/reg401.xml` : scénario SIPp, REGISTER jusqu'au 401
- `docs/` : rapport et captures d'écran

## Étapes de mise en place

1. **Kamailio 6.1** compilé depuis les sources avec les modules IMS (`ims_*`, `cdp`, `db_mysql`, `rtpengine`…), installé dans `/usr/local`.
2. **DNS bind9** : zone `ims.mnc001.mcc001.3gppnetwork.org` avec les enregistrements A et le SRV `_sip._udp` → `icscf:4060`.
3. **MariaDB** : bases `pcscf`, `icscf`, `scscf` créées avec les scripts de `utils/kamctl/mysql`, puis `sql/init_icscf_et_comptes.sql`.
4. **PyHSS** dans un environnement virtuel Python, avec Redis ; `bind_ip`, `OriginHost` et `OriginRealm` adaptés.
5. **Trois instances Kamailio** à partir de `misc/examples/ims`, adresse `11.22.33.44` remplacée par celle de la machine.
6. **Services systemd** : `kamailio-ims@{icscf,scscf,pcscf}`, `pyhss@{diameter,hss,api}`, `rtpengine-daemon`.
7. **Abonnés** Alice (IMSI 001010000010001, MSISDN 10001) et Bob (IMSI 001010000010002, MSISDN 10002) : `scripts/provision_abonnes.sh`.

## Test et résultat

Commande : `sipp -sf tests/reg401.xml 192.168.1.121:5060 -i 192.168.1.121 -p 5090 -m 1 -timeout 10 -nostdin -trace_msg`

Résultat : `SIP/2.0 401 Unauthorized - Challenging the UE` avec `WWW-Authenticate: Digest … algorithm=AKAv1-MD5`.

Séquence capturée avec tshark :

1. REGISTER : terminal → P-CSCF (5060)
2. REGISTER : P-CSCF → I-CSCF (4060), trouvé grâce au SRV du DNS
3. Diameter UAR/UAA (300) : I-CSCF ↔ HSS, choix du S-CSCF
4. REGISTER : I-CSCF → S-CSCF (6060)
5. Diameter MAR/MAA (303) : S-CSCF ↔ HSS, vecteur d'authentification AKA
6. 401 avec défi AKA : S-CSCF → I-CSCF → P-CSCF → terminal

## Problèmes rencontrés

- **Port 5060 occupé par Asterisk** (présent dans l'image de la VM) : service désactivé.
- **Kamailio en échec après redémarrage** : `/run/kamailio` est vidé à chaque démarrage ; ajout de la règle `config/systemd/tmpfiles-kamailio.conf`.
- **PyHSS arrêté après redémarrage** : création du service `pyhss@.service`.

## Limites

L'enregistrement complet (200 OK, échange SAR/SAA) et l'appel 10001 → 10002 (étape bonus 7.3) n'ont pas été réalisés : ils nécessitent un client IMS-AKA ou un vrai terminal VoLTE avec carte SIM.

Les mots de passe et clés présents dans ce dépôt sont les valeurs de test du TP (réseau de test MCC 001 / MNC 01), utilisables uniquement en local.
