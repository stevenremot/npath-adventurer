-- lua.lua
--
-- Defines an ast generator from a lua code base.

--------------------------------------------------------------------------------
local lfs = require('lfs')
local compiler = require('metalua.compiler'):new()

local ast = require('./ast')

--------------------------------------------------------------------------------
--- In-place appending of source to dest
local function concatAst(dest, source)
   for _, unit in pairs(source) do
      table.insert(dest, unit)
   end
end

--------------------------------------------------------------------------------
--- Create an AST function from a function unit
--
-- For now, the complexity is the number of lines
--
-- @param name    A string representing the function's name
-- @param luaUnit THe unit output by metalua
--
-- @return An ast.Function object
local function createFunctionUnit(name, luaUnit)
   return ast.Function:new(
      name,
      math.max(1, luaUnit.lineinfo.last.line - luaUnit.lineinfo.first.line - 1)
   )
end

--------------------------------------------------------------------------------
--- Analyze a "Local" unit
--
-- @param luaUnit    The unit to analyze
-- @param symbols    The table of top-level symbols with their nature
-- @param codeSpaces The association between a code space name and its object
--
-- @return symbols, codeSpace
local function analyzeLocal(luaUnit, symbols, codeSpaces)
   local idents = luaUnit[1]

   for _, ident in pairs(idents) do
      if ident.tag == "Id" then
         symbols[ident[1]] = ast.Value:new(ident[1])
      end
   end

   return symbols, codeSpaces
end

--------------------------------------------------------------------------------
--- Analyze a "Set" unit
--
-- @param luaUnit    The unit to analyze
-- @param symbols    The table of top-level symbols with their nature
-- @param codeSpaces The association between a code space name and its object
--
-- @return symbols, codeSpace
local function analyzeSet(luaUnit, symbols, codeSpaces)
   local lhs = luaUnit[1]
   local rhs = luaUnit[2]

   for index, ident in pairs(lhs) do
      if ident.tag == "Id" then
         symbols[ident[1]] = "value"
      elseif ident.tag == "Index" then
         local name = ident[1][1]
         local prop = ident[2][1]

         symbols[name] = nil

         if not codeSpaces[name] then
            codeSpaces[name] = ast.Codespace:new(name)
         end

         local value = rhs[index]

         if value.tag == "Function" then
            codeSpaces[name]:addComponent(createFunctionUnit(prop, value))
         else
            codeSpaces[name]:addComponent(ast.Value:new(prop))
         end
      end
   end

   return symbols, codeSpaces
end

--------------------------------------------------------------------------------
--- Analyze a "Localrec" unit
--
-- @param luaUnit    The unit to analyze
-- @param symbols    The table of top-level symbols with their nature
-- @param codeSpaces The association between a code space name and its object
--
-- @return symbols, codeSpace
local function analyzeLocalRec(luaUnit, symbols, codeSpaces)
   symbols[luaUnit[1][1][1]] = createFunctionUnit(luaUnit[1][1][1], luaUnit[2])
   return symbols, codeSpaces
end


--------------------------------------------------------------------------------
--- Analyze a unit and update symbols and codeSpaces accordingly
--
-- @param luaUnit    The unit to analyze
-- @param symbols    The table of top-level symbols with their nature
-- @param codeSpaces The association between a code space name and its object
--
-- @return symbols, codeSpace
local function analyzeUnit(luaUnit, symbols, codeSpaces)
   if luaUnit.tag == "Local" then
      return analyzeLocal(luaUnit, symbols, codeSpaces)
   elseif luaUnit.tag == "Set" then
      return analyzeSet(luaUnit, symbols, codeSpaces)
   elseif luaUnit.tag == "Localrec" then
      return analyzeLocalRec(luaUnit, symbols, codeSpaces)
   else
      return symbols, codeSpaces
   end
end

--------------------------------------------------------------------------------
--- Return AST for a source file
--
-- @param file A string representing the path to a source file
local function parseSource(file)
   local luaAst = compiler:srcfile_to_ast(file)
   local symbols = {}
   local codeSpaces = {}

   for _, luaUnit in pairs(luaAst) do
      symbols, codeSpaces = analyzeUnit(luaUnit, symbols, codeSpaces)
   end

   local units = {}
   for _, unit in pairs(symbols) do
         table.insert(units, unit)
   end

   for _, codeSpace in pairs(codeSpaces) do
      table.insert(units, codeSpace)
   end

   return units
end

--------------------------------------------------------------------------------
--- Return AST for a directory
--
-- @param dir A string representing the path to a directory
local function parseDir(dir)
   local units = {}

   for file in lfs.dir(dir) do
      if file ~= "." and file ~= ".." then
         local filepath = dir .. "/" .. file
         local attrs = lfs.attributes(filepath)

         if attrs.mode == "directory" then
            concatAst(units, parseDir(filepath))
         elseif attrs.mode == "file" then
            local _, matchEnd = string.find(file, ".lua")
            if matchEnd == #file then
               local root = ast.Codespace:new(file)
               root.components = parseSource(filepath)
               table.insert(units, root)
            end
         end
      end
   end

   return units
end

return {
   parseDir = parseDir,
   parseSource = parseSource,
   complexityFactor = 5
}
