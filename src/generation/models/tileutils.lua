-- tileutils.lua
-- 
-- Functions and structures to manage tile occupation during the generation


local function tileEquality(tile1, tile2)
  return tile1[1] == tile2[1] and tile1[2] == tile2[2]
end

local function tileSum(tile1, tile2)
  return { tile1[1] + tile2[1], tile1[2] + tile2[2] }
end

local function tileSub(tile1, tile2)
  return { tile1[1] - tile2[1], tile1[2] - tile2[2] }
end

--------------------------------------------------------------------------------
--- A tilemask is a table indexed with the tiles occupied by an object or
--- an environment
--- It is modelised as a sparse matrix
local TileMask = {}
local MetaTileMask = {}

--------------------------------------------------------------------------------
--- Create a new tilemask
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
function TileMask:new(...)
  local tilemask = {}

  for _, index in ipairs{...} do
    local i, j = index[1], index[2]
    if not tilemask[i] then
      tilemask[i] = {}
    end
    tilemask[i][j] = true
  end

  setmetatable(tilemask, MetaTileMask)
  return tilemask
end

--------------------------------------------------------------------------------
--- Add tile index to a tilemask
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
function TileMask:add(...)
  for _, index in ipairs{...} do
    local i, j = index[1], index[2]
    if not self[i] then
      self[i] = {}
    end
    self[i][j] = true
  end
end

--------------------------------------------------------------------------------
--- Add a list of tile index to the tilemask
-- @param l Table of tile index: { {i,j}, {k,l}, ... }
function TileMask:addList(l)
  for _, index in ipairs(l) do
    local i, j = index[1], index[2]
    if not self[i] then
      self[i] = {}
    end
    self[i][j] = true
  end
end

--------------------------------------------------------------------------------
--- Remove tile index to a tilemask
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
function TileMask:remove(...)
  for _, index in ipairs{...} do
    local i, j = index[1], index[2]
    if not self[i] then
      break
    else
      self[i][j] = nil
      if next(self[i]) == nil then
        self[i] = nil
      end
    end
  end
end


--------------------------------------------------------------------------------
--- Check if the tilemask contains one or several tiles
-- @param ... A sequence of tile index {i,j}, {k,l}, etc
-- @return A boolean
function TileMask:contains(...)
  local b = true

  for _, index in ipairs{...} do
    local i, j = index[1], index[2]

    if not self[i] then
      b = false
      break
    else
      if not self[i][j] then
        b = false
        break
      end
    end

  end

  return b
end

--------------------------------------------------------------------------------
-- Returns a list of the TileMask's tiles 
function TileMask:toList()
  local l = {}
  for i, line in pairs(self) do
    for j, _ in pairs(line) do
      l[#l+1] = {i, j}
    end
  end
  return l
end

function TileMask:match(origin, tileList)
  local translatedList = {}
  for _, tile in ipairs(tileList) do
    table.insert(translatedList, tileSum(origin, tile))
  end
  if self:contains(unpack(translatedList)) then
    return translatedList
  else
    return nil
  end
end


MetaTileMask.__index = TileMask

--[[
t = TileMask:new({1,1}, {2,2}, {2,5})
l = t:toList()
for _, tile in ipairs(l) do
  print(tile[1], tile[2])
end
--]]

return {
  TileMask = TileMask,
  tileEquality = tileEquality,
  tileSum = tileSum,
  tileSub = tileSub
}