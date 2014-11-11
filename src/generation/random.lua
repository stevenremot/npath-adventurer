-- random.lua
--
-- Random generation routines based on love.math

local Rng = {}
local MetaRng = {}

--------------------------------------------------------------------------------
--- Create a new Rng
-- @param seed
function Rng:new(seed)
  local rng = {
    loveRng = love.math.newRandomGenerator(seed)
  }

  setmetatable(rng, MetaRng)
  return rng
end

--------------------------------------------------------------------------------
--- Random real number with uniform distribution
-- @param ... nil (for uniform [0,1] distribution)
--            min, max (for [min, max] distribution)
function Rng:randomf(...)
  if #{...} == 0 then
    return self.loveRng:random()
  elseif #{...} == 2 then
    local min, max = ...
    return min + self.loveRng:random() * (max - min)
  else
    print("Wrong argument number")
    return nil
  end
end

--------------------------------------------------------------------------------
--- Random integral number with uniform distribution
-- @param min, max (for [min, max] distribution)
function Rng:randomi(min, max)
  return self.loveRng:random(min, max)
end

--------------------------------------------------------------------------------
--- Random real number with normal distribution
-- @param mean Mean of the normal distribution
-- @param stddev Standard deviation of the normal distribution
function Rng:randomNormal(mean, stddev)
  return self.loveRng:randomNormal(stddev, mean)
end

--------------------------------------------------------------------------------
--- Random element from a list
-- @param list Table indexed from 1 to #list
-- @return random list element, its index
function Rng:randomListElement(list)
  local index = self:randomi(1, #list)
  return list[index], index
end

--------------------------------------------------------------------------------
--- Random element from a list of {element, density}
-- @param list Table of {element, density}
-- @return random list element
function Rng:randomDensityListElement(list)
  local dmax = 0
  for _, e in ipairs(list) do
    dmax = dmax + e[2]
  end

  local n = self:randomf(0, dmax)
  local d = 0
  local element = nil
  for _, e in ipairs(list) do
    element = e[1]
    d = d + e[2]
    if d > n then
      break
    end
  end

  return element
end

MetaRng.__index = Rng

local function test()
  local rng = Rng:new(15)
  local list = { {"a",1}, {"b",2}, {"c",1} }
  print(rng:randomf(), rng:randomf(2, 6), rng:randomi(5, 10), rng:randomNormal(0, 1))
  print(rng:randomListElement(list)[1])

  for _ = 1, 10 do
    print(rng:randomDensityListElement(list))
  end
end

return {
  Rng = Rng,
  test = test
}
