(fn make-weapon [id name sprite-id stats]
  {:category            :arme
   :id                  id
   :name                name
   :sprite-id           sprite-id
   :degats              (or stats.degats              0)
   :portee              (or stats.portee              1)
   :vitesse             (or stats.vitesse             1)
   :critique            (or stats.critique            0)
   :ranged              (or stats.ranged              false)
   :vitesse-projectile  (or stats.vitesse-projectile  0)
   :sprite-projectile   (or stats.sprite-projectile   0)})  ;; manquait ici

(local EPEE
  (make-weapon :epee "Épée" 299
    {:degats 10 :portee 1 :vitesse 1 :critique 5}))

(local ARBALETE
  (make-weapon :arbalete "Arbalète" 300
    {:degats             8
     :portee             20
     :vitesse            1
     :critique          10
     :ranged             true
     :vitesse-projectile 5
     :sprite-projectile  315}))

(local TOUTES [EPEE ARBALETE])

(fn equiper [player weapon]
  (set player.equipped-weapon weapon))

(fn desequiper [player]
  (set player.equipped-weapon nil))

(fn cycle [player]
  (let [current player.equipped-weapon]
    (if (= current nil)
        (equiper player (. TOUTES 1))
        (do
          (var next-idx nil)
          (each [i w (ipairs TOUTES)]
            (when (= w.id current.id)
              (set next-idx (+ i 1))))
          (if (or (= next-idx nil) (> next-idx (length TOUTES)))
              (desequiper player)
              (equiper player (. TOUTES next-idx)))))))

(fn attaquer [player attack-module proj-module]
  (let [weapon player.equipped-weapon]
    (when (not= weapon nil)
      (if weapon.ranged
          (proj-module.fire player weapon)
          (attack-module.start player weapon)))))

{:make-weapon make-weapon
 :equiper     equiper
 :desequiper  desequiper
 :cycle       cycle
 :attaquer    attaquer
 :EPEE        EPEE
 :ARBALETE    ARBALETE
 :TOUTES      TOUTES}