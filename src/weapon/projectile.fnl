;; projectile.fnl
(local actifs [])

;; Table de conversion simplifiée pour les projectiles
(local DIR-MAP
  {:right {:dx 1  :dy 0  :fl 0 :ro 3}
   :left  {:dx -1 :dy 0  :fl 0 :ro 1}
   :up    {:dx 0  :dy -1 :fl 3 :ro 0}
   :down  {:dx 0  :dy 1  :fl 0 :ro 0}})

(fn fire [source weapon]
  "Prend n'importe quelle source ayant .x, .y et .direction"
  (let [config (. DIR-MAP source.direction)]
    (table.insert actifs
      {:x         (+ source.x 4)
       :y         (+ source.y 4)
       :dx        config.dx
       :dy        config.dy
       :fl        config.fl
       :ro        config.ro
       :speed     weapon.vitesse-projectile
       :degats    weapon.degats
       :portee-px (* weapon.portee 8)
       :parcouru  0
       :sprite-id weapon.sprite-projectile
       :owner     source})))

(fn update []
  (var i 1)
  (while (<= i (length actifs))
    (let [p (. actifs i)]
      (set p.x        (+ p.x (* p.dx p.speed)))
      (set p.y        (+ p.y (* p.dy p.speed)))
      (set p.parcouru (+ p.parcouru p.speed))
      (if (>= p.parcouru p.portee-px)
          (table.remove actifs i)
          (set i (+ i 1))))))

(fn draw [cam-x cam-y]
  (each [_ p (ipairs actifs)]
    (spr p.sprite-id
         (- p.x cam-x 4)
         (- p.y cam-y 4)
         0 1 p.fl p.ro)))

{:fire   fire
 :update update
 :draw   draw
 :actifs actifs}