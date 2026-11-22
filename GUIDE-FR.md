# Guide : jouer à WoW sur ton téléphone avec StreamTouch

*[English version](GUIDE.md)*

Le principe : ton PC fait tourner World of Warcraft, **Sunshine** envoie l'image au téléphone, et **StreamTouch** affiche l'image
et sert de manette tactile. L'addon **Streaming Touch** ajoute dans le jeu l'arc de sorts et le menu rond. Avec **Tailscale**,
ça marche aussi hors de chez toi (4G/5G, Wi-Fi d'un ami), et avec le **Magic Packet** tu peux allumer le PC à distance.

Compte 30 minutes la première fois. Ensuite, tu lances StreamTouch et tu joues.

## Ce qu'il te faut

- Un PC Windows avec World of Warcraft, branché **en câble** (Ethernet) sur ta box de préférence.
- Un téléphone Android 8.0 ou plus récent (64 bits).
- Un compte Tailscale gratuit (Google, Microsoft, GitHub ou e-mail).

## 1. Sur le PC : Sunshine

Sunshine est le serveur de streaming (gratuit et libre).

1. Télécharge et installe Sunshine : https://github.com/LizardByte/Sunshine/releases (le fichier `.exe` pour Windows).
   Pendant l'installation, accepte le pilote de manette virtuelle (ViGEmBus) : il sert au mode manette de StreamTouch.
2. Ouvre l'interface de Sunshine dans le navigateur du PC : **https://localhost:47990**. Accepte l'avertissement de sécurité
   (le certificat est local), puis crée un nom d'utilisateur et un mot de passe.
3. Réglages conseillés (onglet **Configuration**) :
   - **Audio/Video > Display Device** : « Désactiver les autres écrans » et une **résolution manuelle** égale à celle de ton
     téléphone (par exemple `2770x1280` pour un Poco F7). L'image remplit alors tout l'écran du téléphone, sans bandes noires.
   - **Input > Gamepad** : `x360`, pilote `vigembus`.
4. Laisse Sunshine démarrer avec Windows (c'est le cas par défaut, c'est un service).

Le programme « Desktop » (bureau) suffit : tu lances WoW depuis le bureau pendant le stream.

## 2. Sur le téléphone : StreamTouch

1. Télécharge `StreamTouch-1.0.0.apk` dans **Releases** : https://github.com/RappaceFer/StreamTouch/releases
2. Installe-le (Android demande d'autoriser l'installation depuis le navigateur ou le gestionnaire de fichiers).
3. L'appli arrive **déjà réglée** avec les réglages de Rappace : place des boutons, tailles, transparence, mode tactile au démarrage.
   Tout se change ensuite dans le menu rond (bouton Menu, ou maintenir Clavier) > Réglages.

## 3. Jouer chez toi (même Wi-Fi)

1. Téléphone et PC sur le même réseau : StreamTouch trouve le PC tout seul. Sinon, **+** et l'adresse locale du PC
   (par exemple `192.168.1.20`, visible dans Sunshine ou avec `ipconfig`).
2. Touche le PC : StreamTouch affiche un **code PIN**. Sur le PC, dans Sunshine, onglet **PIN**, tape ce code.
   C'est l'association, à faire une seule fois.
3. Touche **Desktop** : le bureau du PC apparaît, avec les commandes tactiles par-dessus. Lance WoW.

## 4. Jouer hors de chez toi : Tailscale

Tailscale relie ton téléphone à ton PC comme s'ils étaient chez toi, sans ouvrir de port sur ta box, de façon chiffrée.

1. Crée un compte sur https://tailscale.com (gratuit pour un usage personnel).
2. Installe Tailscale **sur le PC** (https://tailscale.com/download) et connecte-toi avec ce compte.
3. Installe Tailscale **sur le téléphone** (Google Play) et connecte-toi avec **le même compte**. Active-le.
4. Dans l'appli Tailscale, repère l'adresse du PC : elle commence par `100.` (par exemple `100.101.102.103`).
5. Dans StreamTouch : **+**, tape cette adresse `100.x.x.x`, puis associe avec le PIN comme au point 3.
   Cette entrée marche partout, chez toi comme dehors.
6. Pour jouer dehors : active Tailscale sur le téléphone, ouvre StreamTouch, touche le PC.

Conseils pour une image fluide dehors (dans les réglages du stream de StreamTouch) :
- Commence à **60 images/s** et un débit autour de **10 à 15 Mbit/s** en 4G/5G (20 Mbit/s ou plus en bon Wi-Fi), puis ajuste.
- Si l'image saccade, baisse le débit avant la résolution.
- Codec **H.265 (HEVC)** si ton téléphone le gère : même qualité avec moins de débit.

## 5. Allumer le PC à distance : le Magic Packet (Wake-on-LAN)

Le « Magic Packet » est un petit message réseau qui réveille un PC éteint ou en veille. Il faut le préparer une fois.

**Sur le PC :**
1. **BIOS / UEFI** (touche Suppr ou F2 au démarrage) : active **Wake on LAN** (parfois « Power On by PCI-E » ou « Resume by LAN »).
2. **Windows** : Gestionnaire de périphériques > Cartes réseau > ta carte **Ethernet** > Propriétés.
   - Onglet **Avancé** : **Réveil sur Magic Packet** = Activé, et **Arrêter Réveil par réseau** (Shutdown Wake-On-LAN) = Activé.
   - Onglet **Gestion de l'alimentation** : coche « Autoriser ce périphérique à sortir l'ordinateur du mode veille »
     et « Autoriser uniquement un paquet magique à sortir l'ordinateur du mode veille ».
3. Panneau de configuration > Options d'alimentation > « Choisir l'action des boutons d'alimentation » :
   décoche **Activer le démarrage rapide** (sinon le PC ne se réveille pas une fois éteint).
4. Note l'**adresse MAC** de la carte Ethernet (`ipconfig /all`, ligne « Adresse physique »).

Le Wake-on-LAN marche en câble Ethernet ; en Wi-Fi, la plupart des PC ne se réveillent pas.

**Chez toi :** dans StreamTouch, **appui long sur le PC > Envoyer une requête Wake-On-LAN**. Attends 20 à 30 secondes,
puis touche le PC.

**Dehors :** un PC endormi n'est plus joignable par Tailscale, et le Magic Packet ne traverse pas Internet tout seul.
Il faut qu'un appareil **toujours allumé chez toi** l'envoie à ta place. Au choix :
- **Ta box** : beaucoup de box ont le réveil de PC dans leur appli (par exemple la Fritz!Box). C'est le plus simple.
- **Un petit appareil allumé en permanence** avec Tailscale (Raspberry Pi, mini-PC, NAS) : depuis le téléphone, une appli
  Wake-on-LAN (ou SSH avec la commande `wakeonlan` et l'adresse MAC du PC) lui fait envoyer le Magic Packet sur ton réseau.

Ensuite : Tailscale activé, StreamTouch, touche le PC.

## 6. Dans World of Warcraft : l'addon Streaming Touch

1. Télécharge `StreamingTouch-2.4.0.zip` dans **Releases**.
2. Dézippe-le dans `World of Warcraft\_forever_\Interface\AddOns` : tu dois obtenir `AddOns\StreamingTouch`.
3. Lance le jeu. L'addon arrive **déjà réglé** : arc de sorts autour du joystick caméra, avec les sorts conseillés de ta classe,
   menu rond, chat placé au-dessus du clavier du téléphone. Réglages : bouton de la mini-carte ou `/stouch`.

Réglages facultatifs de Rappace, dans le dossier [`reglages-wow`](reglages-wow) :
- **Réglages de l'addon** (`streaming-touch-papa-rapace.txt`) : `/stouch` > Commandes > **Importer des réglages (texte)**,
  colle le texte, **Importer**.
- **Disposition de l'interface** (`disposition-mode-edition.txt`) : Échap > **Mode Édition** > menu des dispositions > **Importer**,
  colle le texte et donne-lui un nom.

## 7. Les commandes en jeu, en bref

- **Joystick gauche** : avancer, reculer, aller de côté. Un appui : Utiliser ; deux appuis : course automatique.
- **Joystick droit** : la caméra. Un appui : cibler ; deux appuis : sauter. L'arc de sorts est autour de lui.
- **Le reste de l'écran** est une souris : toucher = clic, maintenir = clic droit, glisser, deux doigts = molette.
- **Bouton 2** (maintenu) : deuxième couche de sorts. **Target** maintenu : le cadavre le plus proche à fouiller.
- **Clavier** : le clavier (maintenu : le menu rond, avec le guide intégré et tous les réglages).

## 8. L'appli et l'addon ensemble : appui, appui long, deux couches

L'appli ne connaît pas tes sorts : elle envoie des clics et des touches, et l'addon décide quoi lancer.

**Les boutons de l'arc de sorts**
- **Appui court** : lance le sort du bouton, toujours ton meilleur rang appris.
- **Appui long** (garde le doigt ½ seconde) : l'appli envoie un clic droit, et l'addon lance le **second sort** du bouton.
  Exemples pour un chasseur : Tir des Arcanes / Visée, Morsure de serpent / Morsure de scorpide, Raptor / Mangouste,
  Appeler le familier / Renvoyer. Pour choisir : `/stouch` > éditeur de l'arc de sorts > touche le bouton > **Maintien** > **Choisir…**.
- Un bouton peut aussi être un **sous-menu** : il ouvre une bulle avec les boutons d'une autre page (Familier, Pièges…).
- Les sorts pas encore appris restent cachés et apparaissent tout seuls quand tu les apprends.

**Les pages de l'arc**
- **Couche 2** : tant que tu maintiens le bouton Couche 2 de l'appli (il envoie la touche F12), l'arc montre la page
  « Couche 2 » (pour le chasseur : la Mêlée). Tu lâches, il revient à la page d'avant.
- **En combat / Hors combat** : la page qui vient toute seule au début et à la fin d'un combat (pour le chasseur : Tirs en combat).
- **Posture / forme** : la page qui vient toute seule quand tu prends une forme (ours, félin, posture défensive, camouflage…).
- **Flèches < >** à côté de l'arc pour changer de page à la main (elles se cachent dans `/stouch` si tu ne t'en sers pas).
- Le rôle de chaque page se règle dans l'éditeur de l'arc : sélectionne la page, puis Couche 2, En combat, Hors combat, Posture / forme.

**Les autres boutons de l'appli, côté jeu**
- **Target maintenu** (touche F10) : vise le cadavre à fouiller devant toi. Un appui simple sur le joystick droit cible.
- **Joystick gauche vers la gauche ou la droite** : ton personnage fait un pas de côté au lieu de tourner (touches A et D).
  La caméra se tourne avec le joystick droit. Tu peux couper ce réglage dans `/stouch` > Commandes.
- **Clavier** : quand tu écris, la ligne du chat monte au-dessus du clavier du téléphone.

## Problèmes fréquents

- **Le PC n'apparaît pas** : même réseau ? Sinon ajoute-le avec son adresse (locale ou `100.x.x.x` de Tailscale).
- **Ça marche chez moi mais pas dehors** : Tailscale est-il activé sur le téléphone **et** sur le PC, avec le même compte ?
- **Image noire ou bandes noires** : règle la résolution manuelle de Sunshine sur celle du téléphone.
- **Le PC ne se réveille pas** : câble Ethernet, Wake on LAN dans le BIOS, démarrage rapide de Windows désactivé.
- **Pas de son** : vérifie que le son n'est pas coupé dans les réglages du stream de StreamTouch.
