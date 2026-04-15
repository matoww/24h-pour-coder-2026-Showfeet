;; main.fnl
;; script: fennel
;; title:  Base Tower Defense
;; author: Showfeet

;; --- DÉPENDANCES ---
(local item      (include "src.item"))
(local inventory (include "src.player.inventory"))
(local hud       (include "src.hud"))
(local player    (include "src.player.player"))

;; --- CONSTANTES ---
(local screen-w 240)
(local screen-h 136)

;; --- ÉTAT DU MONDE ---
(var world
  {:time           0
   :day-duration   120
   :night-duration 120
   :is-night       false})

(var initialized     false)
(var inventory-open  false)   ;; toggle avec S (btn 7)

;; --- OUTILS SYSTÈME ---

(fn pal [c0 c1]
  (if (not= c0 nil)
      (poke4 (+ 32736 c0) c1)
      (for [i 0 15] (poke4 (+ 32736 i) i))))

;; --- LOGIQUE DU MONDE ---

(fn update-world []
  (when (btnp 4)
    (if world.is-night
        (set world.time 0)
        (set world.time world.day-duration)))
  (set world.time (+ world.time 1))
  (let [total   (+ world.day-duration world.night-duration)
        current (% world.time total)]
    (set world.is-night (>= current world.day-duration))))

;; --- CAMÉRA ---

(fn get-camera []
  (values (- player.x (/ screen-w 2))
          (- player.y (/ screen-h 2))))

;; --- RENDU ---

(fn draw-map-view [cam-x cam-y]
  (let [cell-x   (// cam-x 8)
        cell-y   (// cam-y 8)
        offset-x (- (% cam-x 8))
        offset-y (- (% cam-y 8))]
    (map cell-x cell-y 31 18 offset-x offset-y)))

(fn apply-night-filter []
  (pal 12 13) (pal 13 14) (pal 5  10)
  (pal 6   9) (pal 7   0) (pal 4  14)
  (pal 3   1) (pal 8   2) (pal 11 10)
  (pal 10  9))

(fn init-test-map []
  (for [x 0 63]
    (for [y 0 63]
      (mset x y (math.random 13 15)))))

;; --- INPUTS ---

(fn handle-inputs []
  ;; Debug pickup
  (when (btnp 4) (inventory.add player.inventory item.BOIS   1))
  (when (btnp 5) (inventory.add player.inventory item.PIERRE 1))
  ;; Toggle inventaire (S)
  (when (btnp 7)
    (set inventory-open (not inventory-open))))

;; --- BOUCLE PRINCIPALE ---

(global TIC
  (fn []
    (when (not initialized)
      (init-test-map)
      (set initialized true))

    ;; 1. Mises à jour
    (player.update screen-w screen-h)
    (update-world)
    (handle-inputs)

    ;; 2. Palette scène
    (pal)
    (when world.is-night (apply-night-filter))

    ;; 3. Dessin scène
    (cls 0)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      (player.draw screen-w screen-h))

    ;; 4. HUD avec palette d'origine
    (pal)
    (hud.draw player screen-w screen-h)

    ;; 5. Panneau inventaire (par-dessus tout si ouvert)
    (when inventory-open
      (hud.draw-inventory-panel
        player.inventory item.RESSOURCES screen-w screen-h))))