require('luarocks.loader')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')
local geometry = require('src.geometry')
local assets   = require('src.assets')
local segmentation = require('src.generation.segmentation')
local overworld = require('src.generation.overworld')
local gui      = require('src.gui')
local character = require('src.game.character')
local player = require('src.game.player')
local movement = require('src.movement')

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

local guiSystem = gui.System:new(world)
local tileRenderSystem = graphics.tile.TileRenderSystem:new(world)
local mapWidth, mapHeight = 0, 0

function love.load()
  canvas:setFontSize(20)
  assets.loadSprites()

  local ast = parser.parseDir('src/')
  local seg = segmentation.segmentCodeSpace(ast, { minComplexity = 10, maxComplexity = 20, dungeonRatio = 0 })
  local map = overworld.generateOverworld(seg.overworld)
  map:toEntities(world, tileRenderSystem.index)
  mapWidth, mapHeight =
    #map.tiles, #map.tiles[1]

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

  local gummy = character.createCharacter(world, "gummy", 10, 10, 0, tileRenderSystem.index)
  world:addComponent(gummy, player.Player:new())
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
  guiSystem:onKeyDown(key)
  player.onKeyDown(world, key)
end

function love.mousepressed(x, y)
  guiSystem:onClick(x, y)
end

function love.keyreleased(key)
  player.onKeyUp(world, key)
end

local mouseX, mouseY = 0, 0

function love.update(dt)
  local x, y = love.mouse.getPosition()

  if x ~= mouseX or y ~= mouseY then
    guiSystem:onMouseMove(x, y)
    mouseX, mouseY = x, y
  end

  graphics.sprite.updateSprites(world, dt, 1 / 10)
  movement.updateTileMovable(world, dt, tileRenderSystem.index)
  player.centerViewport(world, viewport)
  viewport:restrainToRectangle(
    1, 1,
    mapWidth, mapHeight
  )
end
