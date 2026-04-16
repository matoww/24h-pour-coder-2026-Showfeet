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

(fn start [entite weapon]
  "Initialise l'état d'attaque sur n'importe quelle entité"
  (set entite.attack-state {:active true :frame 0 :weapon weapon}))

(fn update [entite]
  (when (and entite.attack-state entite.attack-state.active)
    (set entite.attack-state.frame (+ entite.attack-state.frame 1))
    (when (>= entite.attack-state.frame 12)
      (set entite.attack-state.active false))))

(fn draw [entite cam-x cam-y]
  "Affiche l'arme aux coordonnées de l'entité moins la caméra"
  (let [st entite.attack-state]
    (when (and st st.active st.weapon)
      (let [phases (. PHASES entite.direction)
            phase  (math.min 2 (// (* st.frame 3) 12))
            off    (. phases (+ phase 1))]
        (spr st.weapon.sprite-id
             (+ (- entite.x cam-x) off.dx)
             (+ (- entite.y cam-y) off.dy)
             0 1 off.fl off.ro)))))

{:start  start
 :update update
 :draw   draw}