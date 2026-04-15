;; main.fnl
;; script: fennel
;; title:  Base Tower Defense
;; author: Showfeet

;; --- DÉPENDANCES ---
;; Ordre important : anime → agressif → player (chaîne d'héritage)
(local item       (include "src.item"))
(local inventory  (include "src.player.inventory"))
(local player-cls (include "src.player.player"))
(local attack     (include "src.player.attack"))
(local weapon     (include "src.weapon.weapon"))
(local projectile (include "src.weapon.projectile"))
(local hud        (include "src.hud"))

;; --- CONSTANTES ---
(local screen-w 240)
(local screen-h 136)

;; --- INSTANCE DU JOUEUR ---
(local p1 (player-cls.new 120 68))

;; --- ÉTAT DU MONDE ---
(var world
  {:time           0
   :day-duration   120
   :night-duration 120
   :is-night       false})

(var initialized    false)
(var inventory-open false)

;; --- OUTILS SYSTÈME ---

(fn pal [c0 c1]
  (if (not= c0 nil)
      (poke4 (+ 32736 c0) c1)
      (for [i 0 15] (poke4 (+ 32736 i) i))))

;; --- LOGIQUE DU MONDE ---

(fn update-world []
  (set world.time (+ world.time 1))
  (let [total   (+ world.day-duration world.night-duration)
        current (% world.time total)]
    (set world.is-night (>= current world.day-duration))))

;; --- CAMÉRA ---

(fn get-camera []
  (values (- p1.x (/ screen-w 2))
          (- p1.y (/ screen-h 2))))

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
  ;; Z (4) — attaque
  (when (btnp 4)
    (weapon.attaquer p1 attack projectile))
  ;; A (6) — ouvre / ferme l'inventaire
  (when (btnp 6)
    (set inventory-open (not inventory-open)))
  ;; S (7) — cycle arme équipée
  (when (btnp 7)
    (weapon.cycle p1)))

;; --- BOUCLE PRINCIPALE ---

(global TIC
  (fn []
    (when (not initialized)
      (init-test-map)
      (set initialized true))

    ;; 1. Mises à jour
    (p1:update)
    (update-world)
    (handle-inputs)
    (attack.update p1)
    (projectile.update)

    ;; 2. Palette scène
    (pal)
    (when world.is-night (apply-night-filter))

    ;; 3. Dessin scène
    (cls 0)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      (projectile.draw cam-x cam-y)
      (attack.draw p1 screen-w screen-h)
      (p1:draw screen-w screen-h))

    ;; 4. HUD avec palette d'origine
    (pal)
    (hud.draw p1 screen-w screen-h)

    ;; 5. Panneau inventaire
    (when inventory-open
      (hud.draw-inventory-panel
        p1.inventory item.RESSOURCES screen-w screen-h)
      (hud.draw-weapon-stats
        p1.equipped-weapon screen-w screen-h))))