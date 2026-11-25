# Commande de l'appli « WoW » de Sunshine. Sunshine garde la session tant que ce script tourne :
# - WoW fermé : on le lance par Battle.net (connexion automatique, écran des personnages) ;
# - WoW déjà ouvert : on ne relance rien (pas de deuxième WoW) ;
# puis on attend que WoW se ferme. Le script s'arrête alors, la session Sunshine aussi : le prochain
# appui sur le raccourci relance WoW.
$bnet = 'C:\Program Files (x86)\Battle.net\Battle.net.exe'
function WoW { Get-Process -Name Wow -ErrorAction SilentlyContinue }
function Lancer { Start-Process $bnet -ArgumentList '--exec="launch WoWF"' }

if (-not (WoW)) {
    # Battle.net fermé : on l'ouvre d'abord et on lui laisse le temps de se connecter. Un ordre « lancer »
    # donné pendant sa connexion est ignoré, c'est pour ça qu'on le redonne plus bas.
    if (-not (Get-Process -Name Battle.net -ErrorAction SilentlyContinue)) {
        Start-Process $bnet
        $limite = (Get-Date).AddSeconds(60)
        while ((Get-Date) -lt $limite) {
            Start-Sleep -Seconds 2
            $fenetre = Get-Process -Name Battle.net -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle }
            if ($fenetre) { break }
        }
        Start-Sleep -Seconds 8
    }
    # On donne l'ordre, puis on le redonne toutes les 20 secondes tant que le jeu n'est pas ouvert
    # (3 minutes au plus, une mise à jour du jeu peut passer avant).
    $limite = (Get-Date).AddMinutes(3)
    while (-not (WoW) -and (Get-Date) -lt $limite) {
        Lancer
        $attente = (Get-Date).AddSeconds(20)
        while (-not (WoW) -and (Get-Date) -lt $attente) { Start-Sleep -Seconds 2 }
    }
}
# Tant que le jeu est ouvert (un rechargement ou un écran de chargement ne ferme pas le processus).
while (WoW) { Start-Sleep -Seconds 3 }
