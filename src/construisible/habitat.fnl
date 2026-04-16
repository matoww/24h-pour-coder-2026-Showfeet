(local habitat {})
(set habitat.__index habitat)
(fn habitat.new [x y constructeur]
  (setmetatable
    {construisible.new x y 238 200 5000 constructeur}    ; frames restantes avant de finir la construction
    habitant [] ; liste d'entités présentes dans l'habitat
    limite 4
    ))

(fn habitat.ajouterHabitant [self habitant]
  (when and (self.is-build) (< self.habitant.length self.limite))
    (table.insert self.habitant habitant))

habitat