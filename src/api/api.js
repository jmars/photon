import { luaconf, lua, lualib, lauxlib, to_luastring } from "../lib/fengari"
import luaopen_system from "./system"
import luaopen_renderer from "./renderer"

const libs = [
  { name: "system", func: luaopen_system }
]

export function Lapi_openlibs(L) {
  for (let i = 0; i < libs.length; i++) {
    lauxlib.luaL_requiref(L, to_luastring(libs[i].name), libs[i].func, 1);
    lua.lua_pop(L, 1);
  }
}