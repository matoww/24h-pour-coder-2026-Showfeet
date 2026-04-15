;; anime.fnl — entité animée de base
;; Contient : dessin, mouvement le long d'un chemin A*, cooldown de recalcul, ia() surchargeable

(local astar (include "src.aStar"))

(local Anime {})
(set Anime.__index Anime)

;; Nombre de frames entre deux recalculs A* autorisés
(local PATH-COOLDOWN 60)

(fn Anime.new [x y speed sprite-idle sprite-walk]
  (setmetatable
    {:x              x
     :y              y
     :speed          speed
     :sprite-idle    sprite-idle
     :sprite-walk    sprite-walk
     :radius         4
     :flip           0
     :is-moving      false
     :destination    nil   ; table {:x :y} en coordonnées pixel
     :path           nil   ; liste de cases [{:x :y} ...]
     :path-idx       1
     :path-cooldown  0}    ; frames restantes avant de pouvoir recalculer
    Anime))

;; -----------------------------------------------------------------
;; Méthode IA — à surcharger dans les sous-classes.
;; Par défaut : ne fait rien.
;; Doit mettre à jour self.destination si le PNJ veut aller quelque part.
;; -----------------------------------------------------------------
(fn Anime.ia [self]
  nil)

;; -----------------------------------------------------------------
;; Demande un chemin vers self.destination si :
;;   • self.destination est défini
;;   • on n'a pas déjà un chemin valide
;;   • le cooldown est écoulé
;; -----------------------------------------------------------------
(fn Anime.request-path [self]
  (when (and self.destination
             (not self.path)
             (<= self.path-cooldown 0))
    (let [start {:x (// self.x 8) :y (// self.y 8)}
          dest  {:x (// self.destination.x 8) :y (// self.destination.y 8)}]
      (set self.path     (astar.a-star start dest))
      (set self.path-idx 1)
      ;; Remet le cooldown même si A* a échoué (évite de respammer)
      (set self.path-cooldown PATH-COOLDOWN))))

;; -----------------------------------------------------------------
;; Avance d'un pas le long du chemin courant.
;; Retourne true si on est arrivé à destination, false sinon.
;; -----------------------------------------------------------------
(fn Anime.move-along-path [self]
  (if (and self.path (. self.path self.path-idx))
      (let [target (. self.path self.path-idx)
            tx     (* target.x 8)
            ty     (* target.y 8)
            dx     (- tx self.x)
            dy     (- ty self.y)
            dist   (math.sqrt (+ (* dx dx) (* dy dy)))]
        (if (> dist 1)
            (do
              (set self.is-moving true)
              (set self.x (+ self.x (* (/ dx dist) self.speed)))
              (set self.y (+ self.y (* (/ dy dist) self.speed)))
              (set self.flip (if (< dx 0) 1 0))
              false)   ; pas encore arrivé à cette case
            (do
              (set self.path-idx (+ self.path-idx 1))
              (if (> self.path-idx (length self.path))
                  (do
                    ;; Chemin terminé — on nettoie
                    (set self.path        nil)
                    (set self.destination nil)
                    (set self.is-moving   false)
                    true)   ; arrivé !
                  false)))) ; case atteinte, prochain step
      (do
        (set self.is-moving false)
        false)))

;; -----------------------------------------------------------------
;; update générique : décrémente cooldown, appelle ia(), puis bouge
;; -----------------------------------------------------------------
(fn Anime.update [self ...]
  ;; Cooldown de recalcul du chemin
  (when (> self.path-cooldown 0)
    (set self.path-cooldown (- self.path-cooldown 1)))

  ;; L'IA de ce PNJ (éventuellement surchargée) met à jour self.destination
  (self:ia ...)

  ;; Pathfinding : on demande un chemin si nécessaire
  (self:request-path)

  ;; Mouvement le long du chemin
  (self:move-along-path))

;; -----------------------------------------------------------------
;; Dessin
;; -----------------------------------------------------------------
(fn Anime.draw [self draw-x draw-y]
  (let [x   (or draw-x self.x)
        y   (or draw-y self.y)
        sid (if self.is-moving
                (if (= (% (// (time) 150) 2) 0)
                    self.sprite-idle
                    self.sprite-walk)
                self.sprite-idle)]
    (spr sid x y 0 1 self.flip)))

Anime
