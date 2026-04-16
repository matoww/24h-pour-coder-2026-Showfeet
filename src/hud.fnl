(local BAR-W    48)
(local BAR-H     8)
(local SLOT-W    8)
(local SLOT-H    8)
(local SEP       4)
(local PAD-X     2)
(local PAD-Y     2)
(local PANEL-H  12)

(fn hp-color [ratio]
  (if (> ratio 0.6) 6
      (> ratio 0.3) 4
                    2))

(fn draw-hp [bx by hp max-hp]
  (let [ratio  (math.max 0 (math.min 1 (/ hp max-hp)))
        fill-w (math.floor (* (- BAR-W 2) ratio))
        col    (hp-color ratio)
        label  (.. hp "/" max-hp)]
    (rect  bx by BAR-W BAR-H 0)
    (rectb bx by BAR-W BAR-H 5)
    (when (> fill-w 0)
      (rect (+ bx 1) (+ by 1) fill-w (- BAR-H 2) col))
    (let [lw (* (length label) 5)
          lx (+ bx (math.max 1 (// (- BAR-W lw) 2)))]
      (print label lx (+ by 2)
             (if (> ratio 0.3) 12 7)
             false 1 true))))

(fn draw-weapon-slot [sx sy weapon]
  (rect  sx sy SLOT-W SLOT-H 0)
  (rectb sx sy SLOT-W SLOT-H 5)
  (if (not= weapon nil)
      (spr weapon.sprite-id sx sy 0)
      (print "-" (+ sx 2) (+ sy 2) 5 false 1 true)))

(fn draw [player screen-w screen-h]
  (let [panel-w (+ (* 2 PAD-X) BAR-W SEP SLOT-W)
        panel-x 3
        panel-y (- screen-h PANEL-H 2)]
    (rect  panel-x panel-y panel-w PANEL-H 0)
    (rectb panel-x panel-y panel-w PANEL-H 5)
    (draw-hp (+ panel-x PAD-X) (+ panel-y PAD-Y)
             player.hp player.max-hp)
    (draw-weapon-slot (+ panel-x PAD-X BAR-W SEP)
                      (+ panel-y PAD-Y)
                      player.equipped-weapon)))

(fn draw-inventory-panel [inv ressources screen-w screen-h]
  (let [nb      (length ressources)
        panel-w 90
        row-h   10
        panel-h (+ 14 (* nb row-h))
        panel-x (- (// screen-w 2) (// panel-w 2))
        panel-y (- (// screen-h 2) (// panel-h 2))]
    (rect  panel-x panel-y panel-w panel-h 0)
    (rectb panel-x panel-y panel-w panel-h 12)
    (print "Inventaire" (+ panel-x 4) (+ panel-y 3) 12 false 1 false)
    (line panel-x (+ panel-y 11) (+ panel-x panel-w) (+ panel-y 11) 5)
    (each [i res (ipairs ressources)]
      (let [ry  (+ panel-y 13 (* (- i 1) row-h))
            q   (or (. inv.stacks res.id) 0)]
        (spr res.sprite-id (+ panel-x 4) ry 0)
        (print res.name (+ panel-x 14) (+ ry 1)
               (if (> q 0) 12 5) false 1 false)
        (let [qstr (tostring q)
              qw   (* (length qstr) 6)]
          (print qstr (- (+ panel-x panel-w) qw 4) (+ ry 1)
                 (if (> q 0) 12 5) false 1 false))))))

(fn draw-weapon-stats [weapon screen-w screen-h]
  (when (not= weapon nil)
    (let [panel-w 70
          panel-h 42
          panel-x (- screen-w panel-w 3)
          panel-y (- (// screen-h 2) (// panel-h 2))]
      (rect  panel-x panel-y panel-w panel-h 0)
      (rectb panel-x panel-y panel-w panel-h 12)
      (print weapon.name (+ panel-x 4) (+ panel-y 3) 12 false 1 false)
      (line panel-x (+ panel-y 11) (+ panel-x panel-w) (+ panel-y 11) 5)
      (let [stats [[:degats   "Degats"  ]
                   [:portee   "Portee"  ]
                   [:vitesse  "Vitesse" ]
                   [:critique "Critique"]]]
        (each [i [key label] (ipairs stats)]
          (let [ry  (+ panel-y 13 (* (- i 1) 8))
                val (tostring (. weapon key))]
            (print label (+ panel-x 4) ry 5 false 1 true)
            (print val (- (+ panel-x panel-w) (* (length val) 4) 4) ry 12 false 1 true)))))))

;; --- HORLOGE ---

(fn draw-clock [world screen-w screen-h]
  (let [total    (+ world.day-duration world.night-duration)
        current  (% world.time total)
        is-night (>= current world.day-duration)
        ratio    (if is-night
                     (/ (- current world.day-duration) world.night-duration)
                     (/ current world.day-duration))
        r        16
        ;; cy = base plate du dôme, l'arc monte vers y=0
        cx       (- screen-w r 3)
        cy       (+ r 3)
        sky-col  (if is-night 9 10)

        ;; Corps à r-5 → reste dans le dôme
        angle (* math.pi (- 1 ratio))
        bx    (math.floor (+ cx (* (- r 5) (math.cos angle))))
        by    (math.floor (- cy (* (- r 5) (math.sin angle))))]

    ;; 1. Fond panneau
    (rect  (- cx r 2) 1 (+ (* 2 r) 4) (+ r 4) 0)

    ;; 2. Remplissage ciel — scanlines vers le haut depuis cy
    (for [row 0 r]
      (let [hw (math.floor (math.sqrt (math.max 0 (- (* r r) (* row row)))))]
        (line (- cx hw) (- cy row) (+ cx hw) (- cy row) sky-col)))

    ;; 3. Étoiles (nuit)
    (when is-night
      (each [_ s (ipairs [{:rx  0.30 :ry 0.25}
                          {:rx -0.45 :ry 0.30}
                          {:rx  0.55 :ry 0.50}
                          {:rx -0.60 :ry 0.55}
                          {:rx  0.10 :ry 0.70}
                          {:rx -0.20 :ry 0.65}
                          {:rx  0.70 :ry 0.28}
                          {:rx -0.75 :ry 0.22}
                          {:rx  0.40 :ry 0.80}
                          {:rx -0.35 :ry 0.82}
                          {:rx  0.00 :ry 0.45}
                          {:rx -0.55 :ry 0.78}])]
        (pix (math.floor (+ cx (* r s.rx)))
             (math.floor (- cy (* r s.ry)))
             12)))

    ;; 4. Corps céleste
    (if is-night
        (do
          (circ bx by 3 12)
          (circ (+ bx 2) (- by 1) 2 sky-col))
        (do
          (circ bx by 2 4)
          (pix  bx       (- by 3) 4)
          (pix  bx       (+ by 3) 4)
          (pix  (- bx 3) by       4)
          (pix  (+ bx 3) by       4)))

    ;; 5. Arc vers le haut (sin négatif)
    (var a 0)
    (while (<= a math.pi)
      (pix (math.floor (+ cx (* r (math.cos a))))
           (math.floor (- cy (* r (math.sin a))))
           5)
      (set a (+ a 0.04)))

    ;; 6. Horizon (base plate)
    (line (- cx r) cy (+ cx r) cy 5)

    ;; 7. Bordure
    (rectb (- cx r 2) 1 (+ (* 2 r) 4) (+ r 4) 5)))

(fn draw-gameover [screen-w screen-h]
  (let [panel-w 120
        panel-h 60
        panel-x (- (// screen-w 2) (// panel-w 2))
        panel-y (- (// screen-h 2) (// panel-h 2))]
    (rect  panel-x panel-y panel-w panel-h 0)
    (rectb panel-x panel-y panel-w panel-h 2)
    (print "GAME OVER" (+ panel-x 30) (+ panel-y 10) 2 false 2 false)))

{:draw                 draw
 :draw-inventory-panel draw-inventory-panel
 :draw-weapon-stats    draw-weapon-stats
 :draw-clock           draw-clock
 :draw-gameover        draw-gameover}