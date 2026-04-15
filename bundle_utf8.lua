local player
package.preload["src.player"] = package.preload["src.player"] or function(...)
  local sprite_idle = 2
  local sprite_walk = 3
  local player = {x = 120, y = 68, speed = 2, radius = 4, ["is-moving"] = false}
  player.update = function(screen_w, screen_h)
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
    player["is-moving"] = ((dx ~= 0) or (dy ~= 0))
    local current_speed = player.speed
    if ((dx ~= 0) and (dy ~= 0)) then
      current_speed = (player.speed * 0.707)
    else
    end
    player.x = (player.x + (dx * current_speed))
    player.y = (player.y + (dy * current_speed))
    return nil
  end
  player.draw = function(screen_w, screen_h)
    local x = ((screen_w / 2) - 4)
    local y = ((screen_h / 2) - 4)
    local sprite_id
    if player["is-moving"] then
      if (((time() // 150) % 2) == 0) then
        sprite_id = sprite_idle
      else
        sprite_id = sprite_walk
      end
    else
      sprite_id = sprite_idle
    end
    return spr(sprite_id, x, y, 0)
  end
  return player
end
player = require("src.player")
local screen_w = 240
local screen_h = 136
local initialized = false
local function get_camera()
  local cam_x = (player.x - (screen_w / 2))
  local cam_y = (player.y - (screen_h / 2))
  return cam_x, cam_y
end
local function draw_map_view(cam_x, cam_y)
  local cell_x = (cam_x // 8)
  local cell_y = (cam_y // 8)
  local offset_x = ( - (cam_x % 8))
  local offset_y = ( - (cam_y % 8))
  return map(cell_x, cell_y, 31, 18, offset_x, offset_y)
end
local function init_test_map()
  for x = 0, 63 do
    for y = 0, 63 do
      if (math.random(0, 10) == 0) then
        mset(x, y, 1)
      else
        mset(x, y, 0)
      end
    end
  end
  return nil
end
local function _9_()
  if not initialized then
    init_test_map()
    initialized = true
  else
  end
  player.update(screen_w, screen_h)
  cls(12)
  local cam_x, cam_y = get_camera()
  draw_map_view(cam_x, cam_y)
  return player.draw(screen_w, screen_h)
end
TIC = _9_
return nil
