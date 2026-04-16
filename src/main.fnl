;; main.fnl
;; script: fennel
;; title:  Base Tower Defense
;; author: Showfeet

;; --- DÉPENDANCES ---
(local item        (include "src.item"))
(local inventory   (include "src.player.inventory"))
(local player-cls  (include "src.player.player"))
(local attack      (include "src.player.attack"))
(local weapon      (include "src.weapon.weapon"))
(local projectile  (include "src.weapon.projectile"))
(local hud         (include "src.hud"))
(local Civil       (include "src.pnj.civil"))
(local Arbre       (include "src.world.arbre"))
(local Rocher      (include "src.world.rocher"))
(local objects     (include "src.world.objects"))
(local game-map    (include "src.world.map"))

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
   :is-night       false
   :day-count      0})

(var initialized    false)
(var inventory-open false)
(var prev-x p1.x)
(var prev-y p1.y)

;; --- LISTE DES CIVILS ---
(var civils [])

;; --- OUTILS SYSTÈME ---

(fn pal [c0 c1]
  (if (not= c0 nil)
      (poke4 (+ 32736 c0) c1)
      (for [i 0 15] (poke4 (+ 32736 i) i))))

;; --- LOGIQUE DU MONDE ---

(fn update-world []
  (set world.time (+ world.time 1))
  (let [total     (+ world.day-duration world.night-duration)
        current   (% world.time total)
        was-night world.is-night]
    (set world.is-night (>= current world.day-duration))
    ;; Passage nuit → jour
    (when (and was-night (not world.is-night))
      (set world.day-count (+ world.day-count 1))
      (objects.respawn-all))
    ;; Passage jour → nuit : spawn un civil (max 15)
    (when (and (not was-night) world.is-night
               (< (length civils) 15))
      (table.insert civils (Civil.new)))))

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

;; --- COLLISION MONDE ---

(fn resolve-collision []
  (let [r  p1.radius
        px p1.x
        py p1.y]
    (when (objects.check-collision px py r)
      (if (not (objects.check-collision prev-x py r))
          (set p1.x prev-x)
          (if (not (objects.check-collision px prev-y r))
              (set p1.y prev-y)
              (do (set p1.x prev-x)
                  (set p1.y prev-y)))))))

;; --- INPUTS ---

(fn handle-inputs []
  (when (btnp 4)
    (let [w p1.equipped-weapon]
      (when (not= w nil)
        (if w.ranged
            (projectile.fire p1 w)
            (do
              (attack.start p1 w)
              (objects.hit-in-range p1 w inventory))))))
  (when (btnp 5)
    (each [_ c (ipairs civils)]
      (when (not c.batiment)
        (Civil.assign-building c {:x p1.x :y p1.y})
        (trace (.. c.name " reçoit un bâtiment !"))
        (lua "break"))))
  (when (btnp 6)
    (set inventory-open (not inventory-open)))
  (when (btnp 7)
    (weapon.cycle p1)))

;; --- INIT CIVILS ---

(fn init-civils []
  (for [_ 1 3]
    (let [cx (* (math.random 5 25) 8)
          cy (* (math.random 5 15) 8)]
      (table.insert civils (Civil.new cx cy)))))

;; --- INITIALIZATION ---
(music 0)

;; --- BOUCLE PRINCIPALE ---

(global TIC
  (fn []
    (when (not initialized)
      (local ids-trouves {})
      (for [tx 0 239]
        (for [ty 0 135]
          (let [t (mget tx ty)]
            (when (> t 0)
              (tset ids-trouves t true)))))
      (each [id _ (pairs ids-trouves)]
        (trace (.. "Tile ID: " id)))
      (game-map.init objects Arbre Rocher item)
      (trace (.. "Objets: " (length objects.liste)))
      (init-civils)
      (set initialized true))

    ;; --- Sauvegarde position avant mouvement ---
    (set prev-x p1.x)
    (set prev-y p1.y)

    ;; --- Update ---
    (p1:update)
    (resolve-collision)
    (update-world)
    (handle-inputs)
    (attack.update p1)
    (projectile.update)
    (objects.update)
    (each [_ c (ipairs civils)]
      (Civil.update c world.is-night))

    ;; --- Palette ---
    (pal)
    (when world.is-night (apply-night-filter))

    ;; --- Rendu ---
    (cls 0)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      (objects.draw cam-x cam-y)
      (projectile.draw cam-x cam-y)
      (each [_ c (ipairs civils)]
        (Civil.draw c cam-x cam-y))
      (attack.draw p1 screen-w screen-h)
      (p1:draw screen-w screen-h))

    (pal)
    (hud.draw p1 screen-w screen-h)
    (hud.draw-clock world screen-w screen-h)

    (when inventory-open
      (hud.draw-inventory-panel
        p1.inventory item.RESSOURCES screen-w screen-h)
      (hud.draw-weapon-stats
        p1.equipped-weapon screen-w screen-h))))