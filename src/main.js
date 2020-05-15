import { luaconf, lua, lualib, lauxlib, to_luastring } from "./lib/fengari"
import { Lapi_openlibs } from "./api/api"

const L = lauxlib.luaL_newstate();
if (!L) throw Error("failed to create lua state");
lualib.luaL_openlibs(L);
Lapi_openlibs(L);

lua.lua_atnativeerror(L, (l) => {
  console.log('error', l)
})

lauxlib.luaL_dostring(L, to_luastring("print(system.sleep(1))"))