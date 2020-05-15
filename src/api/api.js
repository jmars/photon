import { luaconf, lua, lualib, lauxlib } from "../lib/fengari"
import luaopen_system from "./system"
import luaopen_renderer from "./renderer"

const libs = [
  { name: "system", func: luaopen_system }
]

export default (L) => {
  for (let i = 0; i < libs.length; i++) {
    lauxlib.luaL_requiref(L, libs[i].name, libs[i].func, 1)
  }
}