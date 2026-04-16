;; habitat.fnl — Bâtiment qui héberge des civils (régénération + limite)

(local Construisible (include "src.construisible.construisible"))

(local Habitat {})
(set Habitat.__index Habitat)
(setmetatable Habitat {:__index Construisible})

;; --- CONFIG ---
(local SPRITE-IDLE      238)
(local SPRITE-CHANTIER  239)
(local HP-MAX           200)
(local TEMPS-CONSTRUIRE 300)  ; ~5 secondes à 60fps
(local LIMITE-DEFAUT    4)
(local HEAL-INTERVAL    120)  ; soigne 1 hp / 2s à chaque habitant
(local HEAL-AMOUNT      1)

;; Coût de construction
(local COUT {:bois 5})

;; -----------------------------------------------------------------
;; new
;; -----------------------------------------------------------------
(fn Habitat.new [x y]
  (let [self (Construisible.new x y SPRITE-IDLE SPRITE-CHANTIER
                                HP-MAX TEMPS-CONSTRUIRE)]
    (setmetatable self Habitat)
    (set self.type        :habitat)
    (set self.habitants   [])
    (set self.limite      LIMITE-DEFAUT)
    (set self.heal-timer  HEAL-INTERVAL)
    self))

;; -----------------------------------------------------------------
;; ajouter-habitant — retourne true si accepté
;; -----------------------------------------------------------------
(fn Habitat.ajouter-habitant [self habitant]
  (if (and self.is-build (< (length self.habitants) self.limite))
      (do (table.insert self.habitants habitant) true)
      false))

;; -----------------------------------------------------------------
;; retirer-habitant
;; -----------------------------------------------------------------
(fn Habitat.retirer-habitant [self habitant]
  (for [i (length self.habitants) 1 -1]
    (when (= (. self.habitants i) habitant)
      (table.remove self.habitants i))))

;; -----------------------------------------------------------------
;; update — fait avancer la construction, soigne les habitants
;; -----------------------------------------------------------------
(fn Habitat.update [self]
  (Construisible.update-construction self)
  (when self.is-build
    (set self.heal-timer (- self.heal-timer 1))
    (when (<= self.heal-timer 0)
      (set self.heal-timer HEAL-INTERVAL)
      (each [_ h (ipairs self.habitants)]
        (when (and h.hp h.max-hp (< h.hp h.max-hp))
          (set h.hp (math.min h.max-hp (+ h.hp HEAL-AMOUNT))))))))

{:new  Habitat.new
 :COUT COUT
 :SPRITE-IDLE SPRITE-IDLE}
