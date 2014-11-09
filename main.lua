require('luarocks.loader')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')

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
            canvas:translate(100, 100):drawText(
               ast:toString(),
               { r = 255, g = 255; b = 255 },
               10, 10,
               600
            )
         end
      )
   )
end

function love.draw()
   graphics.render(world, canvas)
end
