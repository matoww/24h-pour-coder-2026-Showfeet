local item
package.preload["src.item"] = package.preload["src.item"] or function(...)
  local function extend(base, props)
    local obj = {}
    for k, v in pairs(base) do
      obj[k] = v
    end
    for k, v in pairs(props) do
      obj[k] = v
    end
    return obj
  end
  local NonAnime = {category = "non-anime", name = "?", id = "unknown"}
  local Ressource = extend(NonAnime, {category = "ressource", stackable = true, ["max-stack"] = 999, ["sprite-id"] = 0, color = 1})
  local function make_ressource(id, name, sprite_id, color, max_stack)
    return extend(Ressource, {id = id, name = name, ["sprite-id"] = sprite_id, color = color, ["max-stack"] = (max_stack or 999)})
  end
  local Construisible = extend(NonAnime, {category = "construisible", cout = {}, ["temps-construction"] = 0})
  local BOIS = make_ressource("bois", "Bois", 5, 6, 999)
  local PIERRE = make_ressource("pierre", "Pierre", 4, 13, 999)
  local RESSOURCES = {BOIS, PIERRE}
  return {extend = extend, NonAnime = NonAnime, Ressource = Ressource, Construisible = Construisible, ["make-ressource"] = make_ressource, BOIS = BOIS, PIERRE = PIERRE, RESSOURCES = RESSOURCES}
end
item = require("src.item")
local inventory
package.preload["src.player.inventory"] = package.preload["src.player.inventory"] or function(...)
  local function make_inventory()
    return {stacks = {}}
  end
  local function quantite(inv, ressource)
    return (inv.stacks[ressource.id] or 0)
  end
  local function add(inv, ressource, count)
    local actuel = quantite(inv, ressource)
    local espace = (ressource["max-stack"] - actuel)
    local ajoute = math.max(0, math.min(count, espace))
    inv.stacks[ressource.id] = (actuel + ajoute)
    return ajoute
  end
  local function retirer(inv, ressource, count)
    local actuel = quantite(inv, ressource)
    if (actuel >= count) then
      inv.stacks[ressource.id] = (actuel - count)
      return true
    else
      return false
    end
  end
  return {["make-inventory"] = make_inventory, quantite = quantite, add = add, retirer = retirer}
end
inventory = require("src.player.inventory")
local player_cls
package.preload["src.player.player"] = package.preload["src.player.player"] or function(...)
  local Agressif = require("src.pnj.agressif")
  local player = {}
  player.__index = player
  setmetatable(player, {__index = Agressif})
  player.new = function(x, y)
    local self = Agressif.new(x, y, 2, 256, 257, 100, 2)
    self["max-hp"] = 100
    self["equipped-weapon"] = nil
    self.inventory = {stacks = {}}
    self.direction = "right"
    self["attack-state"] = {frame = 0, weapon = nil, active = false}
    return setmetatable(self, player)
  end
  player.update = function(self)
    local dx = 0
    local dy = 0
    if btn(0) then
      dy = -1
    else
    end
    if btn(1) then
      dy = 1
    else
    end
    if btn(2) then
      dx = -1
    else
    end
    if btn(3) then
      dx = 1
    else
    end
    if not self["attack-state"].active then
      if (dx < 0) then
        self.direction = "left"
        self.flip = 1
      elseif (dx > 0) then
        self.direction = "right"
        self.flip = 0
      elseif (dy < 0) then
        self.direction = "up"
      elseif (dy > 0) then
        self.direction = "down"
      else
      end
    else
    end
    self["is-moving"] = ((dx ~= 0) or (dy ~= 0))
    local speed = self.speed
    if ((dx ~= 0) and (dy ~= 0)) then
      speed = (speed * 0.707)
    else
    end
    self.x = (self.x + (dx * speed))
    self.y = (self.y + (dy * speed))
    return nil
  end
  player.draw = function(self, screen_w, screen_h)
    local px = ((screen_w / 2) - 4)
    local py = ((screen_h / 2) - 4)
    local sid
    if self["is-moving"] then
      if (((time() // 150) % 2) == 0) then
        sid = self["sprite-idle"]
      else
        sid = self["sprite-walk"]
      end
    else
      sid = self["sprite-idle"]
    end
    return spr(sid, px, py, 0, 1, self.flip)
  end
  return player
end
package.preload["src.pnj.agressif"] = package.preload["src.pnj.agressif"] or function(...)
  local Anime = require("src.pnj.anime")
  local Agressif = {}
  Agressif.__index = Agressif
  setmetatable(Agressif, {__index = Anime})
  Agressif.new = function(x, y, speed, sprite_idle, sprite_walk, hp, damage)
    local self = Anime.new(x, y, speed, sprite_idle, sprite_walk)
    self.hp = hp
    self.damage = damage
    self.target = nil
    return setmetatable(self, Agressif)
  end
  Agressif.ia = function(self, ...)
    if self.target then
      self.destination = {x = self.target.x, y = self.target.y}
      return nil
    else
      return nil
    end
  end
  Agressif.update = function(self, ...)
    return Anime.update(self, ...)
  end
  Agressif.draw = function(self, cam_x, cam_y)
    return Anime.draw(self, (self.x - cam_x), (self.y - cam_y))
  end
  return Agressif
end
package.preload["src.pnj.anime"] = package.preload["src.pnj.anime"] or function(...)
  local astar = require("src.aStar")
  local Anime = {}
  Anime.__index = Anime
  local PATH_COOLDOWN = 60
  Anime.new = function(x, y, speed, sprite_idle, sprite_walk)
    return setmetatable({x = x, y = y, speed = speed, ["sprite-idle"] = sprite_idle, ["sprite-walk"] = sprite_walk, radius = 4, flip = 0, destination = nil, path = nil, ["path-idx"] = 1, ["path-cooldown"] = 0, ["is-moving"] = false}, Anime)
  end
  Anime.ia = function(self)
    return nil
  end
  Anime["request-path"] = function(self)
    if (self.destination and not self.path and (self["path-cooldown"] <= 0)) then
      local start = {x = (self.x // 8), y = (self.y // 8)}
      local dest = {x = (self.destination.x // 8), y = (self.destination.y // 8)}
      self.path = astar["a-star"](start, dest)
      self["path-idx"] = 1
      self["path-cooldown"] = PATH_COOLDOWN
      return nil
    else
      return nil
    end
  end
  Anime["move-along-path"] = function(self)
    if (self.path and self.path[self["path-idx"]]) then
      local target = self.path[self["path-idx"]]
      local tx = (target.x * 8)
      local ty = (target.y * 8)
      local dx = (tx - self.x)
      local dy = (ty - self.y)
      local dist = math.sqrt(((dx * dx) + (dy * dy)))
      if (dist > 1) then
        self["is-moving"] = true
        self.x = (self.x + ((dx / dist) * self.speed))
        self.y = (self.y + ((dy / dist) * self.speed))
        if (dx < 0) then
          self.flip = 1
        else
          self.flip = 0
        end
        return false
      else
        self["path-idx"] = (self["path-idx"] + 1)
        if (self["path-idx"] > #self.path) then
          self.path = nil
          self.destination = nil
          self["is-moving"] = false
          return true
        else
          return false
        end
      end
    else
      self["is-moving"] = false
      return false
    end
  end
  Anime.update = function(self, ...)
    if (self["path-cooldown"] > 0) then
      self["path-cooldown"] = (self["path-cooldown"] - 1)
    else
    end
    self:ia(...)
    self["request-path"](self)
    return self["move-along-path"](self)
  end
  Anime.draw = function(self, draw_x, draw_y)
    local x = (draw_x or self.x)
    local y = (draw_y or self.y)
    local sid
    if self["is-moving"] then
      if (((time() // 150) % 2) == 0) then
        sid = self["sprite-idle"]
      else
        sid = self["sprite-walk"]
      end
    else
      sid = self["sprite-idle"]
    end
    return spr(sid, x, y, 0, 1, self.flip)
  end
  return Anime
end
package.preload["src.aStar"] = package.preload["src.aStar"] or function(...)
  local path = nil
  local function heuristic(a, b)
    return (math.abs((a.x - b.x)) + math.abs((a.y - b.y)))
  end
  local function same_pos_3f(a, b)
    return ((a.x == b.x) and (a.y == b.y))
  end
  local function walkable_3f(x, y)
    local tile = mget(x, y)
    return (tile ~= 0)
  end
  local function reconstruct_path(node)
    local p = {}
    local curr = node
    while curr do
      table.insert(p, 1, {x = curr.x, y = curr.y})
      curr = curr.parent
    end
    return p
  end
  local function a_star(depart, destination)
    local case_a_visite = {{x = depart.x, y = depart.y, g = 0, h = heuristic(depart, destination), f = 0}}
    local case_visitee = {}
    local final_path = nil
    local iterations = 0
    while ((#case_a_visite > 0) and not final_path) do
      iterations = (iterations + 1)
      if (iterations > 500) then
        trace("STOP: Trop d'iterations !")
        break
      else
      end
      local current_idx = 1
      for i = 2, #case_a_visite do
        if (case_a_visite[i].f < case_a_visite[current_idx].f) then
          current_idx = i
        else
        end
      end
      local current = table.remove(case_a_visite, current_idx)
      if same_pos_3f(current, destination) then
        final_path = reconstruct_path(current)
      else
        case_visitee[(current.x .. ":" .. current.y)] = true
        for _, _4_ in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
          local dx = _4_[1]
          local dy = _4_[2]
          local nx = (current.x + dx)
          local ny = (current.y + dy)
          if not walkable_3f(nx, ny) then
          elseif case_visitee[(nx .. ":" .. ny)] then
          else
            local neighbor = {x = nx, y = ny, g = (current.g + 1), h = heuristic({x = nx, y = ny}, destination), parent = current}
            neighbor.f = (neighbor.g + neighbor.h)
            local skip_3f = false
            for _0, node in ipairs(case_a_visite) do
              if (same_pos_3f(node, neighbor) and (node.g <= neighbor.g)) then
                skip_3f = true
              else
              end
            end
            if not skip_3f then
              table.insert(case_a_visite, neighbor)
            else
            end
          end
        end
      end
    end
    if not final_path then
      trace("ECHEC: Liste vide, aucun chemin trouv\195\169.")
    else
    end
    return final_path
  end
  return {["a-star"] = a_star, heuristic = heuristic, ["walkable?"] = walkable_3f, ["same-pos?"] = same_pos_3f}
end
player_cls = require("src.player.player")
local attack
package.preload["src.player.attack"] = package.preload["src.player.attack"] or function(...)
  local DUREE = 12
  local NB_PHASES = 3
  local PHASES = {right = {{dx = 8, dy = -8, fl = 0, ro = 0}, {dx = 10, dy = 0, fl = 0, ro = 0}, {dx = 8, dy = 8, fl = 2, ro = 0}}, left = {{dx = -8, dy = -8, fl = 1, ro = 0}, {dx = -10, dy = 0, fl = 1, ro = 0}, {dx = -8, dy = 8, fl = 3, ro = 0}}, up = {{dx = -8, dy = -8, fl = 0, ro = 0}, {dx = 0, dy = -10, fl = 0, ro = 0}, {dx = 8, dy = -8, fl = 0, ro = 0}}, down = {{dx = 8, dy = 8, fl = 2, ro = 0}, {dx = 0, dy = 10, fl = 2, ro = 0}, {dx = -8, dy = 8, fl = 2, ro = 0}}}
  local function start(player, weapon)
    if not player["attack-state"].active then
      player["attack-state"].active = true
      player["attack-state"].frame = 0
      player["attack-state"].weapon = weapon
      return nil
    else
      return nil
    end
  end
  local function update(player)
    if player["attack-state"].active then
      player["attack-state"].frame = (player["attack-state"].frame + 1)
      if (player["attack-state"].frame >= DUREE) then
        player["attack-state"].active = false
        player["attack-state"].frame = 0
        player["attack-state"].weapon = nil
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  local function draw(player, screen_w, screen_h)
    if (player["attack-state"].active and (player["attack-state"].weapon ~= nil)) then
      local weapon = player["attack-state"].weapon
      local phases = PHASES[player.direction]
      local phase = math.min((NB_PHASES - 1), ((player["attack-state"].frame * NB_PHASES) // DUREE))
      local off = phases[(phase + 1)]
      local cx = ((screen_w / 2) - 4)
      local cy = ((screen_h / 2) - 4)
      return spr(weapon["sprite-id"], (cx + off.dx), (cy + off.dy), 0, 1, off.fl, off.ro)
    else
      return nil
    end
  end
  return {start = start, update = update, draw = draw}
end
attack = require("src.player.attack")
local weapon
package.preload["src.weapon.weapon"] = package.preload["src.weapon.weapon"] or function(...)
  local function make_weapon(id, name, sprite_id, stats)
    return {category = "arme", id = id, name = name, ["sprite-id"] = sprite_id, degats = (stats.degats or 0), portee = (stats.portee or 1), vitesse = (stats.vitesse or 1), critique = (stats.critique or 0), ranged = (stats.ranged or false), ["vitesse-projectile"] = (stats["vitesse-projectile"] or 0), ["sprite-projectile"] = (stats["sprite-projectile"] or 0)}
  end
  local EPEE = make_weapon("epee", "\195\137p\195\169e", 299, {degats = 10, portee = 1, vitesse = 1, critique = 5})
  local ARBALETE = make_weapon("arbalete", "Arbal\195\168te", 300, {degats = 8, portee = 20, vitesse = 1, critique = 10, ranged = true, ["vitesse-projectile"] = 5, ["sprite-projectile"] = 315})
  local TOUTES = {EPEE, ARBALETE}
  local function equiper(player, weapon)
    player["equipped-weapon"] = weapon
    return nil
  end
  local function desequiper(player)
    player["equipped-weapon"] = nil
    return nil
  end
  local function cycle(player)
    local current = player["equipped-weapon"]
    if (current == nil) then
      return equiper(player, TOUTES[1])
    else
      local next_idx = nil
      for i, w in ipairs(TOUTES) do
        if (w.id == current.id) then
          next_idx = (i + 1)
        else
        end
      end
      if ((next_idx == nil) or (next_idx > #TOUTES)) then
        return desequiper(player)
      else
        return equiper(player, TOUTES[next_idx])
      end
    end
  end
  local function attaquer(player, attack_module, proj_module)
    local weapon = player["equipped-weapon"]
    if (weapon ~= nil) then
      if weapon.ranged then
        return proj_module.fire(player, weapon)
      else
        return attack_module.start(player, weapon)
      end
    else
      return nil
    end
  end
  return {["make-weapon"] = make_weapon, equiper = equiper, desequiper = desequiper, cycle = cycle, attaquer = attaquer, EPEE = EPEE, ARBALETE = ARBALETE, TOUTES = TOUTES}
end
weapon = require("src.weapon.weapon")
local projectile
package.preload["src.weapon.projectile"] = package.preload["src.weapon.projectile"] or function(...)
  local actifs = {}
  local DIRS = {right = {dx = 1, dy = 0}, left = {dx = -1, dy = 0}, up = {dx = 0, dy = -1}, down = {dx = 0, dy = 1}}
  local DIR_SPR = {right = {fl = 0, ro = 3}, left = {fl = 0, ro = 1}, up = {fl = 3, ro = 0}, down = {fl = 0, ro = 0}}
  local function fire(player, weapon)
    local dir = DIRS[player.direction]
    local spr_dir = DIR_SPR[player.direction]
    return table.insert(actifs, {x = (player.x + 4), y = (player.y + 4), dx = dir.dx, dy = dir.dy, fl = spr_dir.fl, ro = spr_dir.ro, speed = weapon["vitesse-projectile"], degats = weapon.degats, ["portee-px"] = (weapon.portee * 8), parcouru = 0, ["sprite-id"] = weapon["sprite-projectile"]})
  end
  local function update()
    local i = 1
    while (i <= #actifs) do
      local p = actifs[i]
      p.x = (p.x + (p.dx * p.speed))
      p.y = (p.y + (p.dy * p.speed))
      p.parcouru = (p.parcouru + p.speed)
      if (p.parcouru >= p["portee-px"]) then
        table.remove(actifs, i)
      else
        i = (i + 1)
      end
    end
    return nil
  end
  local function draw(cam_x, cam_y)
    for _, p in ipairs(actifs) do
      spr(p["sprite-id"], (p.x - cam_x - 4), (p.y - cam_y - 4), 0, 1, p.fl, p.ro)
    end
    return nil
  end
  return {fire = fire, update = update, draw = draw, actifs = actifs}
end
projectile = require("src.weapon.projectile")
local hud
package.preload["src.hud"] = package.preload["src.hud"] or function(...)
  local BAR_W = 48
  local BAR_H = 8
  local SLOT_W = 8
  local SLOT_H = 8
  local SEP = 4
  local PAD_X = 2
  local PAD_Y = 2
  local PANEL_H = 12
  local function hp_color(ratio)
    if (ratio > 0.6) then
      return 6
    elseif (ratio > 0.3) then
      return 4
    else
      return 2
    end
  end
  local function draw_hp(bx, by, hp, max_hp)
    local ratio = math.max(0, math.min(1, (hp / max_hp)))
    local fill_w = math.floor(((BAR_W - 2) * ratio))
    local col = hp_color(ratio)
    local label = (hp .. "/" .. max_hp)
    rect(bx, by, BAR_W, BAR_H, 0)
    rectb(bx, by, BAR_W, BAR_H, 5)
    if (fill_w > 0) then
      rect((bx + 1), (by + 1), fill_w, (BAR_H - 2), col)
    else
    end
    local lw = (#label * 5)
    local lx = (bx + math.max(1, ((BAR_W - lw) // 2)))
    local _40_
    if (ratio > 0.3) then
      _40_ = 12
    else
      _40_ = 7
    end
    return print(label, lx, (by + 2), _40_, false, 1, true)
  end
  local function draw_weapon_slot(sx, sy, weapon)
    rect(sx, sy, SLOT_W, SLOT_H, 0)
    rectb(sx, sy, SLOT_W, SLOT_H, 5)
    if (weapon ~= nil) then
      return spr(weapon["sprite-id"], sx, sy, 0)
    else
      return print("-", (sx + 2), (sy + 2), 5, false, 1, true)
    end
  end
  local function draw(player, screen_w, screen_h)
    local panel_w = ((2 * PAD_X) + BAR_W + SEP + SLOT_W)
    local panel_x = 3
    local panel_y = (screen_h - PANEL_H - 2)
    rect(panel_x, panel_y, panel_w, PANEL_H, 0)
    rectb(panel_x, panel_y, panel_w, PANEL_H, 5)
    draw_hp((panel_x + PAD_X), (panel_y + PAD_Y), player.hp, player["max-hp"])
    return draw_weapon_slot((panel_x + PAD_X + BAR_W + SEP), (panel_y + PAD_Y), player["equipped-weapon"])
  end
  local function draw_inventory_panel(inv, ressources, screen_w, screen_h)
    local nb = #ressources
    local panel_w = 90
    local row_h = 10
    local panel_h = (14 + (nb * row_h))
    local panel_x = ((screen_w // 2) - (panel_w // 2))
    local panel_y = ((screen_h // 2) - (panel_h // 2))
    rect(panel_x, panel_y, panel_w, panel_h, 0)
    rectb(panel_x, panel_y, panel_w, panel_h, 12)
    print("Inventaire", (panel_x + 4), (panel_y + 3), 12, false, 1, false)
    line(panel_x, (panel_y + 11), (panel_x + panel_w), (panel_y + 11), 5)
    for i, res in ipairs(ressources) do
      local ry = (panel_y + 13 + ((i - 1) * row_h))
      local q = (inv.stacks[res.id] or 0)
      spr(res["sprite-id"], (panel_x + 4), ry, 0)
      local _43_
      if (q > 0) then
        _43_ = 12
      else
        _43_ = 5
      end
      print(res.name, (panel_x + 14), (ry + 1), _43_, false, 1, false)
      local qstr = tostring(q)
      local qw = (#qstr * 6)
      local _45_
      if (q > 0) then
        _45_ = 12
      else
        _45_ = 5
      end
      print(qstr, ((panel_x + panel_w) - qw - 4), (ry + 1), _45_, false, 1, false)
    end
    return nil
  end
  local function draw_weapon_stats(weapon, screen_w, screen_h)
    if (weapon ~= nil) then
      local panel_w = 70
      local panel_h = 42
      local panel_x = (screen_w - panel_w - 3)
      local panel_y = ((screen_h // 2) - (panel_h // 2))
      rect(panel_x, panel_y, panel_w, panel_h, 0)
      rectb(panel_x, panel_y, panel_w, panel_h, 12)
      print(weapon.name, (panel_x + 4), (panel_y + 3), 12, false, 1, false)
      line(panel_x, (panel_y + 11), (panel_x + panel_w), (panel_y + 11), 5)
      local stats = {{"degats", "Degats"}, {"portee", "Portee"}, {"vitesse", "Vitesse"}, {"critique", "Critique"}}
      for i, _47_ in ipairs(stats) do
        local key = _47_[1]
        local label = _47_[2]
        local ry = (panel_y + 13 + ((i - 1) * 8))
        local val = tostring(weapon[key])
        print(label, (panel_x + 4), ry, 5, false, 1, true)
        print(val, ((panel_x + panel_w) - (#val * 4) - 4), ry, 12, false, 1, true)
      end
      return nil
    else
      return nil
    end
  end
  return {draw = draw, ["draw-inventory-panel"] = draw_inventory_panel, ["draw-weapon-stats"] = draw_weapon_stats}
end
hud = require("src.hud")
local Civil
package.preload["src.pnj.civil"] = package.preload["src.pnj.civil"] or function(...)
  local Anime = require("src.pnj.anime")
  local astar = require("src.aStar")
  local Civil = {}
  Civil.__index = Civil
  setmetatable(Civil, {__index = Anime})
  local TILE_SIZE = 8
  local LST_NAME = {"Alice", "Gauthier", "Anthony", "Lucas", "Marie", "Lynn", "Quentin", "S\195\169bastien", "Flora", "Claire"}
  local LST_DIALOG = {"Salut, je peux me joindre \195\160 toi ?", "Fais attention, il y a des dangers dans les environs.", "Je suis \195\160 la recherche de ressources, tu en as peut-\195\170tre \195\160 partager ?", "Tu devrais \195\169viter la zone nord, c'est infest\195\169 de cr\195\169atures.", "Je pensais que j'\195\169tais seul, mais je suis content de te voir.", "Je suis \195\160 la recherche d'un groupe de survivants, tu en fais partie ?", "Je suis un ancien m\195\169decin, je peux peut-\195\170tre t'aider si tu es bless\195\169."}
  Civil["define-stat"] = function(self, distance, max_dist)
    local min_possible = 1
    local max_possible = 100
    local spread = 20
    local dist_factor = (math.min(distance, max_dist) / max_dist)
    local low_bound = (min_possible + (dist_factor * (max_possible - spread)))
    local high_bound = (low_bound + spread)
    local raw_stat = math.random(math.floor(low_bound), math.floor(high_bound))
    return math.max(min_possible, math.min(max_possible, raw_stat))
  end
  Civil.new = function(x, y)
    local px = (x or math.random(0, 240))
    local py = (y or math.random(0, 136))
    local self = Anime.new(px, py, 0.5, 258, 259)
    setmetatable(self, Civil)
    self.name = LST_NAME[math.random(1, #LST_NAME)]
    self.dialog = LST_DIALOG[math.random(1, #LST_DIALOG)]
    do
      local dist_base = astar.heuristic({x = 120, y = 68}, {x = self.x, y = self.y})
      local max_dist = 40
      self.construction = self["define-stat"](self, dist_base, max_dist)
      self.recolte = self["define-stat"](self, dist_base, max_dist)
    end
    self.batiment = nil
    self.state = "idle"
    self["wander-cooldown"] = math.random(60, 180)
    return self
  end
  Civil.ia = function(self, is_night)
    if (self.state == "at-work") then
      return nil
    elseif (self.batiment and (self.state == "moving")) then
      if not self.destination then
        self.destination = {x = self.batiment.x, y = self.batiment.y}
      else
      end
      if (not self.destination and not self.path) then
        self.state = "at-work"
        return nil
      else
        return nil
      end
    else
      if (self["wander-cooldown"] > 0) then
        self["wander-cooldown"] = (self["wander-cooldown"] - 1)
      else
      end
      if ((self["wander-cooldown"] <= 0) and not self.destination and not self.path) then
        local radius = (math.random(2, 3) * 8)
        local angle = (math.random(0, 628) * 0.01)
        local tx = math.max(0, math.min(504, (self.x + (radius * math.cos(angle)))))
        local ty = math.max(0, math.min(504, (self.y + (radius * math.sin(angle)))))
        self.destination = {x = tx, y = ty}
        self["wander-cooldown"] = math.random(180, 360)
        return nil
      else
        return nil
      end
    end
  end
  Civil.update = function(self, is_night)
    return Anime.update(self, is_night)
  end
  Civil.draw = function(self, cam_x, cam_y)
    local sx = (self.x - cam_x)
    local sy = (self.y - cam_y)
    if ((sx > -8) and (sx < 240) and (sy > -8) and (sy < 136)) then
      return Anime.draw(self, sx, sy)
    else
      return nil
    end
  end
  Civil["assign-building"] = function(self, building)
    self.batiment = building
    self.state = "moving"
    self.path = nil
    self.destination = nil
    self["path-cooldown"] = 0
    return nil
  end
  return Civil
end
Civil = require("src.pnj.civil")
local screen_w = 240
local screen_h = 136
local p1 = player_cls.new(120, 68)
local world = {time = 0, ["day-duration"] = 120, ["night-duration"] = 120, ["is-night"] = false}
local sauvegardeWorld = {["is-night"] = false}
local initialized = false
local inventory_open = false
local civils = {}
local function pal(c0, c1)
  if (c0 ~= nil) then
    return poke4((32736 + c0), c1)
  else
    for i = 0, 15 do
      poke4((32736 + i), i)
    end
    return nil
  end
end
local function update_world()
  world.time = (world.time + 1)
  do
    local total = (world["day-duration"] + world["night-duration"])
    local current = (world.time % total)
    sauvegardeWorld["is-night"] = world["is-night"]
    world["is-night"] = (current >= world["day-duration"])
  end
  if (not (world["is-night"] == sauvegardeWorld["is-night"]) and sauvegardeWorld["is-night"] and (#civils < 15)) then
    return table.insert(civils, Civil.new())
  else
    return nil
  end
end
local function get_camera()
  return (p1.x - (screen_w / 2)), (p1.y - (screen_h / 2))
end
local function draw_map_view(cam_x, cam_y)
  local cell_x = (cam_x // 8)
  local cell_y = (cam_y // 8)
  local offset_x = ( - (cam_x % 8))
  local offset_y = ( - (cam_y % 8))
  return map(cell_x, cell_y, 31, 18, offset_x, offset_y)
end
local function apply_night_filter()
  pal(12, 13)
  pal(13, 14)
  pal(5, 10)
  pal(6, 9)
  pal(7, 0)
  pal(4, 14)
  pal(3, 1)
  pal(8, 2)
  pal(11, 10)
  return pal(10, 9)
end
local function init_test_map()
  for x = 0, 63 do
    for y = 0, 63 do
      mset(x, y, math.random(13, 15))
    end
  end
  return nil
end
local function init_civils()
  for _ = 1, 3 do
    local cx = (math.random(5, 25) * 8)
    local cy = (math.random(5, 15) * 8)
    table.insert(civils, Civil.new(cx, cy))
  end
  return nil
end
local function handle_inputs()
  if btnp(4) then
    weapon.attaquer(p1, attack, projectile)
  else
  end
  if btnp(6) then
    inventory_open = not inventory_open
  else
  end
  if btnp(7) then
    weapon.cycle(p1)
  else
  end
  if btnp(5) then
    for _, c in ipairs(civils) do
      if not c.batiment then
        Civil["assign-building"](c, {x = p1.x, y = p1.y})
        trace((c.name .. " re\195\167oit un b\195\162timent !"))
        break
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function _62_()
  if not initialized then
    init_test_map()
    init_civils()
    initialized = true
  else
  end
  p1:update()
  update_world()
  handle_inputs()
  attack.update(p1)
  projectile.update()
  for _, c in ipairs(civils) do
    Civil.update(c, world["is-night"])
  end
  pal()
  if world["is-night"] then
    apply_night_filter()
  else
  end
  cls(0)
  do
    local cam_x, cam_y = get_camera()
    draw_map_view(cam_x, cam_y)
    projectile.draw(cam_x, cam_y)
    for _, c in ipairs(civils) do
      Civil.draw(c, cam_x, cam_y)
    end
    attack.draw(p1, screen_w, screen_h)
    p1:draw(screen_w, screen_h)
  end
  pal()
  hud.draw(p1, screen_w, screen_h)
  if inventory_open then
    hud["draw-inventory-panel"](p1.inventory, item.RESSOURCES, screen_w, screen_h)
    return hud["draw-weapon-stats"](p1["equipped-weapon"], screen_w, screen_h)
  else
    return nil
  end
end
TIC = _62_
return nil
