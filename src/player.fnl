;; src/player.fnl

(local sprite-idle 2)
(local sprite-walk 3)

(local player {:x 120 
               :y 68 
               :speed 2 
               :radius 4 
               :is-moving false})

(fn player.update [screen-w screen-h]
  "Gère les déplacements du joueur."
  (var dx 0)
  (var dy 0)
  
  (if (btn 0) (set dy -1))
  (if (btn 1) (set dy 1))
  (if (btn 2) (set dx -1))
  (if (btn 3) (set dx 1))
  
  (set player.is-moving (or (not= dx 0) (not= dy 0)))
  
  (var current-speed player.speed)
  (when (and (not= dx 0) (not= dy 0))
    (set current-speed (* player.speed 0.707)))
    
  (set player.x (+ player.x (* dx current-speed)))
  (set player.y (+ player.y (* dy current-speed))))

(fn player.draw [screen-w screen-h]
  "Dessine le joueur au centre de l'écran."
  (let [x (- (/ screen-w 2) 4)
        y (- (/ screen-h 2) 4)
        sprite-id (if player.is-moving
                      (if (= (% (// (time) 150) 2) 0) 
                          sprite-idle 
                          sprite-walk)
                      sprite-idle)]
    (spr sprite-id x y 0)))

;; On retourne la table player pour qu'elle soit accessible via (require)
player