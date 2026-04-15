;; title:  Base Tower Defense
;; author: Showfeet
;; desc:   Mouvement & Camera centrée
;; script: fennel

;; --- CONSTANTES ---
(local screen-w 240)
(local screen-h 136)

;; --- ETAT DU JEU ---
(var player {:x 120 :y 68 :speed 2 :radius 4})
(var initialized false)

;; --- LOGIQUE ---

(fn player.update []
  ;; 1. On crée des variables pour stocker la direction voulue (0 par défaut)
  (var dx 0)
  (var dy 0)
  
  ;; 2. On lit les boutons
  (if (btn 0) (set dy -1)) ;; Haut
  (if (btn 1) (set dy 1))  ;; Bas
  (if (btn 2) (set dx -1)) ;; Gauche
  (if (btn 3) (set dx 1))  ;; Droite
  
  ;; 3. On calcule la vitesse actuelle
  (var current-speed player.speed)
  
  ;; Si on se déplace en diagonale (dx ET dy ne sont pas égaux à 0)
  (when (and (not= dx 0) (not= dy 0))
    ;; On réduit la vitesse pour compenser la diagonale
    (set current-speed (* player.speed 0.707)))
    
  ;; 4. On applique le mouvement au joueur
  (set player.x (+ player.x (* dx current-speed)))
  (set player.y (+ player.y (* dy current-speed))))

(fn get-camera []
  "Calcule les coordonnées en haut à gauche de la caméra pour centrer le joueur."
  (let [cam-x (- player.x (/ screen-w 2))
        cam-y (- player.y (/ screen-h 2))]
    (values cam-x cam-y)))

;; --- RENDU ---

(fn draw-map-view [cam-x cam-y]
  "Dessine uniquement la portion visible de la map (optimisation TIC-80).
   Gère un défilement fluide au pixel près."
  ;; Les cellules font 8x8. On utilise // (division entière) pour trouver la case de départ.
  (let [cell-x (// cam-x 8)
        cell-y (// cam-y 8)
        ;; L'offset permet le défilement "lisse" entre deux cases
        offset-x (- (% cam-x 8))
        offset-y (- (% cam-y 8))]
    ;; map(x, y, w, h, sx, sy)
    ;; 31x18 tuiles pour couvrir tout l'écran (240/8=30, 136/8=17 + 1 de marge)
    (map cell-x cell-y 31 18 offset-x offset-y)))

(fn draw-player []
  "Dessine le joueur. Puisque la map défile, le joueur reste physiquement au centre de l'écran."
  (circ (/ screen-w 2) (/ screen-h 2) player.radius 6)) ; 6 = Rouge dans la palette par défaut

(fn init-test-map []
  "Génère aléatoirement des tuiles pour rendre le défilement visible."
  (for [x 0 63]
    (for [y 0 63]
      ;; Place la tuile n°1 de manière aléatoire
      (if (= (math.random 0 5) 0)
        (mset x y 1)
        (mset x y 0)))))

;; --- BOUCLE PRINCIPALE ---

(global TIC
  (fn []
    ;; 1. Initialisation (exécutée une seule fois)
    (when (not initialized)
      (init-test-map)
      (set initialized true))

    ;; 2. Mise à jour de la logique
    (player.update)

    ;; 3. Dessin à l'écran
    (cls 12) ; Efface l'écran avec un fond bleu clair
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      (draw-player))))