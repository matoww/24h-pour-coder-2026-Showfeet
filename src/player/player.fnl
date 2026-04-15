;; player/player.fnl

(local Agressif (include "src.pnj.agressif"))

(local player {})
(set player.__index player)
(setmetatable player {:__index Agressif})

(fn player.new [x y]
  (let [self (Agressif.new x y 2 256 257 100 2)]
    (set self.max-hp          100)
    (set self.equipped-weapon nil)
    (set self.inventory       {:stacks {}})
    (set self.direction       :right)
    (set self.attack-state    {:active false :frame 0 :weapon nil})
    (setmetatable self player)))

(fn player.update [self]
  (var dx 0) (var dy 0)
  (if (btn 0) (set dy -1))
  (if (btn 1) (set dy  1))
  (if (btn 2) (set dx -1))
  (if (btn 3) (set dx  1))
  (when (not self.attack-state.active)
    (if (< dx 0) (do (set self.direction :left)  (set self.flip 1))
        (> dx 0) (do (set self.direction :right) (set self.flip 0))
        (< dy 0) (set self.direction :up)
        (> dy 0) (set self.direction :down)))
  (set self.is-moving (or (not= dx 0) (not= dy 0)))
  (var speed self.speed)
  (when (and (not= dx 0) (not= dy 0))
    (set speed (* speed 0.707)))
  (set self.x (+ self.x (* dx speed)))
  (set self.y (+ self.y (* dy speed))))

(fn player.draw [self screen-w screen-h]
  (let [px  (- (/ screen-w 2) 4)
        py  (- (/ screen-h 2) 4)
        anim-frame (= (% (// (time) 150) 2) 0)
        sid (if (= self.direction :up)
                (if (and self.is-moving anim-frame) 293 292)
                (if (= self.direction :down)
                    (if (and self.is-moving anim-frame) 291 290)
                    ;; :left et :right — flip géré par self.flip
                    (if (and self.is-moving anim-frame) 289 288)))]
    (spr sid px py 0 1 self.flip)))

player