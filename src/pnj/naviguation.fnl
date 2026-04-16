;; navigation.fnl — file de calcul A* (max N par frame)
(local astar (include "src.aStar"))

(local Navigation {:recalc-queue []})

(fn Navigation.queue-recalc [entite]
  "Ajoute une entité à la file si elle n'y est pas déjà"
  (var already false)
  (each [_ e (ipairs Navigation.recalc-queue)]
    (when (= e entite) (set already true)))
  (when (not already)
    (table.insert Navigation.recalc-queue entite)))

;; Traite jusqu'à ?n calculs A* par frame (défaut : 2).
;; Chaque entité peut définir self.nav-target pour cibler autre chose que le joueur.
(fn Navigation.process-queue [player ?n]
  (let [n (or ?n 2)]
    (for [_ 1 n]
      (when (> (length Navigation.recalc-queue) 0)
        (let [e      (table.remove Navigation.recalc-queue 1)
              target (or e.nav-target player)
              start  {:x (// e.x 8) :y (// e.y 8)}
              dest   {:x (// target.x 8) :y (// target.y 8)}]
          (set e.path    (astar.a-star start dest))
          (set e.path-idx 1))))))

Navigation
