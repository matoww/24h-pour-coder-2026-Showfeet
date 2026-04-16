;; world/objects.fnl

(local liste [])

(local DIR-VEC
  {:right {:dx  1 :dy  0}
   :left  {:dx -1 :dy  0}
   :up    {:dx  0 :dy -1}
   :down  {:dx  0 :dy  1}})

(fn add [obj]
  (table.insert liste obj))

(fn update []
  (each [_ obj (ipairs liste)]
    (when obj.alive (obj:update))))

(fn draw [cam-x cam-y]
  (each [_ obj (ipairs liste)]
    (obj:draw cam-x cam-y)))

(fn collide? [ax ay aw ah bx by bw bh]
  (and (< ax (+ bx bw))
       (> (+ ax aw) bx)
       (< ay (+ by bh))
       (> (+ ay ah) by)))

(fn check-collision [nx ny radius]
  (var blocked false)
  (each [_ obj (ipairs liste)]
    (when (and obj.alive
               (collide? (- nx radius) (- ny radius)
                         (* 2 radius) (* 2 radius)
                         obj.x obj.y
                         (* (or obj.sprite-w 1) 8)
                         (* (or obj.sprite-h 1) 8)))
      (set blocked true)))
  blocked)

(fn hit-in-range [player weapon inv-module]
  (let [range (* weapon.portee 8)
        ;; Rectangle d'attaque devant le joueur selon sa direction
        ax (if (= player.direction :left)  (- player.x range)
               (= player.direction :right) (+ player.x 8)
               (- player.x 4))
        ay (if (= player.direction :up)    (- player.y range)
               (= player.direction :down)  (+ player.y 8)
               (- player.y 4))
        aw (if (or (= player.direction :left)
                   (= player.direction :right)) range 16)
        ah (if (or (= player.direction :up)
                   (= player.direction :down))  range 16)]
    (each [_ obj (ipairs liste)]
      (when obj.alive
        (let [ow (* (or obj.sprite-w 1) 8)
              oh (* (or obj.sprite-h 1) 8)]
          (when (collide? ax ay aw ah obj.x obj.y ow oh)
            (let [destroyed (obj:hit weapon.degats)]
              (when destroyed
                (each [_ drop (ipairs (obj:collect-loot))]
                  (inv-module.add
                    player.inventory
                    drop.ressource
                    drop.count))))))))))

(fn respawn-all []
  (each [_ obj (ipairs liste)]
    (when (. obj :reset)
      (obj:reset))))

{:add             add
 :update          update
 :draw            draw
 :check-collision check-collision
 :hit-in-range    hit-in-range
 :respawn-all     respawn-all
 :liste           liste}