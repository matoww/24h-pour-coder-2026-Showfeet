(local sprite-idle 256)
(local sprite-walk 257)

(local player {:x 120 
               :y 68 
               :speed 2 
               :radius 4 
               :is-moving false
               :flip 0}) ;; 0 = normal, 1 = miroir horizontal

(fn player.update [screen-w screen-h]
  "Gère les déplacements du joueur."
  (var dx 0)
  (var dy 0)
  
  (if (btn 0) (set dy -1))
  (if (btn 1) (set dy 1))
  (if (btn 2) (set dx -1))
  (if (btn 3) (set dx 1))
  
  ;; --- GESTION DU FLIP ---
  ;; Si on va à gauche, on retourne le sprite
  (if (< dx 0) (set player.flip 1)
      ;; Si on va à droite, on le remet à l'endroit
      (> dx 0) (set player.flip 0))
  
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
    
    ;; spr(id, x, y, colorkey, scale, flip)
    ;; flip: 0 = normal, 1 = horizontal, 2 = vertical, 3 = les deux
    (spr sprite-id x y 0 1 player.flip)))

;; On retourne la table player
player