;; script: fennel
;; title:  Base Tower Defense
;; author: Showfeet
;; desc:   Main propre avec module externe Player
;; palette: 0e0f1833153361222e8345308c70405c843e1f6537143e438c625420336f245b873f838886868651616b2f3b4a1c2130

;; --- DEPENDANCES ---
;; On utilise 'include' au lieu de 'require' pour forcer Fennel 
;; à fusionner le fichier lors de la compilation dans TIC-80.
(local player (include "src.player"))

;; --- CONSTANTES ---
(local screen-w 240)
(local screen-h 136)

;; --- ETAT DU MONDE ---
(var world {:time 0
            :day-duration 120
            :night-duration 120
            :is-night false})

(var initialized false)

;; --- OUTILS SYSTÈME ---

(fn pal [c0 c1]
  "Recrée la fonction 'pal' en modifiant la mémoire vidéo de la TIC-80."
  (if (not= c0 nil)
      (poke4 (+ 32736 c0) c1)
      (for [i 0 15]
        (poke4 (+ 32736 i) i))))

;; --- LOGIQUE DU MONDE ---

(fn update-world []
  "Fait avancer le temps. Appuie sur Z (btnp 4) pour basculer en mode Dev."
  (when (btnp 4)
    (if world.is-night
        (set world.time 0)
        (set world.time world.day-duration)))
        
  (set world.time (+ world.time 1))
  
  (let [cycle-total (+ world.day-duration world.night-duration)
        current-time (% world.time cycle-total)]
    (if (>= current-time world.day-duration)
        (set world.is-night true)
        (set world.is-night false))))

(fn get-camera []
  (let [cam-x (- player.x (/ screen-w 2))
        cam-y (- player.y (/ screen-h 2))]
    (values cam-x cam-y)))

;; --- RENDU ---

(fn draw-map-view [cam-x cam-y]
  (let [cell-x (// cam-x 8)
        cell-y (// cam-y 8)
        offset-x (- (% cam-x 8))
        offset-y (- (% cam-y 8))]
    (map cell-x cell-y 31 18 offset-x offset-y)))

(fn apply-night-filter []
  "Filtre de nuit adapté à la nouvelle palette."
  (pal 12 13) ; Gris clair -> Gris moyen
  (pal 13 14) ; Gris moyen -> Gris bleuté
  (pal 5 10)  ; Vert clair -> Bleu acier
  (pal 6 9)   ; Vert forêt -> Bleu roi sombre
  (pal 7 0)   ; Vert émeraude -> Bleu nuit
  (pal 4 14)  ; Sable -> Gris bleuté
  (pal 3 1)   ; Marron -> Violet sombre
  (pal 8 2)   ; Rose/Marron clair -> Bordeaux
  (pal 11 10) ; Cyan -> Bleu acier
  (pal 10 9)) ; Bleu acier -> Bleu roi sombre

(fn init-test-map []
  (for [x 0 63]
    (for [y 0 63]
      (mset x y (math.random 13 15)))))

;; --- BOUCLE PRINCIPALE ---

(global TIC
  (fn []
    (when (not initialized)
      (init-test-map)
      (set initialized true))

    ;; 1. Mises à jour
    ;; On appelle la fonction de ton fichier player.fnl
    (player.update screen-w screen-h)
    (update-world)

    ;; 2. Gestion de la Palette (Filtre Nuit)
    (pal)
    (when world.is-night
      (apply-night-filter))

    ;; 3. Dessin
    (cls 0)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      ;; On dessine le joueur par-dessus la map
      (player.draw screen-w screen-h))))