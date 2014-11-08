-- lua.lua
--
-- Defines an ast generator from a lua code base.

--------------------------------------------------------------------------------
require('luarocks.loader') -- TODO remove
local lfs = require('lfs')
local inspect = require('inspect') -- TODO remove

local ast = require('./ast')
local compiler = require('metalua.compiler'):new()

--------------------------------------------------------------------------------
--- In-place appending of source to dest
local function concatAst(dest, source)
   for _, unit in pairs(source) do
      table.insert(dest, unit)
   end
end

--------------------------------------------------------------------------------
--- Analyze a "Local" unit
--
-- @param luaUnit    The unit to analyze
-- @param symbols    The table of top-level symbols with their nature
-- @param codeSpaces The association between a code space name and its components
--
-- @return symbols, codeSpace
local function analyzeLocal(luaUnit, symbols, codeSpaces)
   local idents = luaUnit[1]

   for _, ident in pairs(idents) do
      if ident.tag == "Id" then
         symbols[ident[1]] = "value"
      end
   end

   return symbols, codeSpaces
end

--------------------------------------------------------------------------------
--- Analyze a unit and update symbols and codeSpaces accordingly
--
-- @param luaUnit    The unit to analyze
-- @param symbols    The table of top-level symbols with their nature
-- @param codeSpaces The association between a code space name and its components
--
-- @return symbols, codeSpace
local function analyzeUnit(luaUnit, symbols, codeSpaces)
   if luaUnit.tag == "Local" then
      return analyzeLocal(luaUnit, symbols, codeSpaces)
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
   for symbol, tag in pairs(symbols) do
      if tag == "value" then
         table.insert(units, ast.Value:new(symbol))
      end
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

print(inspect(parseDir('.'))) -- TODO remove

return {
   parseDir = parseDir,
   parseSource = parseSource
}
