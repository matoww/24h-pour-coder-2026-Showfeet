;; attack.fnl

(local DUREE     12)
(local NB-PHASES  3)

(local PHASES
  {:right [{:dx  8 :dy -8 :fl 0 :ro 0}
           {:dx 10 :dy  0 :fl 0 :ro 0}
           {:dx  8 :dy  8 :fl 2 :ro 0}]
   ;; -16 → -8, -18 → -10 : on compense les 8px de largeur du joueur
   :left  [{:dx  -8 :dy -8 :fl 1 :ro 0}
           {:dx -10 :dy  0 :fl 1 :ro 0}
           {:dx  -8 :dy  8 :fl 3 :ro 0}]
   ;; même correction sur dy : -16 → -8, -18 → -10
   :up    [{:dx -8 :dy  -8 :fl 0 :ro 0}
           {:dx  0 :dy -10 :fl 0 :ro 0}
           {:dx  8 :dy  -8 :fl 0 :ro 0}]
   :down  [{:dx  8 :dy  8 :fl 2 :ro 0}
           {:dx  0 :dy 10 :fl 2 :ro 0}
           {:dx -8 :dy  8 :fl 2 :ro 0}]})

(fn start [player weapon]
  (when (not player.attack-state.active)
    (set player.attack-state.active true)
    (set player.attack-state.frame  0)
    (set player.attack-state.weapon weapon)))

(fn update [player]
  (when player.attack-state.active
    (set player.attack-state.frame (+ player.attack-state.frame 1))
    (when (>= player.attack-state.frame DUREE)
      (set player.attack-state.active false)
      (set player.attack-state.frame  0)
      (set player.attack-state.weapon nil))))

(fn draw [player screen-w screen-h]
  (when (and player.attack-state.active
             (not= player.attack-state.weapon nil))
    (let [weapon player.attack-state.weapon
          phases (. PHASES player.direction)
          phase  (math.min (- NB-PHASES 1)
                           (// (* player.attack-state.frame NB-PHASES) DUREE))
          off    (. phases (+ phase 1))
          cx     (- (/ screen-w 2) 4)
          cy     (- (/ screen-h 2) 4)]
      (spr weapon.sprite-id
           (+ cx off.dx)
           (+ cy off.dy)
           0 1 off.fl off.ro))))

{:start  start
 :update update
 :draw   draw}