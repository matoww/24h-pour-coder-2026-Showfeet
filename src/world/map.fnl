;; map.fnl

(local Base (include "src.world.base"))

(local TILE-HERBE-REF  13)
(local TILES-HERBE     [13 14 15])

(local TILE-ROCHE-REF  31)
(local TILES-ROCHE     [29 30 31])

(local TILE-CHAOS-REF  63)
(local TILES-CHAOS     [61 62 63])

(local TILE-SABLE-REF  45)
(local TILES-SABLE     [45 46])

(local TILES-SPAWN-ARBRE  [13 14 15])
(local TILES-SPAWN-ROCHER [29 30 31])
(local TILES-SPAWN-FER [61 62 63])

(local PROB-ARBRE  0.08)
(local PROB-ROCHER 0.06)
(local PROB-FER 0.04)

(local MAP-W 240)
(local MAP-H 136)

(local BASE-TX 200)
(local BASE-TY 100)

(fn contient? [tab val]
  (var found false)
  (each [_ v (ipairs tab)]
    (when (= v val) (set found true)))
  found)

(fn init [objects-module Arbre Rocher item]
  ;; Instanciation de la base en premier
  (local base (Base.new BASE-TX BASE-TY))
  (objects-module.add base)


  (var nb-arbres  0)
  (var nb-rochers 0)
  (var nb-fer 0)
  (var nb-herbe   0)

  (for [tx 0 (- MAP-W 1)]
    (for [ty 0 (- MAP-H 1)]
      (let [tile (mget tx ty)]

        ;; Variations de terrain
        (when (= tile TILE-HERBE-REF)
          (mset tx ty (. TILES-HERBE (math.random 1 (length TILES-HERBE)))))
        (when (= tile TILE-ROCHE-REF)
          (mset tx ty (. TILES-ROCHE (math.random 1 (length TILES-ROCHE)))))
        (when (= tile TILE-CHAOS-REF)
          (mset tx ty (. TILES-CHAOS (math.random 1 (length TILES-CHAOS)))))
        (when (= tile TILE-SABLE-REF)
          (mset tx ty (. TILES-SABLE (math.random 1 (length TILES-SABLE)))))

        ;; Compte herbe pour debug
        (when (contient? TILES-HERBE (mget tx ty))
          (set nb-herbe (+ nb-herbe 1)))

        ;; Skip spawn si dans la zone d'exclusion de la base
        (when (not (base:in-exclusion-zone? tx ty))

        ;; Spawn arbres sur herbe
        (var arbre-spawne false)
        (let [t (mget tx ty)]
          (when (and (contient? TILES-SPAWN-ARBRE t)
                     (< (math.random) PROB-ARBRE))
            (objects-module.add (Arbre.new (* tx 8) (* ty 8) item))
            (set nb-arbres (+ nb-arbres 1))
            (set arbre-spawne true)))

        ;; Spawn rochers sur roche
        (when (not arbre-spawne)
          (let [t (mget tx ty)]
            (when (and (contient? TILES-SPAWN-ROCHER t)
                       (< (math.random) PROB-ROCHER))
              (objects-module.add (Rocher.new (* tx 8) (* ty 8) item))
              (set nb-rochers (+ nb-rochers 1))))))

        ;; Spawn fer sur nether
        (when (not arbre-spawne)
          (let [t (mget tx ty)]
            (when (and (contient? TILES-SPAWN-FER t)
                       (< (math.random) PROB-FER))
              (objects-module.add (Rocherfer.new (* tx 8) (* ty 8) item))
              (set nb-fer (+ nb-fer 1))))))))

  (trace (.. "Tuiles herbe trouvees: " nb-herbe))
  (trace (.. "Arbres:  " nb-arbres))
  (trace (.. "Rochers: " nb-rochers)))

{:init init}