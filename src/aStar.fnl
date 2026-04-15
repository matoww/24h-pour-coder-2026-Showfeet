;; title: Algo A* Pathfinding
;; author: Matisse
;; desc: Algo de pathfinding (A* car plus opti)
;; script: fennel

;; Calcule la distance de Manhattan
(fn heuristic [a b]
  (+ (math.abs (- a.x b.x))
     (math.abs (- a.y b.y))))

;; Vérifie si deux nœuds sont à la même position
(fn same-pos? [a b]
  (and (= a.x b.x) (= a.y b.y)))

;; Vérifie si une case est traversable (Tile 0 = vide)
(fn walkable? [x y]
  (let [tile (mget x y)]
    (= tile 0)))

;; Reconstruit le chemin en remontant les parents
(fn reconstruct-path [node]
  (let [path []]
    (var curr node)
    (while curr
      (table.insert path 1 {:x curr.x :y curr.y})
      (set curr curr.parent))
    path))

;; Fonction A* principale
(fn a-star [depart destination]
  (let [case-a-visite [{:x depart.x :y depart.y :g 0 :h (heuristic depart destination) :f 0}]
        case-visitee {}]
    (var final-path nil) ; On stockera le résultat ici

    (while (and (> (length open-list) 0) (not final-path))
      ;; 1. Trouver l'index du nœud avec le F le plus bas
      (var current-idx 1)
      (for [i 2 (length open-list)]
        (if (< (. open-list i :f) (. open-list current-idx :f))
            (set current-idx i)))
      
      (let [current (table.remove open-list current-idx)]
        
        ;; SI ARRIVÉE : on génère le chemin et la boucle s'arrêtera au prochain test
        (if (same-pos? current destination)
            (set final-path (reconstruct-path current))
            
            ;; SINON : on continue l'exploration
            (do
              (tset closed-list (.. current.x ":" current.y) true)
              (each [_ [dx dy] (ipairs [[0 -1] [0 1] [-1 0] [1 0]])]
                (let [nx (+ current.x dx)
                      ny (+ current.y dy)]
                  (if (and (walkable? nx ny) 
                           (not (. closed-list (.. nx ":" ny))))
                      (let [neighbor {:x nx :y ny 
                                      :g (+ current.g 1) 
                                      :h (heuristic {:x nx :y ny} destination)
                                      :parent current}]
                        (set neighbor.f (+ neighbor.g neighbor.h))
                        
                        (var skip? false)
                        (each [_ node (ipairs open-list)]
                          (if (and (same-pos? node neighbor) (<= node.g neighbor.g))
                              (set skip? true)))
                        
                        (if (not skip?)
                            (table.insert open-list neighbor)))))))))
    final-path)))