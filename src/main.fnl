;; main.fnl
;; script: fennel
;; title:  Base Tower Defense
;; author: Showfeet

(local item        (include "src.item"))
(local inventory   (include "src.player.inventory"))
(local player-cls  (include "src.player.player"))
(local attack      (include "src.player.attack"))
(local weapon      (include "src.weapon.weapon"))
(local projectile  (include "src.weapon.projectile"))
(local hud         (include "src.hud"))
(local Civil       (include "src.pnj.civil"))
(local zombie-mod  (include "src.pnj.zombie"))
(local Arbre       (include "src.world.arbre"))
(local Rocher      (include "src.world.rocher"))
(local objects     (include "src.world.objects"))
(local game-map    (include "src.world.map"))

(local Zombie zombie-mod.Zombie)

(local screen-w 240)
(local screen-h 136)

(local ZOMBIE-MAX             20)
(local ZOMBIE-SPAWN-INTERVAL 120)
(local ZOMBIE-SPAWN-PAR-VAGUE  2)

(local p1 (player-cls.new 120 68))

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

(var game-over false)
(var civils  [])
(var zombies [])
(var zombie-spawn-timer 0)
(var zombie-spawn-points [])

(fn pal [c0 c1]
  (if (not= c0 nil)
      (poke4 (+ 32736 c0) c1)
      (for [i 0 15] (poke4 (+ 32736 i) i))))

(fn init-zombie-spawn-points []
  (for [tx 0 239]
    (for [ty 0 135]
      (let [t (mget tx ty)]
        (when (or (= t 61) (= t 62) (= t 63))
          (table.insert zombie-spawn-points
                        {:x (* tx 8) :y (* ty 8)}))))))

(fn spawn-zombie []
  (when (and (< (length zombies) ZOMBIE-MAX)
             (> (length zombie-spawn-points) 0))
    (for [_ 1 ZOMBIE-SPAWN-PAR-VAGUE]
      (when (< (length zombies) ZOMBIE-MAX)
        (let [idx (math.random 1 (length zombie-spawn-points))
              sp  (. zombie-spawn-points idx)
              z   (Zombie.new sp.x sp.y (length zombies))]
          (table.insert zombies z))))))

(fn update-world []
  (set world.time (+ world.time 1))
  (let [total     (+ world.day-duration world.night-duration)
        current   (% world.time total)
        was-night world.is-night]
    (set world.is-night (>= current world.day-duration))
    (when (and was-night (not world.is-night))
      (set world.day-count (+ world.day-count 1))
      (trace (.. "Jour " world.day-count))
      (objects.respawn-all))
    (when (and (not was-night) world.is-night
               (< (length civils) 15))
      (table.insert civils (Civil.new))))
  ;; Détection game over
  (when (<= p1.hp 0)
    (set game-over true)))

(fn update-zombies []
  (when world.is-night
    (set zombie-spawn-timer (+ zombie-spawn-timer 1))
    (when (>= zombie-spawn-timer ZOMBIE-SPAWN-INTERVAL)
      (set zombie-spawn-timer 0)
      (spawn-zombie)))

  ;; Traite UN seul recalcul A* par frame
  (zombie-mod.process-recalc-queue p1)

  (var i 1)
  (while (<= i (length zombies))
    (let [z (. zombies i)]
      (if (<= z.hp 0)
          (table.remove zombies i)
          (do
            (Zombie.update z p1)
            (set i (+ i 1)))))))

(fn check-projectiles-vs-zombies []
  (var pi 1)
  (while (<= pi (length projectile.actifs))
    (let [proj (. projectile.actifs pi)]
      (var touche false)
      (var zi 1)
      (while (<= zi (length zombies))
        (let [z    (. zombies zi)
              dx   (- proj.x z.x)
              dy   (- proj.y z.y)
              dist (math.sqrt (+ (* dx dx) (* dy dy)))]
          (when (and (> z.hp 0) (<= dist 8))
            (set z.hp (math.max 0 (- z.hp proj.degats)))
            (set proj.parcouru proj.portee-px)
            (set touche true)))
        (set zi (+ zi 1)))
      (set pi (+ pi 1)))))

(fn check-melee-vs-zombies []
  (when (and p1.attack-state.active
             p1.equipped-weapon
             (not p1.equipped-weapon.ranged))
    (let [w     p1.equipped-weapon
          range (* w.portee 8)
          ax    (if (= p1.direction :left)  (- p1.x range)
                    (= p1.direction :right) (+ p1.x 8)
                    (- p1.x 4))
          ay    (if (= p1.direction :up)    (- p1.y range)
                    (= p1.direction :down)  (+ p1.y 8)
                    (- p1.y 4))
          aw    (if (or (= p1.direction :left)
                        (= p1.direction :right)) range 16)
          ah    (if (or (= p1.direction :up)
                        (= p1.direction :down))  range 16)]
      (each [_ z (ipairs zombies)]
        (when (and (> z.hp 0)
                   (< ax (+ z.x 8)) (> (+ ax aw) z.x)
                   (< ay (+ z.y 8)) (> (+ ay ah) z.y))
          (set z.hp (math.max 0 (- z.hp w.degats))))))))

(fn get-camera []
  (values (- p1.x (/ screen-w 2))
          (- p1.y (/ screen-h 2))))

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

(fn reset-game []
  (set p1.hp      p1.max-hp)
  (set p1.x       120)
  (set p1.y       68)
  (set zombies    [])
  (set game-over  false)
  (set world.time 0)
  (set world.day-count 0)
  (set world.is-night  false)
  (set zombie-spawn-timer 0)
  (set zombie-mod.recalc-queue []))

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
      (init-zombie-spawn-points)
      (trace (.. "Objets: "        (length objects.liste)))
      (trace (.. "Spawn zombies: " (length zombie-spawn-points)))
      (init-civils)
      (set initialized true))

    ;; --- Game Over ---
    (when game-over
      (cls 0)
      (hud.draw-gameover screen-w screen-h)
      (print (.. "Jours survecus: " world.day-count)
             (- (// screen-w 2) 50)
             (+ (- (// screen-h 2) 30) 20)
             12 false 1 false)
      (when (btnp 4)
        (reset-game))
      (lua "return"))

    ;; --- Update ---
    (set prev-x p1.x)
    (set prev-y p1.y)

    (p1:update)
    (resolve-collision)
    (update-world)
    (handle-inputs)
    (attack.update p1)
    (projectile.update)
    (objects.update)
    (each [_ c (ipairs civils)]
      (Civil.update c world.is-night))
    (update-zombies)
    (check-projectiles-vs-zombies)
    (check-melee-vs-zombies)

    (pal)
    (when world.is-night (apply-night-filter))

    (cls 0)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      (objects.draw cam-x cam-y)
      (projectile.draw cam-x cam-y)
      (each [_ z (ipairs zombies)]
        (Zombie.draw z cam-x cam-y))
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