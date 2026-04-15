;; title: A* Pathfinding
;; author: Showfeet
;; script: fennel

(var path nil)


(fn heuristic [a b]
  (+ (math.abs (- a.x b.x)) (math.abs (- a.y b.y))))

(fn same-pos? [a b]
  (and (= a.x b.x) (= a.y b.y)))

(fn walkable? [x y]
  (let [tile (mget x y)]
    (not= tile 0)))

(fn reconstruct-path [node]
  (let [p []]
    (var curr node)
    (while curr
      (table.insert p 1 {:x curr.x :y curr.y})
      (set curr curr.parent))
    p))

(fn a-star [depart destination]

  (let [case-a-visite [{:x depart.x :y depart.y :g 0 :h (heuristic depart destination) :f 0}]
        case-visitee {}]
    (var final-path nil)
    (var iterations 0)

    (while (and (> (length case-a-visite) 0) (not final-path))
      (set iterations (+ iterations 1))

      (if (> iterations 500) (do (trace "STOP: Trop d'iterations !") (lua "break")))

      (var current-idx 1)
      (for [i 2 (length case-a-visite)]
        (if (< (. case-a-visite i :f) (. case-a-visite current-idx :f))
            (set current-idx i)))

      (let [current (table.remove case-a-visite current-idx)]

        (if (same-pos? current destination)
            (do
              (set final-path (reconstruct-path current)))

            (do
              (tset case-visitee (.. current.x ":" current.y) true)
              (each [_ [dx dy] (ipairs [[0 -1] [0 1] [-1 0] [1 0]])]
                (let [nx (+ current.x dx)
                      ny (+ current.y dy)]

                  (if (not (walkable? nx ny))
                      nil

                      (. case-visitee (.. nx ":" ny))
                      nil

                      (let [neighbor {:x nx :y ny
                                      :g (+ current.g 1)
                                      :h (heuristic {:x nx :y ny} destination)
                                      :parent current}]
                        (set neighbor.f (+ neighbor.g neighbor.h))

                        (var skip? false)
                        (each [_ node (ipairs case-a-visite)]
                          (if (and (same-pos? node neighbor) (<= node.g neighbor.g))
                              (set skip? true)))

                        (if (not skip?)
                            (table.insert case-a-visite neighbor))))))))))

    (if (not final-path) (trace "ECHEC: Liste vide, aucun chemin trouvé."))
    final-path))
