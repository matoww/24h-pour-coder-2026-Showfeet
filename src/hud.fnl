(local BAR-W    48)
(local BAR-H     8)
(local SLOT-W    8)   ;; = BAR-H : le slot s'aligne exactement sur la barre
(local SLOT-H    8)
(local SEP       4)
(local PAD-X     2)
(local PAD-Y     2)
(local PANEL-H  12)   ;; BAR-H + 2×PAD-Y

;; --- BARRE DE VIE ---

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

;; --- SLOT ARME ---

(fn draw-weapon-slot [sx sy weapon]
  (rect  sx sy SLOT-W SLOT-H 0)
  (rectb sx sy SLOT-W SLOT-H 5)
  (if (not= weapon nil)
      (spr weapon.sprite-id sx sy 0)
      (print "-" (+ sx 2) (+ sy 2) 5 false 1 true)))

;; --- HUD PRINCIPAL ---

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

;; --- PANNEAU INVENTAIRE COMPLET ---

(fn draw-inventory-panel [inv ressources screen-w screen-h]
  "Affiché quand le joueur appuie sur S (btn 7)."
  (let [nb      (length ressources)
        panel-w 90
        row-h   10
        panel-h (+ 14 (* nb row-h))
        panel-x (- (// screen-w 2) (// panel-w 2))
        panel-y (- (// screen-h 2) (// panel-h 2))]

    (rect  panel-x panel-y panel-w panel-h 0)
    (rectb panel-x panel-y panel-w panel-h 12)

    ;; Titre
    (print "Inventaire" (+ panel-x 4) (+ panel-y 3) 12 false 1 false)
    (line panel-x (+ panel-y 11) (+ panel-x panel-w) (+ panel-y 11) 5)

    ;; Une ligne par ressource
    (each [i res (ipairs ressources)]
      (let [ry  (+ panel-y 13 (* (- i 1) row-h))
            q   (or (. inv.stacks res.id) 0)]
        ;; Icône
        (spr res.sprite-id (+ panel-x 4) ry 0)
        ;; Nom
        (print res.name (+ panel-x 14) (+ ry 1)
               (if (> q 0) 12 5) false 1 false)
        ;; Quantité alignée à droite
        (let [qstr (tostring q)
              qw   (* (length qstr) 6)]
          (print qstr (- (+ panel-x panel-w) qw 4) (+ ry 1)
                 (if (> q 0) 12 5) false 1 false))))))

;; --- STATS ARME ---

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

{:draw                 draw
 :draw-inventory-panel draw-inventory-panel
 :draw-weapon-stats    draw-weapon-stats}