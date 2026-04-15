;; inventory.fnl
;; Gère le stock de ressources du joueur et son affichage en HUD.

(local SLOT-W   20)
(local SLOT-H   20)
(local SLOT-GAP  2)
(local PADDING   3)

;; ------------------------------------------------------------------
;; CRÉATION
;; ------------------------------------------------------------------
(fn make-inventory []
  "Retourne un inventaire vide."
  {:stacks {}})   ;; { item-id (keyword) -> quantite (number) }

;; ------------------------------------------------------------------
;; LECTURE
;; ------------------------------------------------------------------
(fn quantite [inv ressource]
  "Retourne le nombre d'unités de cette ressource dans l'inventaire."
  (or (. inv.stacks ressource.id) 0))

;; ------------------------------------------------------------------
;; ÉCRITURE
;; ------------------------------------------------------------------
(fn add [inv ressource count]
  "Ajoute 'count' unités. Plafonne à max-stack. Retourne la quantité ajoutée."
  (let [actuel  (quantite inv ressource)
        espace  (- ressource.max-stack actuel)
        ajoute  (math.max 0 (math.min count espace))]
    (tset inv.stacks ressource.id (+ actuel ajoute))
    ajoute))

(fn retirer [inv ressource count]
  "Retire 'count' unités si le stock le permet. Retourne true si succès."
  (let [actuel (quantite inv ressource)]
    (if (>= actuel count)
        (do (tset inv.stacks ressource.id (- actuel count)) true)
        false)))

;; ------------------------------------------------------------------
;; EXPORTS
;; ------------------------------------------------------------------
{:make-inventory make-inventory
 :quantite       quantite
 :add            add
 :retirer        retirer
 :draw           draw}