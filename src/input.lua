-- input.lua
-- Input handling - currently for keyboard only

--------------------------------------------------------------------------------
--- Keyboard input state
local keyboard = {
  dir = {
    x = 0,
    y = 0
  },
  attack = false
}

local guiSystem = nil

function love.keypressed(key)
  if key == "left" then
    keyboard.dir.x = keyboard.dir.x - 1
  elseif key == "right" then
    keyboard.dir.x = keyboard.dir.x + 1
  elseif key == "up" then
    keyboard.dir.y = keyboard.dir.y - 1
  elseif key == "down" then
    keyboard.dir.y = keyboard.dir.y + 1
  elseif key == "t" then
    keyboard.attack = true
  end

  if guiSystem then
    guiSystem:onKeyDown(key)
  end
end

function love.keyreleased(key)
  if key == "left" then
    keyboard.dir.x = keyboard.dir.x + 1
  elseif key == "right" then
    keyboard.dir.x = keyboard.dir.x - 1
  elseif key == "up" then
    keyboard.dir.y = keyboard.dir.y + 1
  elseif key == "down" then
    keyboard.dir.y = keyboard.dir.y - 1
  elseif key == "t" then
    keyboard.attack = false
  end
end

return {
  keyboard = keyboard,
  setGuiSystem = function (s)
    guiSystem = s
  end
}
