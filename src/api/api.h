#ifndef API_H
#define API_H

#include "lib/luajit/src/lua.h"
#include "lib/luajit/src/lauxlib.h"
#include "lib/luajit/src/lualib.h"
#include "lib/amoeba/amoeba.h"
#include "compat-5.3.h"

#define API_TYPE_FONT "Font"

void api_load_libs(lua_State *L);

#endif
