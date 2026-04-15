(local civil {})
(local civil-idle 258)
(local civil-walk 259)
(local position-base {:x 120 :y 68})
(local astar (include "src.aStar"))

(local lst-name ["Alice" "Gauthier" "Anthony" "Lucas" "Marie" "Lynn" "Quentin" "Sébastien" "Flora" "Claire"] )

(local lst-dialog [
  "Salut, je peux me joindre à toi ?"
  "Fais attention, il y a des dangers dans les environs. Unissons nos forces pour survivre !"
  "Je suis à la recherche de ressources, tu en as peut-être à partager ?"
  "Tu devrais éviter la zone nord, c'est infesté de créatures. Tu connaîtrais un endroit sûr pour se cacher ?"
  "Je pensais que j'étais seul, mais je suis content de te voir. On pourrait s'entraider pour trouver de la nourriture et de l'eau."
  "Je suis à la recherche d'un groupe de survivants, tu en fais partie ?"
  "Je suis un ancien médecin, je peux peut-être t'aider si tu es blessé."
])

(fn civil.new [self]
( set self.x  math.random (240))
( set self.y math.random (136))
( set self.speed 1)
( set self.batiment nil)

( set self.path nil)
( set self.destination nil)
( set self.is-moving false)
( set self.flip 0)

( set self.name (lst-name (math.random 1 (length lst-name))))
( set self.dialog (lst-dialog (math.random 1 (length lst-dialog))))
( set self.construction self.defineStat (astar.heuristic position-base {:x self.x :y self.y}) (astar.heuristic {:x 0 :y 0} {x 240 :y 136}))
( set self.recolte self.defineStat (astar.heuristic position-base {:x self.x :y self.y}) (astar.heuristic {:x 0 :y 0} {x 240 :y 136})))

(fn civil.defineStat [self distance max-dist]
  (let [min-possible 1
        max-possible 100
        spread 20
        
        dist-factor (/ (math.min distance max-dist) max-dist)
        
        low-bound (+ min-possible (* dist-factor (- max-possible spread)))
        high-bound (+ low-bound spread)
        
        raw-stat (math.random (math.floor low-bound) (math.floor high-bound))]

    (math.max min-possible (math.min max-possible raw-stat))))

(fn civil.ia [self])

(fn civil.draw [self])

(fn civil.interact [self player])

(fn civil.update [self])