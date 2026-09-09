# 04 — Notice d'utilisation

Cette notice s'adresse à l'utilisateur final de l'infrastructure une fois les
VM démarrées.

---

## Démarrage

1. Démarrer la **VM Serveur** en premier et attendre ~30 secondes que les
   services se lancent.
2. Démarrer la **VM Cliente**. Elle obtient automatiquement une adresse IP,
   une passerelle et un DNS via le serveur (DHCP).

Vérifier depuis le client que tout est prêt :

```bash
ip -br addr          # une IP en 10.0.0.100-200
ping -c2 10.0.0.1    # le serveur repond
```

---

## Accès aux sites et interfaces

Depuis **Firefox sur la VM cliente** :

| Adresse | Description | Identifiants |
|---------|-------------|--------------|
| `https://www7.starfleet.lan` | Site de démonstration PHP 7.4 | — (public) |
| `https://www8.starfleet.lan` | Site de démonstration PHP 8.4 | — (public) |
| `https://www8.starfleet.lan/prive/` | Zone protégée par LDAP | utilisateur LDAP |
| `https://php.starfleet.lan` | phpMyAdmin (gestion BDD) | compte MariaDB |
| `https://admin.starfleet.lan` | Cockpit (administration) | compte système Linux |
| `https://vscore.starfleet.lan` | code-server (VS Code) | mot de passe code-server |

> Le premier accès HTTPS peut afficher un avertissement de sécurité tant que
> l'autorité de certification (`starfleet-CA.crt`) n'a pas été importée dans
> Firefox. Une fois importée (*Paramètres → Certificats → Autorités →
> Importer*), les sites affichent un cadenas normal.

---

## Les différents comptes

L'infrastructure utilise **quatre systèmes d'authentification distincts**.
Il est important de ne pas les confondre :

| Comptes | Servent à | Exemple |
|---------|-----------|---------|
| **Système Linux** | SSH, console, **Cockpit** | `alexis` |
| **LDAP** | Zones web protégées (`/prive/`) | `picard`, `riker`, `data`, `laforge`, `worf` |
| **MariaDB** | phpMyAdmin | `root` (SQL) |
| **FTP** | Serveur FTP | `ftpweb` |

> Exemple de confusion fréquente : un utilisateur **LDAP** (picard) ne peut pas
> se connecter à **Cockpit**, car Cockpit n'accepte que les comptes système
> Linux. Chaque compte a son périmètre.

---

## Transférer des fichiers web (FTP)

Le dépôt de fichiers sur le serveur web se fait par **FTP sécurisé (FTPS)**.

Avec **FileZilla** (sur le client) :

1. Hôte : `10.0.0.1`
2. Identifiant : `ftpweb`
3. Port : `21`
4. Chiffrement : **FTP explicite sur TLS**
5. Accepter le certificat présenté.

L'utilisateur `ftpweb` est **enfermé (chroot)** dans le dossier web
(`/var/www`) : il voit les dossiers `www7`, `www8`, `phpmyadmin` et peut y
déposer des fichiers, mais ne peut pas remonter ailleurs dans le système.

En ligne de commande (`lftp`) :

```bash
lftp -u ftpweb 10.0.0.1
set ssl:verify-certificate no
ls
```

---

## Administration système (Cockpit)

`https://admin.starfleet.lan` — connexion avec un **compte système Linux**.

Cockpit permet de consulter l'état des services, les journaux, le réseau, etc.

> Comme l'infrastructure n'utilise **aucun compte sudo**, la connexion à
> Cockpit avec un utilisateur standard donne un **accès en lecture
> (« accès limité »)**. C'est le comportement attendu, conforme à la politique
> de sécurité. Les modifications système se font en root via la console ou SSH.

---

## Développement (code-server)

`https://vscore.starfleet.lan` — un éditeur VS Code complet dans le navigateur,
protégé par mot de passe. Utile pour éditer directement les fichiers des sites
web hébergés.

---

## Sauvegarde de la configuration

La configuration complète du serveur est sauvegardée **automatiquement chaque
nuit** (tâche cron à 2h). Les archives sont dans `/var/backups/starfleet/`
et seules les 7 dernières sont conservées (rotation).

Lancer une sauvegarde manuelle à tout moment (en root) :

```bash
/opt/backup/backup-config.sh
```

Consulter le journal des sauvegardes automatiques :

```bash
cat /var/log/backup-starfleet.log
```

---

## Dépannage rapide

| Symptôme | Piste |
|----------|-------|
| Le client n'a pas d'IP | Vérifier que le serveur est démarré et que `isc-dhcp-server` tourne ; vérifier le LAN Segment |
| Pas d'accès Internet sur le client | Vérifier le NAT (`nft list ruleset`) et `ip_forward` sur le serveur |
| Un site ne répond pas | `nginx -t` puis `systemctl status nginx` ; vérifier la zone DNS |
| Avertissement certificat | Importer `starfleet-CA.crt` dans Firefox |
| Connexion Cockpit refusée | Utiliser un **compte système Linux**, pas un compte LDAP |
