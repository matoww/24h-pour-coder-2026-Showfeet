;; anime.fnl — entité animée de base

(local Anime {})
(set Anime.__index Anime)

(fn Anime.new [x y speed sprite-idle sprite-walk]
  (setmetatable
    {:x           x
     :y           y
     :speed       speed
     :sprite-idle sprite-idle
     :sprite-walk sprite-walk
     :radius      4
     :flip        0
     :is-moving   false}
    Anime))

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