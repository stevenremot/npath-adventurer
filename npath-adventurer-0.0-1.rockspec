package = "npath-adventurer"
version = "0.0-1"
source = {
   url = "https://github.com/stevenremot/npath-adventurer"
}
description = {
   summary = "An adventure game set in a world generated from a codebase.",
   detailed = "An adventure game set in a world generated from a codebase",
   homepage = "https://github.com/stevenremot/npath-adventurer",
   license = "GPL v3"
}
dependencies = {
   "lua ~> 5.2",
   "metalua-parser ~> 0.7",
   "luafilesystem ~> 1.6"
}
build = {
   type = "builtin",
   modules = {}
}
