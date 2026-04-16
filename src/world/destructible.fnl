(local Destructible {})
(set Destructible.__index Destructible)

(fn Destructible.new [x y sprite-id hp loot sw sh]
  (setmetatable
    {:x         x
     :y         y
     :sprite-id sprite-id
     :hp        hp
     :max-hp    hp
     :loot      loot
     :alive     true
     :flash     0
     :sprite-w  (or sw 1)
     :sprite-h  (or sh 1)}
    Destructible))

(fn Destructible.update [self]
  (when (> self.flash 0)
    (set self.flash (- self.flash 1))))

(fn Destructible.hit [self degats]
  (when self.alive
    (set self.hp    (math.max 0 (- self.hp degats)))
    (set self.flash 6)
    (when (<= self.hp 0)
      (set self.alive false)))
  (not self.alive))

(fn Destructible.reset [self]
  (set self.alive true)
  (set self.hp    self.max-hp)
  (set self.flash 0))

(fn Destructible.collect-loot [self]
  (let [drops []]
    (each [_ entry (ipairs self.loot)]
      (let [n (+ entry.min (math.random 0 (- entry.max entry.min)))]
        (when (> n 0)
          (table.insert drops {:ressource entry.ressource :count n}))))
    drops))

(fn Destructible.draw [self cam-x cam-y]
  (when self.alive
    (let [sx (- self.x cam-x)
          sy (- self.y cam-y)
          pw (* self.sprite-w 8)]
      (when (or (= self.flash 0) (= (% self.flash 2) 0))
        (spr self.sprite-id sx sy 0 1 0 0 self.sprite-w self.sprite-h))
      (when (< self.hp self.max-hp)
        (let [fw (math.floor (* pw (/ self.hp self.max-hp)))]
          (rect sx (- sy 3) pw 2 0)
          (rect sx (- sy 3) fw 2 6))))))

Destructible