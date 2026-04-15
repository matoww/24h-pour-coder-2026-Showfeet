;; player.fnl

(local sprite-idle 256)
(local sprite-walk 257)

(local player
  {:x               120
   :y                68
   :speed             2
   :radius            4
   :is-moving     false
   :flip              0
   :direction     :right   ;; :right :left :up :down
   :hp              100
   :max-hp          100
   :equipped-weapon nil
   :inventory       {:stacks {}}
   :attack-state    {:active false :frame 0 :weapon nil}})

(fn player.update [screen-w screen-h]
  (var dx 0) (var dy 0)
  (if (btn 0) (set dy -1))
  (if (btn 1) (set dy  1))
  (if (btn 2) (set dx -1))
  (if (btn 3) (set dx  1))

  ;; Direction et flip mis à jour seulement hors attaque
  (when (not player.attack-state.active)
    (if (< dx 0) (do (set player.direction :left)  (set player.flip 1))
        (> dx 0) (do (set player.direction :right) (set player.flip 0))
        (< dy 0) (set player.direction :up)
        (> dy 0) (set player.direction :down)))

  (set player.is-moving (or (not= dx 0) (not= dy 0)))
  (var speed player.speed)
  (when (and (not= dx 0) (not= dy 0))
    (set speed (* speed 0.707)))
  (set player.x (+ player.x (* dx speed)))
  (set player.y (+ player.y (* dy speed))))

(fn player.draw [screen-w screen-h]
  (let [px    (- (/ screen-w 2) 4)
        py    (- (/ screen-h 2) 4)
        frame (if (= (% (// (time) 150) 2) 0) sprite-idle sprite-walk)
        sid   (if player.is-moving frame sprite-idle)]
    (spr sid px py 0 1 player.flip)))

player