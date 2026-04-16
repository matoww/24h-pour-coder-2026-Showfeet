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
(local Nav         (include "src.pnj.naviguation"))
(local Arbre       (include "src.world.arbre"))
(local Rocher      (include "src.world.rocher"))
(local Rocherfer      (include "src.world.rocherfer"))
(local objects     (include "src.world.objects"))
(local game-map    (include "src.world.map"))
(local Base        (include "src.world.base"))
(local Buildings   (include "src.construisible.buildings"))
(local Menu        (include "src.menu"))

;; Mobs
(local MeleeMob    (include "src.pnj.meleeMob"))
(local RangedMob   (include "src.pnj.rangeMob"))

(local screen-w 240)
(local screen-h 136)

(local MOB-MAX        25)
(local SPAWN-INTERVAL 120)

(local p1 (player-cls.new 1585 825))

(var world
  {:time           0
   :day-duration   5600
   :night-duration 5600
   :is-night       false
   :day-count      0})

(var initialized false)
(var prev-x p1.x)
(var prev-y p1.y)
(var game-over false)
(var civils  [])
(var mobs    [])
(var spawn-timer 0)
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

(fn spawn-mob []
  ;; On vérifie d'abord qu'il y a bien des points de spawn
  (if (<= (length zombie-spawn-points) 0)
      (trace "ERREUR : Aucun point de spawn disponible !")
      
      ;; S'il y en a, on choisit un point au hasard
      (let [idx (math.random 1 (length zombie-spawn-points))
            sp  (. zombie-spawn-points idx)
            
            ;; On tire à pile ou face (50% de chance) pour choisir la classe du mob
            is-melee (< (math.random) 0.5)
            
            ;; On génère le monstre en fonction du tirage
            new-mob (if is-melee
                        ;; Cas 1 : C'est un monstre de mêlée (Barbare ou Araignée)
                        (let [type-key (if (< (math.random) 0.5) :barbare :araignee)]
                          (MeleeMob.new sp.x sp.y type-key))
                        
                        ;; Cas 2 : C'est un monstre à distance (Sorcier ou Sorcière)
                        (let [type-key (if (< (math.random) 0.5) :sorcier :sorciere)]
                          (RangedMob.new sp.x sp.y type-key)))]
        
        ;; On insère le nouveau monstre dans la liste globale
        (when new-mob
          (table.insert mobs new-mob)
          (trace (.. "Spawn ! Mobs: " (length mobs)))))))

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
  (when (<= p1.hp 0)
    (set game-over true)))

(fn update-mobs-logic []
  (Nav.process-queue p1) 
  (for [i (length mobs) 1 -1]
    (let [m (. mobs i)]
      (if (<= m.hp 0)
          (table.remove mobs i)
          (m:update p1)))))

(fn check-projectiles [targets]
  (var pi 1)
  (while (<= pi (length projectile.actifs))
    (let [proj (. projectile.actifs pi)]
      (var a-touche false)
      (each [_ target (ipairs targets)]
        (when (and (not a-touche) 
                   (> (or target.hp 0) 0) 
                   (not= target proj.owner))
          (let [dx (- proj.x (+ target.x 4))
                dy (- proj.y (+ target.y 4))
                dist (math.sqrt (+ (* dx dx) (* dy dy)))]
            (when (<= dist 8)
              (set target.hp (math.max 0 (- target.hp proj.degats)))
              (set proj.parcouru proj.portee-px) 
              (set a-touche true)))))
      (set pi (+ pi 1)))))

(fn check-hit [attacker targets]
  (let [st attacker.attack-state]
    (when (and st st.active st.weapon)
      (let [w     st.weapon
            range (* w.portee 8)
            ax    (if (= attacker.direction :left)  (- attacker.x range)
                      (= attacker.direction :right) (+ attacker.x 8)
                      (- attacker.x 4))
            ay    (if (= attacker.direction :up)    (- attacker.y range)
                      (= attacker.direction :down)  (+ attacker.y 8)
                      (- attacker.y 4))
            aw    (if (or (= attacker.direction :left) (= attacker.direction :right)) range 16)
            ah    (if (or (= attacker.direction :up)   (= attacker.direction :down))  range 16)]
        (each [_ target (ipairs targets)]
          (when (and (not= attacker target) 
                     (> (or target.hp 0) 0)
                     (< ax (+ target.x 8)) (> (+ ax aw) target.x)
                     (< ay (+ target.y 8)) (> (+ ay ah) target.y))
            (set target.hp (math.max 0 (- target.hp w.degats)))))))))

(fn get-camera []
  (values (- (+ p1.x 4) (/ screen-w 2))
          (- (+ p1.y 4) (/ screen-h 2)))) 

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
  (set p1.x       1585)
  (set p1.y       825)
  (set mobs       [])
  (set game-over  false)
  (set world.time 0)
  (set world.day-count 0)
  (set world.is-night  false)
  (set spawn-timer 0)
  (set Nav.recalc-queue [])
  (while (> (length Buildings.list) 0)
    (table.remove Buildings.list)))

;; -----------------------------------------------------------------
;; build-ctx : contexte transmis au Menu pour qu'il sache quoi faire.
;; Reconstruit chaque frame pour toujours avoir des données fraîches.
;; -----------------------------------------------------------------
(fn build-menu-ctx []
  {:inventory     p1.inventory
   :civils        civils
   :build-catalog Buildings.CATALOGUE
   :can-pay       (fn [info] (Buildings.peut-payer? p1.inventory info.cout))
   :on-build      (fn [info] (Buildings.placer p1 info))
   :on-civil      (fn [civil] (Buildings.assigner-civil civil Civil))})

;; -----------------------------------------------------------------
;; handle-inputs : délègue au menu s'il est ouvert
;; -----------------------------------------------------------------
(fn handle-inputs []

  (if (Menu.open?)
      (do
        (trace "[DEBUG] Menu ouvert, handle-input")
        (Menu.handle-input (build-menu-ctx)))
      (do
  (when (btnp 4)
    (let [w p1.equipped-weapon]
      (when (not= w nil)
        (if w.ranged
            (projectile.fire p1 w)
            (do
              (attack.start p1 w)
              (objects.hit-in-range p1 w inventory))))))
  (when (btnp 6)
          (trace "[DEBUG] Appel Menu.toggle")
          (Menu.toggle)
        (when (btnp 7)
          (weapon.cycle p1))))))


(music 0)

(global TIC
  (fn []
    (when (not initialized)
      (game-map.init objects Arbre Rocher item)
      (init-zombie-spawn-points)
      (set initialized true))

    ;; --- Game Over ---
    (when game-over
      (cls 0)
      (hud.draw-gameover screen-w screen-h)
      (when (btnp 4) (reset-game))
      (lua "return"))

    ;; --- Update ---
    (set prev-x p1.x)
    (set prev-y p1.y)

    ;; Quand le menu est ouvert, on fige le joueur mais on laisse
    ;; le monde tourner (les bâtiments bossent, les mobs avancent).
    (when (not (Menu.open?))
    (p1:update)
      (resolve-collision))

    (update-world)
    (handle-inputs)
    (attack.update p1)
    (projectile.update)
    (objects.update)
    (each [_ c (ipairs civils)] (Civil.update c world.is-night))
    
    ;; --- Spawn ---
    (set spawn-timer (+ spawn-timer 1))
    (when (= (% world.time 60) 0)
       (trace (.. "Etat: " (if world.is-night "NUIT" "JOUR") 
                 " | Mobs: " (length mobs)
                 " | Batiments: " (length Buildings.list))))
    (when (>= spawn-timer SPAWN-INTERVAL)
      (set spawn-timer 0)
      (when (> (length zombie-spawn-points) 0)
          (spawn-mob)))

    (update-mobs-logic)
    (Buildings.update mobs)
    (Buildings.auto-collecte p1)

    ;; --- Collisions ---
    (check-projectiles mobs)
    (check-projectiles [p1])
    (check-projectiles (Buildings.cibles-pour-mobs))
    (check-hit p1 mobs)
    (each [_ m (ipairs mobs)] (check-hit m [p1]))

    ;; --- Rendu ---
    (pal)
    (when world.is-night (apply-night-filter))
    (cls 0)
    (let [(cam-x cam-y) (get-camera)]
      (draw-map-view cam-x cam-y)
      (objects.draw cam-x cam-y)
      (Buildings.draw cam-x cam-y)
      (projectile.draw cam-x cam-y)
      (each [_ m (ipairs mobs)] (m:draw cam-x cam-y))
      (each [_ c (ipairs civils)] (Civil.draw c cam-x cam-y))
      (attack.draw p1 cam-x cam-y)
      (p1:draw screen-w screen-h))


    (pal)
    (hud.draw p1 screen-w screen-h)
    (hud.draw-clock world screen-w screen-h)
    ;; Menu unifié (onglets INVENT / BUILD / CIVILS)
    (Menu.draw screen-w screen-h (build-menu-ctx))))