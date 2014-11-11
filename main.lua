require('luarocks.loader')
require('profiler')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')
local geometry = require('src.geometry')
local assets   = require('src.assets')
local segmentation = require('src.generation.segmentation')
local overworld = require('src.generation.overworld')
local gui      = require('src.gui')

local world = ecs.World:new()
local canvas = graphics.Canvas:new{
  screen = {
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight()
  },
  canvas = {
    width = 800,
    height = 600
  }
}
local viewport = graphics.Viewport:new(0, 0, 20, 15)
viewportSpeed = { x = 0, y = 0, value = 5 }

local guiSystem = gui.System:new(world)

function love.load()
  canvas:setFontSize(20)

  local ast = parser.parseDir('src/')
  seg = segmentation.segmentCodeSpace(ast, { minComplexity = 10, maxComplexity = 20, dungeonRatio = 0 })
  map = overworld.generateOverworld(seg.overworld)
  map:toEntities(world)

  local entity = world:createEntity()
  world:addComponent(
    entity,
    graphics.Renderable:new(
      function (canvas)
        canvas:translate(100, 100):
        drawText{
          text = seg.overworld[1]:toString(),
          color = { r = 255, g = 255, b = 255 },
          x = 10, y = 10,
          width = 600,
          anchor = "justify"
        }
      end
    )
  )

  gui.createButton(
    world,
    {
      action = function () print("Clicked") end,
      text = "Click here",
      x = 20, y = 20,
      width = 200, height = 50,
      fillColor = { r = 64, g = 0, b = 0 },
      strokeColor = { r = 255, g = 255, b = 255 }
    }
  )

  profiler.start('out.log')
end

function love.draw()
  graphics.tilerender(world, canvas, viewport)
  -- graphics.render(world, canvas)
  guiSystem:render(canvas)

  love.graphics.print(
    love.timer.getFPS() .. "",
    0,
    0
  )
end

function love.keypressed(key)
  local v = viewportSpeed.value
  if key == "down" then
    viewportSpeed.y = math.min(v, viewportSpeed.y + v)
  elseif key == "up" then
    viewportSpeed.y = math.max(-v, viewportSpeed.y - v)
  elseif key == "left" then
    viewportSpeed.x = math.max(-v, viewportSpeed.x - v)
  elseif key == "right" then
    viewportSpeed.x = math.min(v, viewportSpeed.x + v)
  end
  guiSystem:onKeyDown(key)
end

function love.mousepressed(x, y)
  guiSystem:onClick(x, y)
end

function love.keyreleased(key)
  local v = viewportSpeed.value
  if key == "down" then
    viewportSpeed.y = math.max(-v, viewportSpeed.y - v)
  elseif key == "up" then
    viewportSpeed.y = math.min(v, viewportSpeed.y + v)
  elseif key == "left" then
    viewportSpeed.x = math.min(v, viewportSpeed.x + v)
  elseif key == "right" then
    viewportSpeed.x = math.max(-v, viewportSpeed.x - v)
  end
end

local mouseX, mouseY = 0, 0

function love.update(dt)
  viewport:translate(viewportSpeed.x * dt, viewportSpeed.y * dt)

  local x, y = love.mouse.getPosition()

  if x ~= mouseX or y ~= mouseY then
    guiSystem:onMouseMove(x, y)
    mouseX, mouseY = x, y
  end
end

function love.quit()
  -- profiler.stop()
end
