;; buildings.fnl — Gestionnaire de bâtiments (logique pure).
;; Le menu est géré par src.menu ; ici on expose juste les opérations.

(local Habitat    (include "src.construisible.habitat"))
(local Defense    (include "src.construisible.defense"))
(local Extraction (include "src.construisible.extraction"))
(local inventory  (include "src.player.inventory"))
(local item       (include "src.item"))

(local Buildings {:list []})

;; -----------------------------------------------------------------
;; CATALOGUE des types constructibles.
;; -----------------------------------------------------------------
(local CATALOGUE
  [{:id :habitat    :nom "Habitat"    :mk Habitat.new    :cout Habitat.COUT    :sprite Habitat.SPRITE-IDLE}
   {:id :defense    :nom "Tourelle"   :mk Defense.new    :cout Defense.COUT    :sprite Defense.SPRITE-IDLE}
   {:id :extraction :nom "Extracteur" :mk Extraction.new :cout Extraction.COUT :sprite Extraction.SPRITE-IDLE}])

(set Buildings.CATALOGUE CATALOGUE)

;; -----------------------------------------------------------------
;; Coûts : lecture par id, vérification et paiement
;; -----------------------------------------------------------------
(fn ressource-par-id [id]
  (var trouve nil)
  (each [_ r (pairs item.RESSOURCES)]
    (when (= r.id id)
      (set trouve r)))
  trouve)

(fn Buildings.peut-payer? [inv cout]
  (var ok true)
  (each [id qte (pairs cout)]
    (let [r (ressource-par-id id)]
      (when (or (not r) (< (inventory.quantite inv r) qte))
        (set ok false))))
  ok)

(fn payer [inv cout]
  (each [id qte (pairs cout)]
    (let [r (ressource-par-id id)]
      (when r (inventory.retirer inv r qte)))))

;; -----------------------------------------------------------------
;; Placement d'un bâtiment à la position joueur (snappée sur grille).
;; Retourne le bâtiment créé ou nil si paiement impossible.
;; -----------------------------------------------------------------
(fn Buildings.placer [player type-info ?ressource]
  (if (not (Buildings.peut-payer? player.inventory type-info.cout))
      (do (trace (.. "Pas assez de ressources pour " type-info.nom))
          nil)
      (let [tx (// player.x 8)
            ty (// player.y 8)
            bx (* tx 8)
            by (* ty 8)
            batiment (if (= type-info.id :extraction)
                         (type-info.mk bx by (or ?ressource item.BOIS))
                         (type-info.mk bx by))]
        (payer player.inventory type-info.cout)
        (table.insert Buildings.list batiment)
        (trace (.. "Batiment pose: " type-info.nom " @ " bx "," by))
        batiment)))

;; -----------------------------------------------------------------
;; Update : chantier + comportement par type + retrait des détruits
;; -----------------------------------------------------------------
(fn Buildings.update [mobs]
  (for [i (length Buildings.list) 1 -1]
    (let [b (. Buildings.list i)]
      (if (= b.type :habitat)    (b:update)
          (= b.type :defense)    (b:update mobs)
          (= b.type :extraction) (b:update)
          (when b.update-construction
            (b:update-construction))))
    (let [b (. Buildings.list i)]
      (when (<= b.hp 0)
        (trace (.. "Batiment detruit: " (tostring b.type)))
        (when b.assigne
          (set b.assigne.batiment nil)
          (set b.assigne.state :idle))
        (when (and (= b.type :habitat) b.habitants)
          (each [_ h (ipairs b.habitants)]
            (set h.batiment nil)
            (set h.state :idle)))
        (table.remove Buildings.list i)))))

(fn Buildings.draw [cam-x cam-y]
  (each [_ b (ipairs Buildings.list)]
    (b:draw cam-x cam-y)))

;; -----------------------------------------------------------------
;; Recherche : plus proche, optionnellement filtré
;; -----------------------------------------------------------------
(fn Buildings.plus-proche [px py ?filter]
  (var meilleur nil)
  (var best-d   math.huge)
  (each [_ b (ipairs Buildings.list)]
    (when (or (not ?filter) (?filter b))
      (let [d (b:distance-a px py)]
        (when (< d best-d)
          (set meilleur b)
          (set best-d   d)))))
  meilleur)

(fn Buildings.a-besoin? [b]
  "true si le bâtiment peut accueillir un civil de plus."
  (if (= b.type :habitat)    (< (length b.habitants) b.limite)
      (= b.type :defense)    (= b.assigne nil)
      (= b.type :extraction) (= b.assigne nil)
      false))

;; -----------------------------------------------------------------
;; Assigne un civil précis au bâtiment libre le plus proche de LUI.
;; Retourne le type du bâtiment (string) ou nil si rien n'a marché.
;; -----------------------------------------------------------------
(fn Buildings.assigner-civil [civil Civil]
  ;; Libérer le bâtiment précédent si besoin
  (when civil.batiment
    (let [ancien civil.batiment]
      (if (= ancien.type :habitat)
          (when ancien.retirer-habitant
            (ancien:retirer-habitant civil))
          (when (= ancien.assigne civil)
            (set ancien.assigne nil)
            (set ancien.constructeur nil)))))
  (let [cible (Buildings.plus-proche civil.x civil.y Buildings.a-besoin?)]
    (when cible
      (Civil.assign-building civil cible)
      (if (= cible.type :habitat)
          (cible:ajouter-habitant civil)
          (do (set cible.assigne civil)
              (set cible.constructeur civil)))
      (tostring cible.type))))

;; -----------------------------------------------------------------
;; Collecte auto : si le joueur touche un extracteur avec du stock,
;; il récupère les ressources directement.
;; -----------------------------------------------------------------
(fn Buildings.auto-collecte [player]
  (each [_ b (ipairs Buildings.list)]
    (when (and (= b.type :extraction) (> b.stock 0))
      (let [d (b:distance-a (+ player.x 4) (+ player.y 4))]
        (when (< d 12)
          (b:collecter player.inventory))))))

(fn Buildings.cibles-pour-mobs []
  Buildings.list)

{:list                  Buildings.list
 :CATALOGUE             CATALOGUE
 :placer                Buildings.placer
 :peut-payer?           Buildings.peut-payer?
 :update                Buildings.update
 :draw                  Buildings.draw
 :plus-proche           Buildings.plus-proche
 :a-besoin?             Buildings.a-besoin?
 :assigner-civil        Buildings.assigner-civil
 :auto-collecte         Buildings.auto-collecte
 :cibles-pour-mobs      Buildings.cibles-pour-mobs}
