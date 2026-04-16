;; ranged_mob.fnl
(local projectile (include "src.weapon.projectile"))

(local RangedMob {})
(set RangedMob.__index RangedMob)

(local TYPES {
  :sorcier {:hp 15 :speed 0.6 :sprite-idle 260 :weapon {:degats 4 :portee 15 :vitesse-projectile 3 :sprite-projectile 316}}
  :sorciere {:hp 12 :speed 0.8 :sprite-idle 275 :weapon {:degats 3 :portee 12 :vitesse-projectile 4 :sprite-projectile 317}}
})

(fn RangedMob.new [x y type-key]
  (let [config (. TYPES type-key)
        self (setmetatable {
          :x x :y y :hp config.hp :speed config.speed
          :sprite-idle config.sprite-idle :direction :down
          :weapon config.weapon :cooldown 0
        } RangedMob)]
    self))

(fn RangedMob.update [self player]
  (let [dist (math.sqrt (+ (^ (- player.x self.x) 2) (^ (- player.y self.y) 2)))]
    ;; Garde ses distances (s'arrête à 60 pixels)
    (if (> dist 60)
        (set self.x (+ self.x (if (> player.x self.x) self.speed (- self.speed))))
        ;; Tir de projectile [cite: 19, 28]
        (do
          (when (<= self.cooldown 0)
            (projectile.fire self self.weapon)
            (set self.cooldown 60))
          (set self.cooldown (- self.cooldown 1))))))

(fn RangedMob.draw [self cam-x cam-y]
  (spr self.sprite-idle (- self.x cam-x) (- self.y cam-y) 0 1))

{:new RangedMob.new :TYPES TYPES}