-- ast.lua
--
-- Defines the data structures that represents the codebase

--------------------------------------------------------------------------------
--- A code unit is an abstract unit representing some entity in the code
local CodeUnit = {}

--- Return true when the unit is a code space
--
-- Overriden by subtypes
function CodeUnit:isCodespace()
   return false
end
--- Return true when the unit is a function
--
-- Overriden by subtypes
function CodeUnit:isFunction()
   return false
end
--- Return true when the unit is a value
--
-- Overriden by subtypes
function CodeUnit:isValue()
   return false
end

--- Return the code unit complexity
function CodeUnit:getComplexity()
   return 0
end

--------------------------------------------------------------------------------
--- A codespace is a code unit that contains other entities.
--
-- Depending on the language, this can be a file, a namespace, a
-- class, a struct, etc...
local Codespace = {}
setmetatable(
   Codespace,
   {
      __index = CodeUnit
   }
)

local MetaCodespace = {}

--- Create a new codespace
--
-- @param name A string representing the codespace's name
function Codespace:new(name)
   local object = {
      name = name,
      components = {},
      _complexityCache = nil
   }

   setmetatable(object, MetaCodespace)
   return object
end

--- Add a component to the codespace
--
-- @param component It can be any code unit.
function Codespace:addComponent(component)
   table.insert(self.components, component)
   self.complexityCache = nil
end

function Codespace:getComplexity()
   if self._complexityCache == nil then
      local complexity = 0

      for _, component in pairs(self.components) do
         complexity = complexity + component:getComplexity()
      end

      self._complexityCache = complexity
   end

   return self._complexityCache
end

function Codespace:isCodespace()
   return true
end

function Codespace:toString()
   local s = "Code space " .. self.name

   local elements = {}
   for _, component in pairs(self.components) do
      table.insert(elements, component:toString())
   end

   return s .. " [" .. table.concat(elements, ", ") .. "]"
end

MetaCodespace.__index = Codespace
MetaCodespace.__tostring = Codespace.toString

--------------------------------------------------------------------------------
--- A function is a code unit representing a code function or method.
local Function = {}
setmetatable(
   Function,
   {
      __index = CodeUnit
   }
)

local MetaFunction = {}

--- Create a new function
--
-- @param name       A string representing the function's name
-- @param complexity A number representing in some way the function's complexity.
--                   This can be the number of lines, the NPath complexity, etc...
function Function:new(name, complexity)
   local object = {
      name = name,
      complexity = complexity
   }

   setmetatable(object, MetaFunction)
   return object
end

function Function:isFunction()
   return true
end

function Function:getComplexity()
   return self.complexity
end

function Function:toString()
   return "Function " .. self.name .. " (".. self.complexity .. ")"
end

MetaFunction.__index = Function
MetaFunction.__tostring = Function.toString

--------------------------------------------------------------------------------
--- A value is a code unit representing an association between a name and a data
local Value = {}
setmetatable(
   Value,
   {
      __index = CodeUnit
   }
)

local MetaValue = {}

--- Create a new value
--
-- @param name A string representing the value's name
function Value:new(name)
   local object = {
      name = name
   }

   setmetatable(object, MetaValue)
   return object
end

function Value:getComplexity()
  return 1
end

function Value:isValue()
   return true
end

function Value:toString()
   return "Value " .. self.name
end

MetaValue.__index = Value
MetaValue.__tostring = Value.toString

return {
   Codespace = Codespace,
   Function = Function,
   Value    = Value
}
