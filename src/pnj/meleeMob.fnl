;; melee_mob.fnl
(local attack (include "src.player.attack"))
(local nav    (include "src.pnj.naviguation")) ;; Changement ici

(local MeleeMob {})
(set MeleeMob.__index MeleeMob)

;; Liste des types de monstres au corps à corps
(local TYPES {
  :barbare  {:hp 30 :speed 0.8 :sprite-idle 276 :sprite-walk 277 :range 1 :degats 5}
  :araignee {:hp 15 :speed 1.2 :sprite-idle 272 :sprite-walk 273 :range 1 :degats 7}
})

(fn MeleeMob.new [x y type-key]
  (let [config (. TYPES type-key)
        self (setmetatable {
          :x x :y y
          :hp config.hp :max-hp config.hp :speed config.speed
          :sprite-idle config.sprite-idle :sprite-walk config.sprite-walk
          :direction :down :flip 0 :is-moving false
          :recalc-timer 0 :path nil :path-idx 1
          :attack-state {:active false :frame 0 :weapon {:degats config.degats :portee config.range :sprite-id 299}}
        } MeleeMob)]
    self))

(fn MeleeMob.update [self player]
  ;; 1. On demande un chemin au A* toutes les secondes
  (set self.recalc-timer (- self.recalc-timer 1))
  (when (<= self.recalc-timer 0)
    (nav.queue-recalc self)
    (set self.recalc-timer 60))

  ;; 2. MOUVEMENT
  (if (and self.path (. self.path self.path-idx))
      ;; Cas A : Il a un chemin A*, il le suit intelligemment
      (let [target (. self.path self.path-idx)
            tx (* target.x 8) 
            ty (* target.y 8)
            dx (- tx self.x)  
            dy (- ty self.y)
            dist (math.sqrt (+ (* dx dx) (* dy dy)))]
        (if (> dist 1)
            (do 
              (set self.x (+ self.x (* (/ dx dist) self.speed)))
              (set self.y (+ self.y (* (/ dy dist) self.speed)))
              (set self.is-moving true))
            (set self.path-idx (+ self.path-idx 1))))
      
      ;; 🔴 Cas B (LA SOLUTION) : S'il n'a PAS de chemin A*, 
      ;; il se dirige en ligne droite vers le joueur à travers les murs !
      (let [dx (- player.x self.x)
            dy (- player.y self.y)
            dist (math.sqrt (+ (* dx dx) (* dy dy)))]
        (if (> dist 1)
            (do
              (set self.x (+ self.x (* (/ dx dist) self.speed)))
              (set self.y (+ self.y (* (/ dy dist) self.speed)))
              (set self.is-moving true))
            (set self.is-moving false))))

  ;; 3. Logique d'attaque
  (let [dist-player (math.sqrt (+ (^ (- player.x self.x) 2) (^ (- player.y self.y) 2)))]
    (when (<= dist-player 12)
       (attack.start self self.attack-state.weapon)))
  (attack.update self))

(fn MeleeMob.draw [self cam-x cam-y]
  (let [sx (- self.x cam-x) sy (- self.y cam-y)
        sid (if (and self.is-moving (= (% (// (time) 150) 2) 0)) self.sprite-walk self.sprite-idle)]
    (spr sid sx sy 0 1 (if (= self.direction :left) 1 0))
    (attack.draw self cam-x cam-y))) ;; Affiche l'arme de l'ennemi 

{:new MeleeMob.new :TYPES TYPES}