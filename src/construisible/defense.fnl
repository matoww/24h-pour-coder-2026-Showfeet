(local defense {})
(set defense.__index defense)
(fn defense.new [x y constructeur]
  (setmetatable
    {construisible.new x y 224 150 10000 constructeur}
     )
    
    
   )   