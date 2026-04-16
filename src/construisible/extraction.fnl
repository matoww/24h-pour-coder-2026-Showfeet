;; extraction.fnl — Bâtiment qui produit une ressource régulièrement.
;; Accéléré par la stat "recolte" du civil assigné.

(local Construisible (include "src.construisible.construisible"))
(local item          (include "src.item"))
(local inventory     (include "src.player.inventory"))

(local Extraction {})
(set Extraction.__index Extraction)
(setmetatable Extraction {:__index Construisible})

;; --- CONFIG ---
(local SPRITE-IDLE      226)
(local HP-MAX           120)
(local TEMPS-CONSTRUIRE 450)  ; ~7.5s

;; Production : 1 ressource toutes les 10s par défaut (sans civil).
;; Avec un civil stat recolte=100 -> ~2x plus rapide (5s).
(local INTERVAL-BASE 600)

;; Coût
(local COUT {:bois 3})

;; -----------------------------------------------------------------
;; new
;;   ressource : { :id ... :max-stack ... } (voir src.item.RESSOURCES)
;; -----------------------------------------------------------------
(fn Extraction.new [x y ressource]
  (let [self (Construisible.new x y SPRITE-IDLE SPRITE-CHANTIER
                                HP-MAX TEMPS-CONSTRUIRE)]
    (setmetatable self Extraction)
    (set self.type           :extraction)
    (set self.ressource      ressource)
    (set self.prod-timer     INTERVAL-BASE)
    (set self.interval-base  INTERVAL-BASE)
    (set self.stock          0)           ; ressources accumulées
    (set self.stock-max      20)
    self))

;; -----------------------------------------------------------------
;; interval-courant — interval ajusté par la stat du civil assigné
;;   base=600. civil.recolte=50 -> mult 1.5 -> 400f. recolte=100 -> 2x -> 300f.
;; -----------------------------------------------------------------
(fn Extraction.interval-courant [self]
  (if (and self.assigne self.assigne.recolte)
      (let [stat (math.max 1 (math.min 100 self.assigne.recolte))
            mult (+ 1 (/ stat 100))]  ; 1.01 .. 2.00
        (math.floor (/ self.interval-base mult)))
      self.interval-base))

;; -----------------------------------------------------------------
;; update — chantier puis production si :at-work
;; -----------------------------------------------------------------
(fn Extraction.update [self]
  (Construisible.update-construction self)
  (when (and self.is-build (< self.stock self.stock-max))
    (set self.prod-timer (- self.prod-timer 1))
    (when (<= self.prod-timer 0)
      (set self.stock (+ self.stock 1))
      (set self.prod-timer (self:interval-courant)))))

;; -----------------------------------------------------------------
;; collecter — le joueur vient chercher le stock.
;; Retourne le nombre réellement pris (respecte la capacité d'inventaire).
;; -----------------------------------------------------------------
(fn Extraction.collecter [self player-inventory]
  (if (or (<= self.stock 0) (= self.ressource nil))
      0
      (let [pris (inventory.add player-inventory self.ressource self.stock)]
        (set self.stock (- self.stock pris))
        pris)))

;; -----------------------------------------------------------------
;; draw — override pour afficher aussi le stock au-dessus
;; -----------------------------------------------------------------
(fn Extraction.draw [self cam-x cam-y]
  (Construisible.draw self cam-x cam-y)
  (when (and self.is-build (> self.stock 0))
    (let [sx (- self.x cam-x)
          sy (- self.y cam-y)]
      (when (and (> sx -16) (< sx 248) (> sy -8) (< sy 144))
        (print self.stock sx (- sy 6) 12 false 1)))))

{:new  Extraction.new
 :COUT COUT
 :SPRITE-IDLE SPRITE-IDLE}
