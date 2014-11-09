require('luarocks.loader')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')
local geometry = require('src.geometry')

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

function love.load()
  local ast = parser.parseDir('src/')
  local entity = world:createEntity()
  world:addComponent(
    entity,
    graphics.Renderable:new(
      function (canvas)
        canvas:translate(100, 100):
          drawText{
            text = ast:toString(),
            color = { r = 255, g = 255, b = 255 },
            x = 10, y = 10,
            width = 600
          }
      end
    )
  )

  local smileImage = love.graphics.newImage('assets/images/smile.png')
  local smile = world:createEntity()
  world:addComponent(
    smile,
    graphics.Renderable:new(
      function (canvas)
        canvas:drawImage{
          image = smileImage,
          x = 0,
          y = 0
        }
      end
    )
  )
  world:addComponent(
    smile,
    geometry.Positionable:new(50, 50)
  )
end

function love.draw()
  graphics.render(world, canvas)
end

function love.update(dt)
  for _, position in world:getEntitiesWithComponent(geometry.Positionable.TYPE) do
    position.x = position.x + dt * 10
  end
end
