require('luarocks.loader')
local parser   = require('src.parser.lua')
local ecs      = require('src.ecs')
local graphics = require('src.graphics')
local geometry = require('src.geometry')
local assets   = require('src.assets')
local segmentation = require('src.generation.segmentation')
local overworld = require('src.generation.overworld')

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

function love.load()
  -- tilemask test
  local tilemask = overworld.TileMask:new({1,1},{1,2})
  tilemask:remove({1,1})
  tilemask:add({2,2},{2,3})
  print(tilemask:contains({1,2},{2,3}))
  print(love.math.random(1, 100))
  
  local ast = parser.parseDir('src/')
  seg = segmentation.segmentCodeSpace(ast, { minComplexity = 10, maxComplexity = 20, dungeonRatio = 0 })
  print(#seg.overworld, #seg.dungeons, seg.overworld[4]:getComplexity())

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

  for i = 0, 19 do
    for j = 0, 14 do
      if ((i+j) % 2 == 0) then
        assets.createTileEntity(world, 'assets/images/grass.png', i, j)
      else 
        assets.createTileEntity(world, 'assets/images/rock.png', i, j) end
      end
    end

  end

  function love.draw()
    graphics.tilerender(world, canvas, viewport)
    graphics.render(world, canvas)
  end


  function love.update(dt)
    for _, position in world:getEntitiesWithComponent(geometry.Positionable.TYPE) do
      position.x = position.x + dt * 10
    end
    viewport:translate(viewportSpeed.x * dt, viewportSpeed.y * dt)
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

