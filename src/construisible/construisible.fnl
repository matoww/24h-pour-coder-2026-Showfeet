(local construisible {})
(set construisible.__index construisible)
(fn construisible.new [x y sprite-idle hp  tempsConstruire constructeur]
  (setmetatable
    {:x           x
     :y           y
     :sprite-idle sprite-idle
     :is-build false
     :build-timer 0
     :hp hp
     :tempsConstruire tempsConstruire
     :constructeur constructeur
     :ressources {}}
    construisible))

(fn construisible.updateTempsConstruire [self deltaTime]
  (when not (self.is-build)
    (set self.tempsConstruire (- self.tempsConstruire deltaTime))
    (when (<= self.tempsConstruire 0)
        (set self.is-build true))))

(fn construisible.draw [self cam-x cam-y]
  (when self.is-build
    (spr self.sprite-idle (- self.x cam-x) (- self.y cam-y))))

(fn construisible.reparation [self amount]
  (when self.is-build
    (set self.hp (+ self.hp amount))))


construisible