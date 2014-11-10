require('luarocks.loader')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')
local geometry = require('src.geometry')
local assets   = require('src.assets')
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
local guiSystem = gui.System:new(world)

function love.load()
  canvas:setFontSize(20)

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
          width = 600,
          anchor = "justify"
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

  for i = 0, 39 do
    for j = 0, 39 do
      if ((i+j) % 2 == 0) then
        assets.createTileEntity(world, 'assets/images/grass.png', i, j)
      else
        assets.createTileEntity(world, 'assets/images/rock.png', i, j) end
    end
  end


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

end

function love.draw()
  graphics.tilerender(world, canvas, viewport)
  graphics.render(world, canvas)
  guiSystem:render(canvas)
end

function love.keypressed(key)
  guiSystem:onKeyDown(key)
end

function love.mousepressed(x, y)
  guiSystem:onClick(x, y)
end

local mouseX, mouseY = 0, 0

function love.update()
  local x, y = love.mouse.getPosition()

  if x ~= mouseX or y ~= mouseY then
    guiSystem:onMouseMove(x, y)
    mouseX, mouseY = x, y
  end
end
