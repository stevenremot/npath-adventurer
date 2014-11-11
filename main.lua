require('luarocks.loader')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')
local geometry = require('src.geometry')
local assets   = require('src.assets')
local segmentation = require('src.generation.segmentation')
local overworld = require('src.generation.overworld')
local gui      = require('src.gui')
local sprite = require('src.sprite')

local world = ecs.World:new()
local canvas = graphics.base.Canvas:new{
  screen = {
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight()
  },
  canvas = {
    width = 800,
    height = 600
  }
}
local viewport = graphics.tile.Viewport:new(0, 0, 20, 15)
viewportSpeed = { x = 0, y = 0, value = 5 }

local guiSystem = gui.System:new(world)
local tileRenderSystem = graphics.tile.TileRenderSystem:new(world)

local gummySprite = nil

function love.load()
  canvas:setFontSize(20)
  assets.loadSprites()

  local ast = parser.parseDir('src/')
  seg = segmentation.segmentCodeSpace(ast, { minComplexity = 10, maxComplexity = 20, dungeonRatio = 0 })
  map = overworld.generateOverworld(seg.overworld, world, tileRenderSystem.index)
  map:toEntities(world, tileRenderSystem.index)

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
  gummySprite = assets.createSprite('gummy')

  local gummy = world:createEntity()
  local pos = geometry.TilePositionable:new(10, 10, 0, 1)
  world:addComponent(
    gummy,
    pos
  )
  world:addComponent(
    gummy,
    geometry.TileDimensionable:new(40, 80)
  )
  world:addComponent(
    gummy,
    graphics.base.Renderable:new(function (canvas)
        canvas:drawImage{
          image = gummySprite,
          x = 0,
          y = 0
        }
    end)
  )
  tileRenderSystem.index:register(gummy, pos)

end

function love.draw()
  tileRenderSystem:render(canvas, viewport)
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
    gummySprite:setAnimation(1)
  elseif key == "up" then
    viewportSpeed.y = math.max(-v, viewportSpeed.y - v)
    gummySprite:setAnimation(4)
  elseif key == "left" then
    viewportSpeed.x = math.max(-v, viewportSpeed.x - v)
    gummySprite:setAnimation(3)
  elseif key == "right" then
    viewportSpeed.x = math.min(v, viewportSpeed.x + v)
    gummySprite:setAnimation(2)
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
local increment = 0
local delay = 1 / 10

function love.update(dt)
  viewport:translate(viewportSpeed.x * dt, viewportSpeed.y * dt)

  local x, y = love.mouse.getPosition()

  if x ~= mouseX or y ~= mouseY then
    guiSystem:onMouseMove(x, y)
    mouseX, mouseY = x, y
  end

  increment = increment + dt
  while increment > delay do
    increment = increment - delay
    gummySprite:nextStep()
  end
end
