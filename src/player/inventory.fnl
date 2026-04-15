;; inventory.fnl — stock de ressources du joueur

(fn make-inventory []
  {:stacks {}})

(fn quantite [inv ressource]
  (or (. inv.stacks ressource.id) 0))

(fn add [inv ressource count]
  (let [actuel (quantite inv ressource)
        espace (- ressource.max-stack actuel)
        ajoute (math.max 0 (math.min count espace))]
    (tset inv.stacks ressource.id (+ actuel ajoute))
    ajoute))

(fn retirer [inv ressource count]
  (let [actuel (quantite inv ressource)]
    (if (>= actuel count)
        (do (tset inv.stacks ressource.id (- actuel count)) true)
        false)))

{:make-inventory make-inventory
 :quantite       quantite
 :add            add
 :retirer        retirer}