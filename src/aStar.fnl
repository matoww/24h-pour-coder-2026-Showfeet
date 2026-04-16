;; title: A* Pathfinding — 8 directions + lissage
;; author: Showfeet
;; script: fennel

;; 8 directions : [dx dy coût*10]  (14 ≈ √2*10 pour les diagonales)
(local DIRS
  [[0 -1 10] [0 1 10] [-1 0 10] [1 0 10]
   [-1 -1 14] [1 -1 14] [-1 1 14] [1 1 14]])

;; Heuristique octile — admissible pour 8 directions
(fn heuristic [a b]
  (let [dx (math.abs (- a.x b.x))
        dy (math.abs (- a.y b.y))
        mn (math.min dx dy)
        mx (math.max dx dy)]
    (+ (* 14 mn) (* 10 (- mx mn)))))

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

;; Vérification de ligne de vue (Bresenham) entre deux cases
(fn los? [x1 y1 x2 y2]
  (let [dx (math.abs (- x2 x1))
        dy (math.abs (- y2 y1))
        sx (if (< x1 x2) 1 -1)
        sy (if (< y1 y2) 1 -1)]
    (var cx x1) (var cy y1)
    (var err (- dx dy))
    (var clear true)
    (while (and clear (or (not= cx x2) (not= cy y2)))
      (when (not (walkable? cx cy))
        (set clear false))
      (let [e2 (* 2 err)]
        (when (> e2 (- dy))
          (set err (- err dy))
          (set cx (+ cx sx)))
        (when (< e2 dx)
          (set err (+ err dx))
          (set cy (+ cy sy)))))
    clear))

;; Lissage de chemin : supprime les waypoints intermédiaires quand la LdV est dégagée
(fn smooth-path [path]
  (if (or (not path) (<= (length path) 2))
      path
      (let [smoothed [(. path 1)]]
        (var i 1)
        (while (< i (length path))
          (var j (length path))
          (var jumped false)
          (while (and (> j (+ i 1)) (not jumped))
            (let [a (. path i)
                  b (. path j)]
              (if (los? a.x a.y b.x b.y)
                  (do
                    (table.insert smoothed b)
                    (set i j)
                    (set jumped true))
                  (set j (- j 1)))))
          (when (not jumped)
            (set i (+ i 1))
            (when (<= i (length path))
              (table.insert smoothed (. path i)))))
        smoothed)))

(fn a-star [depart destination]
  (let [case-a-visite [{:x depart.x :y depart.y
                        :g 0
                        :h (heuristic depart destination)
                        :f (heuristic depart destination)
                        :parent nil}]
        case-visitee {}]
    (var final-path nil)
    (var iterations 0)

    (while (and (> (length case-a-visite) 0) (not final-path))
      (set iterations (+ iterations 1))
      (when (> iterations 1000)
        (lua "break"))

      ;; Trouve le nœud avec le f minimal
      (var best-idx 1)
      (for [i 2 (length case-a-visite)]
        (let [ci (. case-a-visite i)
              cb (. case-a-visite best-idx)]
          (when (< ci.f cb.f)
            (set best-idx i))))

      (let [current (table.remove case-a-visite best-idx)]
        (if (same-pos? current destination)
            (set final-path (smooth-path (reconstruct-path current)))

            (do
              (tset case-visitee (.. current.x ":" current.y) true)
              (each [_ dir (ipairs DIRS)]
                (let [dx   (. dir 1)
                      dy   (. dir 2)
                      cost (. dir 3)
                      nx   (+ current.x dx)
                      ny   (+ current.y dy)]
                  (when (and
                          (walkable? nx ny)
                          (not (. case-visitee (.. nx ":" ny)))
                          ;; Diagonales : les deux cardinales adjacentes doivent être libres
                          (or (= cost 10)
                              (and (walkable? (+ current.x dx) current.y)
                                   (walkable? current.x (+ current.y dy)))))
                    (let [g (+ current.g cost)
                          h (heuristic {:x nx :y ny} destination)
                          f (+ g h)
                          neighbor {:x nx :y ny :g g :h h :f f :parent current}]
                      (var skip? false)
                      (each [_ node (ipairs case-a-visite)]
                        (when (and (same-pos? node neighbor) (<= node.f f))
                          (set skip? true)))
                      (when (not skip?)
                        (table.insert case-a-visite neighbor))))))))))

    final-path))

{: a-star : heuristic : walkable? : same-pos? : los?}
