;; projectile.fnl

(local actifs [])

(local DIRS
  {:right {:dx  1 :dy  0}
   :left  {:dx -1 :dy  0}
   :up    {:dx  0 :dy -1}
   :down  {:dx  0 :dy  1}})

;; flip/rotate selon direction — même logique que attack.fnl
(local DIR-SPR
  {:right {:fl 0 :ro 3}
   :left  {:fl 0 :ro 1}
   :up    {:fl 3 :ro 0}   ;; 270° = pointe vers le haut
   :down  {:fl 0 :ro 0}}) ;; 90°  = pointe vers le bas

(fn fire [player weapon]
  (let [dir     (. DIRS    player.direction)
        spr-dir (. DIR-SPR player.direction)]
    (table.insert actifs
      {:x         (+ player.x 4)
       :y         (+ player.y 4)
       :dx        dir.dx
       :dy        dir.dy
       :fl        spr-dir.fl
       :ro        spr-dir.ro
       :speed     weapon.vitesse-projectile
       :degats    weapon.degats
       :portee-px (* weapon.portee 8)
       :parcouru  0
       :sprite-id weapon.sprite-projectile})))

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