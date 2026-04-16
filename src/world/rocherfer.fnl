(local Destructible (include "src.world.destructible"))

(local Rocherfer {})
(set Rocherfer.__index Rocherfer)
(setmetatable Rocherfer {:__index Destructible})

(local SPRITE-ROCHER-FER 20)   ;; ← mets le bon ID de ton rocher

(fn Rocherfer.new [x y item]
  (setmetatable
    (Destructible.new x y SPRITE-ROCHER-FER 5
      [{:ressource item.PIERRE :min 1 :max 3}]
      1 1)
    Rocherfer))

Rocherfer