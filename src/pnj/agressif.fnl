;; agressif.fnl — entité animée avec HP et dégâts
;; Hérite de Anime. Override ia() pour la chasse/attaque.

(local Anime (include "src.pnj.anime"))

(local Agressif {})
(set Agressif.__index Agressif)
(setmetatable Agressif {:__index Anime})

(fn Agressif.new [x y speed sprite-idle sprite-walk hp damage]
  (let [self (Anime.new x y speed sprite-idle sprite-walk)]
    (set self.hp     hp)
    (set self.damage damage)
    (set self.target nil)   ; table {:x :y} ou entité à chasser
    (setmetatable self Agressif)))

;; -----------------------------------------------------------------
;; ia() — surchargée par les sous-classes (zombie, boss, etc.)
;; Exemple : pointer self.destination vers self.target chaque frame.
;; -----------------------------------------------------------------
(fn Agressif.ia [self ...]
  ;; Comportement de base : se diriger vers self.target s'il existe.
  ;; Le recalcul A* est limité par le cooldown de Anime (PATH-COOLDOWN frames).
  (when self.target
    (set self.destination {:x self.target.x :y self.target.y})))

;; update — délègue à Anime.update (appelle self:ia puis bouge)
(fn Agressif.update [self ...]
  (Anime.update self ...))

;; draw — appelle Anime.draw avec coords caméra
(fn Agressif.draw [self cam-x cam-y]
  (Anime.draw self (- self.x cam-x) (- self.y cam-y)))

Agressif
