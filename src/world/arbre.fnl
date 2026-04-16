(local Destructible (include "src.world.destructible"))

(local Arbre {})
(set Arbre.__index Arbre)
(setmetatable Arbre {:__index Destructible})

;; Sprite 2x2 : cases 32, 33 (ligne du haut) et 48, 49 (ligne du bas)
;; On passe le coin haut-gauche = 32
(local SPRITE-ARBRE 32)

(fn Arbre.new [x y item]
  (setmetatable
    (Destructible.new x y SPRITE-ARBRE 3
      [{:ressource item.BOIS :min 2 :max 4}]
      2 2)   ;; ← sprite-w=2 sprite-h=2
    Arbre))

Arbre