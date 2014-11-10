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

  for i = 0, 39 do
    for j = 0, 39 do
      if ((i+j) % 2 == 0) then
        assets.createTileEntity(world, 'assets/images/grass.png', i, j)
      else
        assets.createTileEntity(world, 'assets/images/rock.png', i, j) end
    end
  end

  local text = ""

  local textEntity = world:createEntity()
  world:addComponent(textEntity, geometry.Positionable:new(10, 10))
  world:addComponent(textEntity, geometry.Dimensionable:new(130, 30))
  world:addComponent(
    textEntity,
    gui.Element:new{
      draw = function (gui, canvas)
        local backColor = { r = 64, g = 64, b = 64 }

        if gui:hasFocus() then
          backColor = { r = 128, g = 128, b = 128 }
        end

        canvas:
          drawRectangle{
            x = 0, y = 0,
            width = 120, height = 20,
            fillColor = backColor,
            strokeColor = { r = 255, g = 255, b = 255 }
          }:
          drawText{
            text = text,
            color = { r = 255, g = 255, b = 255 },
            x = -2, y = -5,
            width = 90
          }
      end,
      onClick = function (gui) gui:focus() end,
      onKeyDown = function (wrapper, key)
        if key == "backspace" then
          text = text:sub(1, -2)
        elseif #key == 1 then
          text = text .. key
        end
      end
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
