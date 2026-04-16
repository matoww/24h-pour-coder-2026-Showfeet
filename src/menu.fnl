;; menu.fnl — Menu unifié à onglets (INVENTAIRE / CONSTRUIRE / CIVILS)
;;
;; Contrôles dans le menu :
;;   ← / →  : changer d'onglet
;;   ↑ / ↓  : naviguer dans la liste
;;   A      : valider
;;   X ou B : fermer
;;
;; Ce module ne connaît RIEN du moteur : le main lui passe
;; les données et les callbacks dont il a besoin.

(local inventory (include "src.player.inventory"))
(local item      (include "src.item"))

(local Menu {})

;; Onglets disponibles
(local TABS [:invent :build :civils])
(local TAB-LABELS {:invent "INVENTAIRE" :build "CONSTRUIRE" :civils "CIVILS"})

;; État
(var open      false)
(var tab-idx   1)      ; 1..3
(var list-idx  1)      ; position dans la liste de l'onglet courant
(var last-action-msg "")  ; message flash en bas ("Pas assez de bois", etc.)
(var msg-timer 0)

;; Layout
(local W 180)
(local H 110)

(fn flash [s]
  (set last-action-msg s)
  (set msg-timer 120))

;; -----------------------------------------------------------------
;; API : ouverture
;; -----------------------------------------------------------------
(fn Menu.open? [] open)

(fn Menu.toggle []
  (set open (not open))
  (when open
    (set tab-idx 1)
    (set list-idx 1)))

(fn Menu.close []
  (set open false))

;; -----------------------------------------------------------------
;; Récupération de la liste de l'onglet courant (nombre d'items).
;; Utilise les ressources passées en argument pour éviter les imports circulaires.
;; -----------------------------------------------------------------
(fn list-length [current-tab ctx]
  (if (= current-tab :invent) (length item.RESSOURCES)
      (= current-tab :build)  (length ctx.build-catalog)
      (= current-tab :civils) (length ctx.civils)
      0))

;; -----------------------------------------------------------------
;; Navigation
;; -----------------------------------------------------------------
(fn Menu.nav-tab [delta]
  (when open
    (set tab-idx (+ tab-idx delta))
    (when (< tab-idx 1) (set tab-idx (length TABS)))
    (when (> tab-idx (length TABS)) (set tab-idx 1))
    (set list-idx 1)))

(fn Menu.nav-list [delta ctx]
  (when open
    (let [current (. TABS tab-idx)
          n       (list-length current ctx)]
      (when (> n 0)
        (set list-idx (+ list-idx delta))
        (when (< list-idx 1) (set list-idx n))
        (when (> list-idx n) (set list-idx 1))))))

;; -----------------------------------------------------------------
;; Validation (A) — appelle le callback approprié selon l'onglet
;; -----------------------------------------------------------------
(fn Menu.valider [ctx]
  (when open
    (let [current (. TABS tab-idx)]
      (if (= current :build)
          (let [info (. ctx.build-catalog list-idx)]
            (when info
              (let [result (ctx.on-build info)]
                (if result
                    (do (flash (.. "Pose: " info.nom))
                        (set open false))
                    (flash "Pas assez de ressources !")))))

          (= current :civils)
          (let [civil (. ctx.civils list-idx)]
            (when civil
              (let [result (ctx.on-civil civil)]
                (if result
                    (flash (.. (or civil.name "Civil") " -> " result))
                    (flash "Aucun batiment libre")))))

          ;; :invent : pas d'action
          nil))))

;; -----------------------------------------------------------------
;; Rendu
;; -----------------------------------------------------------------

;; Dessine la rangée d'onglets en haut
(fn draw-tabs [x y]
  (var tx x)
  (each [i tab (ipairs TABS)]
    (let [label (. TAB-LABELS tab)
          selected (= i tab-idx)
          lw (+ 2 (* (length label) 4))]
      (if selected
          (do (rect tx y lw 9 11)
              (print label (+ tx 1) (+ y 2) 0 false 1 true))
          (do (rect tx y lw 9 0)
              (print label (+ tx 1) (+ y 2) 12 false 1 true)))
      (set tx (+ tx lw 2)))))

;; Panneau Inventaire
(fn draw-invent-body [x y w h inv]
  (each [i res (ipairs item.RESSOURCES)]
    (let [ly (+ y 2 (* (- i 1) 10))
          q  (or (. inv.stacks res.id) 0)
          selected (= i list-idx)
          col (if selected 11 (if (> q 0) 12 5))]
      (when selected (print ">" (+ x 2) ly col false 1 true))
      (spr res.sprite-id (+ x 10) (- ly 1) 0)
      (print res.name (+ x 20) ly col false 1 false)
      (let [qstr (tostring q)
            qw   (* (length qstr) 4)]
        (print qstr (- (+ x w) qw 6) ly col false 1 true)))))

;; Panneau Construction
(fn draw-build-body [x y w h ctx]
  (each [i info (ipairs ctx.build-catalog)]
    (let [ly (+ y 2 (* (- i 1) 12))
          selected (= i list-idx)
          payable  (ctx.can-pay info)
          col (if (not payable) 14 (if selected 11 12))]
      (when selected (print ">" (+ x 2) ly col false 1 true))
      (spr info.sprite (+ x 10) (- ly 1) 0)
      (print info.nom (+ x 20) ly col false 1 false)
      ;; Résumé des coûts
      (var cx (+ x 60))
      (each [id qte (pairs info.cout)]
        (print (.. qte (string.sub (tostring id) 1 1)) cx ly col false 1 true)
        (set cx (+ cx 12))))))

;; Panneau Civils
(fn draw-civils-body [x y w h ctx]
  (if (= (length ctx.civils) 0)
      (print "Aucun civil." (+ x 4) (+ y 4) 14 false 1 false)
      (each [i civil (ipairs ctx.civils)]
        (let [ly (+ y 2 (* (- i 1) 10))
              selected (= i list-idx)
              etat (if (= civil.state :idle)    "libre"
                       (= civil.state :moving)  "en route"
                       (= civil.state :at-work) "travaille"
                       "?")
              col (if selected 11 12)]
          (when selected (print ">" (+ x 2) ly col false 1 true))
          ;; Nom
          (print (or civil.name "?") (+ x 10) ly col false 1 false)
          ;; Stats rec./const. compactes
          (print (.. "R:" (or civil.recolte 0)) (+ x 70) ly col false 1 true)
          (print (.. "C:" (or civil.construction 0)) (+ x 95) ly col false 1 true)
          ;; État
          (print etat (+ x 125) ly (if (= civil.state :idle) 11 14)
                 false 1 true)))))

;; Aide en bas
(fn draw-footer [x y w current-tab]
  (let [txt (if (= current-tab :invent) "X: fermer           L/R onglets"
                (= current-tab :build)  "A: poser   X: fermer   L/R onglets"
                (= current-tab :civils) "A: assigner   X: fermer   L/R onglets"
                "")]
    (print txt (+ x 3) y 14 false 1 true)))

(fn Menu.draw [screen-w screen-h ctx]
  (when open
    (when (> msg-timer 0)
      (set msg-timer (- msg-timer 1)))
    (let [x (- (// screen-w 2) (// W 2))
          y (- (// screen-h 2) (// H 2))
          current (. TABS tab-idx)
          body-y (+ y 14)
          body-h (- H 24)]
      (rect  x y W H 0)
      (rectb x y W H 12)
      (draw-tabs (+ x 4) (+ y 3))
      (line x (+ y 13) (+ x W) (+ y 13) 5)
      (if (= current :invent) (draw-invent-body (+ x 3) body-y (- W 6) body-h ctx.inventory)
          (= current :build)  (draw-build-body  (+ x 3) body-y (- W 6) body-h ctx)
          (= current :civils) (draw-civils-body (+ x 3) body-y (- W 6) body-h ctx))
      (line x (- (+ y H) 9) (+ x W) (- (+ y H) 9) 5)
      (draw-footer x (- (+ y H) 7) W current)
      ;; Message flash éventuel
      (when (> msg-timer 0)
        (print last-action-msg (+ x 3) (- y 8) 11 false 1 false)))))

;; -----------------------------------------------------------------
;; Gestion des inputs (à appeler depuis le main quand open? = true)
;; ctx : voir main, contient inventory / civils / build-catalog / callbacks
;; -----------------------------------------------------------------
(fn Menu.handle-input [ctx]
  (when open
    (when (btnp 0) (Menu.nav-list -1 ctx))
    (when (btnp 1) (Menu.nav-list  1 ctx))
    (when (btnp 2) (Menu.nav-tab  -1))
    (when (btnp 3) (Menu.nav-tab   1))
    (when (btnp 4) (Menu.valider ctx))
    (when (or (btnp 5) (btnp 6)) (Menu.close))))

{:open?        Menu.open?
 :toggle       Menu.toggle
 :close        Menu.close
 :nav-tab      Menu.nav-tab
 :nav-list     Menu.nav-list
 :valider      Menu.valider
 :draw         Menu.draw
 :handle-input Menu.handle-input}
