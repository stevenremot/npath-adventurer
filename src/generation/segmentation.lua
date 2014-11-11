-- segmentation.lua
--
-- Segmentation of the code tree to get a codebase per environment
local ast = require('src.parser.ast')

--------------------------------------------------------------------------------
--- Check whether a codespace can be split or not
--
-- A code space can be split when it only contains code spaces
--
-- @param codeSpace
--
-- @return true if it can be split, false otherwise
local function canSplit(codeSpace)
  for _, component in pairs(codeSpace.components) do
    if not component:isCodespace() then
      return false
    end
  end
  return true
end

--------------------------------------------------------------------------------
--- Split the set of codeSpaces so that no root codeSpace has a complexity greter than max
--
-- @param codeSpaces
-- @param maxCOmplexity
--
-- @return A new set of codeSpaces
local function splitCodeSpaces(codeSpaces, maxComplexity)
  local hasSplitCodeSpaces = false
  local splitSet = {}

  for _, codeSpace in ipairs(codeSpaces) do
    if codeSpace:getComplexity() > maxComplexity and canSplit(codeSpace) then
      hasSplitCodeSpaces = true
      for _, component in ipairs(codeSpace.components) do
        component.name = codeSpace.name .. "/" .. component.name
        table.insert(splitSet, component)
      end
    else
      table.insert(splitSet, codeSpace)
    end
  end

  if hasSplitCodeSpaces then
    return splitCodeSpaces(splitSet, maxComplexity)
  else
    return splitSet
  end
end

--------------------------------------------------------------------------------
--- Separate the code spaces by a complexity threshold
local function sliceByComplexity(codeSpaces, threshold)
  local tinyCodeSpaces = {}
  local bigCodeSpaces = {}
  for _, codeSpace in ipairs(codeSpaces) do
    if codeSpace:getComplexity() < threshold then
      table.insert(tinyCodeSpaces, codeSpace)
    else
      table.insert(bigCodeSpaces, codeSpace)
    end
  end

  return tinyCodeSpaces, bigCodeSpaces
end

--------------------------------------------------------------------------------
--- Merge tiny codespaces on by one
local function mergeTinyCodeSpaces(tiny)
  table.sort(tiny, function (a, b)
               return a:getComplexity() > b:getComplexity()
  end)

  local mergedCodespaces = {}

  while #tiny > 1 do
    local last = table.remove(tiny)
    local first = table.remove(tiny, 1)

    local cp = ast.Codespace:new(
      last.name .. "|" .. first.name
    )
    cp.components = { last, first }
    table.insert(
      mergedCodespaces,
      cp
    )
  end

  for _, cp in ipairs(tiny) do
    table.insert(mergedCodespaces, cp)
  end

  return mergedCodespaces
end

--------------------------------------------------------------------------------
--- Merge code spaces with complexity smaller than minComplexity
--
-- @param codeSpaces
-- @param minComplexity
--
-- @return A set of codespaces
local function growCodeSpaces(codeSpaces, minComplexity)
  local tiny, big = sliceByComplexity(codeSpaces, minComplexity)

  if #tiny > 1 then
    for _, cp in ipairs(mergeTinyCodeSpaces(tiny)) do
      table.insert(big, cp)
    end
    return growCodeSpaces(big, minComplexity)
  elseif #tiny == 1 then
    table.insert(big, tiny[1])
    return big
  else
    return big
  end
end

--------------------------------------------------------------------------------
--- Segment the codeSpace to get a set of codespaces suitable to build world on
--
-- Minimal and maximal complexity rules are followed as much as
-- possible, but this exact bounds are not guaranteed.
--
-- @param codeSpace             Root of the code to segment
-- @param options.minComplexity Minimal complexity an area should have
-- @param options.maxComplexity Maximal complexity an area should have
-- @param options.dungeonRatio  Ratio of dungeons on all the areas
--
-- @return {
--   dungeons = { dungeons codeSpaces },
--   overworld = { overworld codeSpaces }
-- }
local function segmentCodeSpace(codeSpace, options)
  local codeSpaces = { codeSpace }

  codeSpaces = splitCodeSpaces(codeSpaces, options.maxComplexity)
  codeSpaces = growCodeSpaces(codeSpaces, options.minComplexity)

  local dungeons = {}

  for _ = 1, math.ceil(#codeSpaces * options.dungeonRatio) do
    table.insert(dungeons, table.remove(codeSpaces, #codeSpaces))
  end

  return {
    dungeons = dungeons,
    overworld = codeSpaces
  }
end

return {
  segmentCodeSpace = segmentCodeSpace
}
