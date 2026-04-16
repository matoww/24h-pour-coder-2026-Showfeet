;; defense.fnl — Tourelle qui tire sur les ennemis à proximité

(local Construisible (include "src.construisible.construisible"))
(local projectile    (include "src.weapon.projectile"))

(local Defense {})
(set Defense.__index Defense)
(setmetatable Defense {:__index Construisible})

;; --- CONFIG ---
(local SPRITE-IDLE      224)
(local SPRITE-CHANTIER  225)
(local HP-MAX           150)
(local TEMPS-CONSTRUIRE 600)  ; ~10s à 60fps

;; Stats de tir
(local PORTEE-TILES       8)   ; en tuiles (= 64 px)
(local COOLDOWN-FRAMES    45)  ; ~0.75s entre deux tirs
(local DEGATS             6)
(local VITESSE-PROJECTILE 12)  ; quasi-instantané
(local SPRITE-PROJECTILE  315)

;; Coût
(local COUT {:bois 2 :pierre 3 :fer 1})

;; Directions supportées (les seules gérées par projectile.DIR-MAP)
(local DIRS [:right :left :up :down])

;; -----------------------------------------------------------------
;; new
;; -----------------------------------------------------------------
(fn Defense.new [x y]
  (let [self (Construisible.new x y SPRITE-IDLE SPRITE-CHANTIER
                                HP-MAX TEMPS-CONSTRUIRE)]
    (setmetatable self Defense)
    (set self.type          :defense)
    (set self.portee-px     (* PORTEE-TILES 8))
    (set self.cooldown      0)
    (set self.direction     :down)  ; maj par la cible
    (set self.weapon        {:degats             DEGATS
                             :portee             PORTEE-TILES
                             :vitesse-projectile VITESSE-PROJECTILE
                             :sprite-projectile  SPRITE-PROJECTILE})
    self))

;; -----------------------------------------------------------------
;; choisir-direction — retourne la direction cardinale la + proche
;; du vecteur (dx, dy). projectile.fire ne gère que ces 4 directions.
;; -----------------------------------------------------------------
(fn choisir-direction [dx dy]
  (if (> (math.abs dx) (math.abs dy))
      (if (> dx 0) :right :left)
      (if (> dy 0) :down  :up)))

;; -----------------------------------------------------------------
;; trouver-cible — renvoie l'ennemi le plus proche dans la portée,
;; ou nil si aucun.
;; -----------------------------------------------------------------
(fn Defense.trouver-cible [self mobs]
  (var meilleur nil)
  (var best-d   math.huge)
  (each [_ m (ipairs mobs)]
    (when (and m (> (or m.hp 0) 0))
      (let [d (self:distance-a (+ m.x 4) (+ m.y 4))]
        (when (and (<= d self.portee-px) (< d best-d))
          (set meilleur m)
          (set best-d   d)))))
  meilleur)

;; -----------------------------------------------------------------
;; tirer — sur la cible donnée
;; -----------------------------------------------------------------
(fn Defense.tirer [self cible]
  (let [dx (- cible.x self.x)
        dy (- cible.y self.y)]
    (set self.direction (choisir-direction dx dy))
    (projectile.fire self self.weapon)
    (set self.cooldown COOLDOWN-FRAMES)))

;; -----------------------------------------------------------------
;; update — chantier puis logique de tir
;; -----------------------------------------------------------------
(fn Defense.update [self mobs]
  (Construisible.update-construction self)
  (when self.is-build
    (when (> self.cooldown 0)
      (set self.cooldown (- self.cooldown 1)))
    (when (<= self.cooldown 0)
      (let [cible (self:trouver-cible mobs)]
        (when cible
          (self:tirer cible))))))

{:new  Defense.new
 :COUT COUT
 :SPRITE-IDLE SPRITE-IDLE}
