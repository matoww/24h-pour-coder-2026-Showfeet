;; civil.fnl — PNJ civil, hérite de Anime
;; Override de ia() uniquement : le mouvement/pathfinding est géré par Anime.update

(local Anime (include "src.pnj.anime"))
(local astar (include "src.aStar"))

(local Civil {})
(set Civil.__index Civil)
(setmetatable Civil {:__index Anime})

;; --- CONFIGURATION ---
(local TILE-SIZE 8)
(local LST-NAME
  ["Alice" "Gauthier" "Anthony" "Lucas" "Marie"
   "Lynn" "Quentin" "Sébastien" "Flora" "Claire"])
(local LST-DIALOG
  ["Salut, je peux me joindre à toi ?"
   "Fais attention, il y a des dangers dans les environs."
   "Je suis à la recherche de ressources, tu en as peut-être à partager ?"
   "Tu devrais éviter la zone nord, c'est infesté de créatures."
   "Je pensais que j'étais seul, mais je suis content de te voir."
   "Je suis à la recherche d'un groupe de survivants, tu en fais partie ?"
   "Je suis un ancien médecin, je peux peut-être t'aider si tu es blessé."])

;; --- LOGIQUE DES STATS ---
(fn Civil.define-stat [self distance max-dist]
  (let [min-possible 1
        max-possible 100
        spread       20
        dist-factor  (/ (math.min distance max-dist) max-dist)
        low-bound    (+ min-possible (* dist-factor (- max-possible spread)))
        high-bound   (+ low-bound spread)
        raw-stat     (math.random (math.floor low-bound) (math.floor high-bound))]
    (math.max min-possible (math.min max-possible raw-stat))))

;; --- CONSTRUCTEUR ---
(fn Civil.new [x y]
  (let [px   (or x (math.random 0 240))
        py   (or y (math.random 0 136))
        self (Anime.new px py 0.5 258 259)]
    (setmetatable self Civil)

    ;; Identité
    (set self.name   (. LST-NAME   (math.random 1 (length LST-NAME))))
    (set self.dialog (. LST-DIALOG (math.random 1 (length LST-DIALOG))))

    ;; Stats (meilleures loin du centre 120,68)
    (let [dist-base (astar.heuristic {:x 120 :y 68} {:x self.x :y self.y})
          max-dist  40]
      (set self.construction (self:define-stat dist-base max-dist))
      (set self.recolte      (self:define-stat dist-base max-dist)))

    ;; État propre au civil
    (set self.batiment      nil)
    (set self.state         :idle)   ; :idle | :moving | :at-work
    ;; Cooldown entre deux errance (en frames), décalé aléatoirement pour éviter la synchro
    (set self.wander-cooldown (math.random 60 180))

    self))

;; -----------------------------------------------------------------
;; ia() — surchargée : le civil cherche à rejoindre son bâtiment.
;; Appelée automatiquement par Anime.update chaque frame.
;; -----------------------------------------------------------------
(fn Civil.ia [self is-night]
  (if (= self.state :at-work)
      ;; Déjà arrivé : ne rien faire (pas de recalcul A*)
      nil

      (and self.batiment (= self.state :moving))
      ;; On veut aller au bâtiment — on pose la destination si on ne l'a pas
      (do
        (when (not self.destination)
          (set self.destination {:x self.batiment.x :y self.batiment.y}))
        ;; Détecte l'arrivée : move-along-path a effacé destination quand c'est fini
        (when (and (not self.destination) (not self.path))
          (set self.state :at-work)))

      ;; :idle — errance aléatoire dans un rayon de 2-3 tiles
      (do
        ;; Décrémente le cooldown d'errance
        (when (> self.wander-cooldown 0)
          (set self.wander-cooldown (- self.wander-cooldown 1)))

        ;; Quand le cooldown est écoulé et qu'on n'a plus de destination : en choisir une nouvelle
        (when (and (<= self.wander-cooldown 0) (not self.destination) (not self.path))
          (let [radius (* (math.random 2 3) 8)
                angle  (* (math.random 0 628) 0.01) ; 0..2π approximé
                tx     (math.max 0 (math.min 504 (+ self.x (* radius (math.cos angle)))))
                ty     (math.max 0 (math.min 504 (+ self.y (* radius (math.sin angle)))))]
            (set self.destination {:x tx :y ty})
            ;; Prochain délai : 3 à 6 secondes (180-360 frames à 60fps)
            (set self.wander-cooldown (math.random 180 360)))))))

;; -----------------------------------------------------------------
;; update — délègue entièrement à Anime.update (qui appelle self:ia)
;; -----------------------------------------------------------------
(fn Civil.update [self is-night]
  (Anime.update self is-night))

;; -----------------------------------------------------------------
;; draw — corrigé : appelle Anime.draw avec les coords caméra
;; -----------------------------------------------------------------
(fn Civil.draw [self cam-x cam-y]
  (let [sx (- self.x cam-x)
        sy (- self.y cam-y)]
    ;; Ne dessine que si le sprite est dans le viewport (240x136)
    (when (and (> sx -8) (< sx 240)
               (> sy -8) (< sy 136))
      (Anime.draw self sx sy))))

;; -----------------------------------------------------------------
;; assign-building — assigne un bâtiment cible au civil
;; -----------------------------------------------------------------
(fn Civil.assign-building [self building]
  (set self.batiment   building)
  (set self.state      :moving)
  ;; Réinitialise le chemin pour forcer un recalcul
  (set self.path       nil)
  (set self.destination nil)
  ;; Expire le cooldown pour recalculer immédiatement
  (set self.path-cooldown 0))

Civil
