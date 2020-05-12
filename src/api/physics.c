#include "api.h"
#include "lib/physics/spring.h"

static int L_spring(lua_State *L) {
  double c = luaL_checknumber(L, 1);
  double m = luaL_checknumber(L, 2);
  double k = luaL_checknumber(L, 3);

  double initial = luaL_checknumber(L, 4);
  double velocity = luaL_checknumber(L, 5);

  double t = luaL_checknumber(L, 5);

  double x;
  double dx;

  phys_SpringSolve(c, m, k, initial, velocity, t, &x, &dx);

  lua_pushnumber(L, x);
  lua_pushnumber(L, dx);

  return 2;
}


static const luaL_Reg lib[] = {
  { "spring", L_spring },
  { NULL,     NULL }
};


int luaopen_physics(lua_State *L) {
  luaL_newlib(L, lib);
  return 1;
}