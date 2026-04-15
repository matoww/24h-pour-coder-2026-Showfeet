;; script: fennel
;; title:  Base Tower Defense
;; author: Showfeet
;; desc:   Mouvement, Caméra & Animation (Version Multi-fichiers)

;; Import du module player
;; Avec --require-as-include, le chemin est relatif à l'endroit où tu lances la commande
(local player (include :src.player))

;; --- CONSTANTES ---
(local screen-w 240)
(local screen-h 136)

;; --- ETAT GLOBAL ---
(var initialized false)

;; --- LOGIQUE CARTE & CAMERA ---

(fn get-camera []
  "Calcule la position de la caméra basée sur la position du joueur."
  (let [cam-x (- player.x (/ screen-w 2))
        cam-y (- player.y (/ screen-h 2))]
    (values cam-x cam-y)))

(fn draw-map-view [cam-x cam-y]
  (let [cell-x (// cam-x 8)
        cell-y (// cam-y 8)
        offset-x (- (% cam-x 8))
        offset-y (- (% cam-y 8))]
    (map cell-x cell-y 31 18 offset-x offset-y)))

(fn init-test-map []
  (for [x 0 63]
    (for [y 0 63]
      (if (= (math.random 0 10) 0)
          (mset x y 1)
          (mset x y 0)))))

;; --- BOUCLE PRINCIPALE ---

(global TIC
  (fn []
    (when (not initialized)
      (init-test-map)
      (set initialized true))

    ;; Mise à jour du joueur (logique exportée)
    (player.update screen-w screen-h)

    ;; Rendu
    (cls 12)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      ;; Dessin du joueur (rendu exporté)
      (player.draw screen-w screen-h))))