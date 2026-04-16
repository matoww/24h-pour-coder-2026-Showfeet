;; zombie.fnl — A* avec file de recalcul (1 calcul max par frame)

(local astar (include "src.aStar"))

(local Zombie {})
(set Zombie.__index Zombie)

(local SPRITE-IDLE     276)
(local SPRITE-WALK     277)
(local ATTACK-RANGE     10)
(local ATTACK-COOLDOWN  45)
(local MAX-HP           30)
(local SPEED           0.8)
(local RECALC-INTERVAL 120) ;; frames entre recalculs pour chaque zombie

;; File globale : liste des zombies qui attendent un recalcul A*
;; Un seul est traité par frame
(var recalc-queue [])

(fn Zombie.new [x y index]
  (setmetatable
    {:x               x
     :y               y
     :speed           SPEED
     :hp              MAX-HP
     :damage          5
     :attack-cooldown 0
     :is-moving       false
     :flip            0
     :radius          4
     :path            nil
     :path-idx        1
     ;; Décale le premier recalcul selon l'index pour étaler les calculs
     :recalc-timer    (* (or index 0) 6)}
    Zombie))

;; --- FILE DE RECALCUL ---

(fn queue-recalc [zombie]
  ;; Évite les doublons dans la file
  (var already false)
  (each [_ z (ipairs recalc-queue)]
    (when (= z zombie) (set already true)))
  (when (not already)
    (table.insert recalc-queue zombie)))

(fn process-recalc-queue [player]
  ;; Traite UN SEUL zombie par frame
  (when (> (length recalc-queue) 0)
    (let [z (table.remove recalc-queue 1)
          start {:x (// z.x 8) :y (// z.y 8)}
          dest  {:x (// player.x 8) :y (// player.y 8)}]
      (set z.path     (astar.a-star start dest))
      (set z.path-idx 1))))

(fn Zombie.update [self player]
  ;; --- Timer de recalcul ---
  (if (> self.recalc-timer 0)
      (set self.recalc-timer (- self.recalc-timer 1))
      (do
        (queue-recalc self)
        (set self.recalc-timer RECALC-INTERVAL)))

  (let [dx   (- player.x self.x)
        dy   (- player.y self.y)
        dist (math.sqrt (+ (* dx dx) (* dy dy)))]

    (if (<= dist ATTACK-RANGE)
        ;; --- Attaque ---
        (do
          (set self.is-moving false)
          (when (> self.attack-cooldown 0)
            (set self.attack-cooldown (- self.attack-cooldown 1)))
          (when (<= self.attack-cooldown 0)
            (set player.hp (math.max 0 (- player.hp self.damage)))
            (set self.attack-cooldown ATTACK-COOLDOWN)))

        ;; --- Suit le chemin A* ---
        (if (and self.path (. self.path self.path-idx))
            (let [target (. self.path self.path-idx)
                  tx     (* target.x 8)
                  ty     (* target.y 8)
                  tdx    (- tx self.x)
                  tdy    (- ty self.y)
                  tdist  (math.sqrt (+ (* tdx tdx) (* tdy tdy)))]
              (if (> tdist 2)
                  ;; Avance vers la prochaine case
                  (do
                    (set self.is-moving true)
                    (set self.x (+ self.x (* (/ tdx tdist) self.speed)))
                    (set self.y (+ self.y (* (/ tdy tdist) self.speed)))
                    (set self.flip (if (< tdx 0) 1 0)))
                  ;; Case atteinte → passe à la suivante
                  (do
                    (set self.path-idx (+ self.path-idx 1))
                    (when (> self.path-idx (length self.path))
                      (set self.path nil)
                      (set self.is-moving false)))))
            ;; Pas de chemin → recalcul immédiat demandé
            (do
              (set self.is-moving false)
              (when (= self.recalc-timer RECALC-INTERVAL)
                (queue-recalc self)
                (set self.recalc-timer 0)))))))

(fn Zombie.draw [self cam-x cam-y]
  (let [sx (- self.x cam-x)
        sy (- self.y cam-y)]
    (when (and (> sx -8) (< sx 248)
               (> sy -8) (< sy 144))
      (let [sid (if (and self.is-moving
                         (= (% (// (time) 150) 2) 0))
                    SPRITE-WALK SPRITE-IDLE)]
        (spr sid sx sy 0 1 self.flip))
      (let [fw (math.floor (* 8 (/ self.hp MAX-HP)))]
        (rect sx (- sy 3) 8 2 0)
        (rect sx (- sy 3) fw 2 2)))))

{:Zombie          Zombie
 :process-recalc-queue process-recalc-queue
 :recalc-queue    recalc-queue}