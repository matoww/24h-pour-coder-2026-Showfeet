;; world/base.fnl

(local Destructible (include "src.world.destructible"))

(local Base {})
(set Base.__index Base)
(setmetatable Base {:__index Destructible})

(local SPRITE-BASE 142)   ;; adapte l'ID sprite

;; Rayon d'exclusion en tuiles
(local EXCLUSION-RADIUS 12)

(fn Base.new [tx ty]
  (setmetatable
    (Destructible.new (* tx 8) (* ty 8) SPRITE-BASE 999
      []       ;; pas de loot
      2 2)
    Base))

;; Retourne true si (tx, ty) est dans la zone d'exclusion
(fn Base.in-exclusion-zone? [self tx ty]
  (let [bx (/ self.x 8)
        by (/ self.y 8)
        dx (- tx bx)
        dy (- ty by)]
    (< (+ (* dx dx) (* dy dy))
       (* EXCLUSION-RADIUS EXCLUSION-RADIUS))))

Base