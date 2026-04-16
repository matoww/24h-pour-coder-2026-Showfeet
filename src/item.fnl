;; item.fnl
;; Hiérarchie prototype des entités Non-Animées.
;; Utilise l'héritage par délégation (tables Lua) plutôt que des classes.

;; ------------------------------------------------------------------
;; UTILITAIRE : héritage par copie de prototype
;; ------------------------------------------------------------------
(fn extend [base props]
  "Crée un nouveau prototype qui hérite des champs de 'base'."
  (let [obj {}]
    (each [k v (pairs base)]  (tset obj k v))
    (each [k v (pairs props)] (tset obj k v))
    obj))

;; ------------------------------------------------------------------
;; NIVEAU 1 : Non-Animé (racine)
;; ------------------------------------------------------------------
(local NonAnime
  {:category :non-anime
   :name     "?"
   :id       :unknown})

;; ------------------------------------------------------------------
;; NIVEAU 2a : Ressource
;; ------------------------------------------------------------------
(local Ressource
  (extend NonAnime
    {:category  :ressource
     :stackable true
     :max-stack 999
     :sprite-id 0    ;; à remplacer dans TIC-80
     :color     1}))

(fn make-ressource [id name sprite-id color max-stack]
  "Fabrique une instance concrète de Ressource."
  (extend Ressource
    {:id        id
     :name      name
     :sprite-id sprite-id
     :color     color
     :max-stack (or max-stack 999)}))

;; ------------------------------------------------------------------
;; NIVEAU 2b : Construisible (socle pour Bâtiment & Arme)
;; À développer lors d'une prochaine itération.
;; ------------------------------------------------------------------
(local Construisible
  (extend NonAnime
    {:category          :construisible
     :cout              {}    ;; {item-id -> quantite}
     :temps-construction 0}))

;; ------------------------------------------------------------------
;; INSTANCES CONCRÈTES DE RESSOURCE
;; Les IDs de sprites sont des placeholders — à ajuster dans
;; l'éditeur de sprites TIC-80.
;; ------------------------------------------------------------------
(local BOIS   (make-ressource :bois   "Bois"   5 6  999))
(local PIERRE (make-ressource :pierre "Pierre" 4 13 999))
(local FER (make-ressource :pierre "Fer" 20 13 999))

;; Tableau ordonné pour l'affichage (ipairs = ordre garanti).
(local RESSOURCES [BOIS PIERRE FER])

;; ------------------------------------------------------------------
;; EXPORTS
;; ------------------------------------------------------------------
{:extend        extend
 :NonAnime      NonAnime
 :Ressource     Ressource
 :Construisible Construisible
 :make-ressource make-ressource
 :BOIS          BOIS
 :PIERRE        PIERRE
 :FER           FER
 :RESSOURCES    RESSOURCES}