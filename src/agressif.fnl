;; agressif.fnl — entité animée avec HP et dégâts

(local Anime (include "src.anime"))

(local Agressif {})
(set Agressif.__index Agressif)
(setmetatable Agressif {:__index Anime})

(fn Agressif.new [x y speed sprite-idle sprite-walk hp damage]
  (let [self (Anime.new x y speed sprite-idle sprite-walk)]
    (set self.hp     hp)
    (set self.damage damage)
    (setmetatable self Agressif)))

Agressif