;; constructible.fnl — Classe de base pour tous les bâtiments

(local Construisible {})
(set Construisible.__index Construisible)

;; -----------------------------------------------------------------
;; new — crée un bâtiment en construction.
;;   x, y             : position monde (pixels)
;;   sprite-idle      : id sprite quand construit
;;   sprite-chantier  : id sprite quand en chantier (facultatif)
;;   hp-max           : points de vie max
;;   temps-construire : frames avant fin de chantier
;; -----------------------------------------------------------------
(fn Construisible.new [x y sprite-idle sprite-chantier hp-max temps-construire]
  (setmetatable
    {:x                x
     :y                y
     :sprite-idle      sprite-idle
     :sprite-chantier  (or sprite-chantier sprite-idle)
     :is-build         false
     :build-timer      temps-construire
     :temps-construire temps-construire
     :hp               hp-max
     :hp-max           hp-max
     :constructeur     nil   ; civil qui construit (peut être nil)
     :assigne          nil   ; civil affecté une fois construit
     :type             :generic}
    Construisible))

;; -----------------------------------------------------------------
;; update-construction — fait avancer le chantier.
;; Un civil assigné au chantier fait avancer plus vite.
;; -----------------------------------------------------------------
(fn Construisible.update-construction [self]
  (when (not self.is-build)
    (let [vitesse (if (and self.constructeur
                           (= self.constructeur.state :at-work))
                      2
                      1)]
      (set self.build-timer (- self.build-timer vitesse))
      (when (<= self.build-timer 0)
        (set self.is-build true)
        (set self.build-timer 0)))))

;; -----------------------------------------------------------------
;; progression — float 0..1 pour afficher une barre de chantier
;; -----------------------------------------------------------------
(fn Construisible.progression [self]
  (if self.is-build
      1
      (- 1 (/ self.build-timer self.temps-construire))))

;; -----------------------------------------------------------------
;; draw — dessine chantier ou bâtiment + barre de progression/vie
;; -----------------------------------------------------------------
(fn Construisible.draw [self cam-x cam-y]
  (let [sx (- self.x cam-x)
        sy (- self.y cam-y)]
    (when (and (> sx -16) (< sx 248) (> sy -16) (< sy 144))
      (if self.is-build
          (spr self.sprite-idle sx sy 0)
          (do
            (spr self.sprite-chantier sx sy 0)
            (let [w (math.floor (* 8 (self:progression)))]
              (rect sx (+ sy 9) 8 1 0)
              (rect sx (+ sy 9) w 1 11))))
      (when (and self.is-build (< self.hp self.hp-max))
        (let [ratio (/ self.hp self.hp-max)
              w     (math.floor (* 8 ratio))
              couleur (if (> ratio 0.5) 11 (if (> ratio 0.2) 4 6))]
          (rect sx (+ sy 9) 8 1 0)
          (rect sx (+ sy 9) w 1 couleur))))))

;; -----------------------------------------------------------------
;; reparation / degats
;; -----------------------------------------------------------------
(fn Construisible.reparation [self amount]
  (when self.is-build
    (set self.hp (math.min self.hp-max (+ self.hp amount)))))

(fn Construisible.degats [self amount]
  (set self.hp (math.max 0 (- self.hp amount)))
  (<= self.hp 0))

;; -----------------------------------------------------------------
;; utilitaires géométrie
;; -----------------------------------------------------------------
(fn Construisible.distance-a [self px py]
  (let [dx (- (+ self.x 4) px)
        dy (- (+ self.y 4) py)]
    (math.sqrt (+ (* dx dx) (* dy dy)))))

Construisible
