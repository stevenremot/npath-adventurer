require('luarocks.loader')
local parser = require('src.parser.lua')

local ast = nil

function love.load()
   ast = parser.parseDir('src/')
end

function love.draw()
   love.graphics.printf(ast:toString(), 10, 10, 600)
end
