;; navigation.fnl
(local astar (include "src.aStar"))

(local Navigation {:recalc-queue []})

(fn Navigation.queue-recalc [entite]
  "Ajoute une entité à la file si elle n'y est pas déjà"
  (var already false)
  (each [_ e (ipairs Navigation.recalc-queue)]
    (when (= e entite) (set already true)))
  (when (not already)
    (table.insert Navigation.recalc-queue entite)))

(fn Navigation.process-queue [player]
  "Traite UN SEUL calcul par frame pour ne pas faire ramer le jeu"
  (when (> (length Navigation.recalc-queue) 0)
    (let [e (table.remove Navigation.recalc-queue 1)
          start {:x (// e.x 8) :y (// e.y 8)}
          dest  {:x (// player.x 8) :y (// player.y 8)}]
      (set e.path (astar.a-star start dest))
      (set e.path-idx 1))))

Navigation