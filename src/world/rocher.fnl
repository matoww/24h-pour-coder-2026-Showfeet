(local Destructible (include "src.world.destructible"))

(local Rocher {})
(set Rocher.__index Rocher)
(setmetatable Rocher {:__index Destructible})

(local SPRITE-ROCHER 4)   ;; ← mets le bon ID de ton rocher

(fn Rocher.new [x y item]
  (setmetatable
    (Destructible.new x y SPRITE-ROCHER 5
      [{:ressource item.PIERRE :min 1 :max 3}]
      1 1)
    Rocher))

Rocher