
import { luaconf, lua, lualib, lauxlib } from "../lib/fengari"

function poll_event(L) {

}

function wait_event(L) {

}

function set_cursor(L) {

}

function set_window_title(L) {

}

function set_window_mode(L) {

}

function window_has_focus(L) {

}

function absolute_path(L) {

}

function get_clipboard(L) {

}

function set_clipboard(L) {

}

function get_time(L) {

}

function sleep(L) {

}

const lib = {
  poll_event,
  wait_event,
  set_cursor,
  set_window_title,
  set_window_mode,
  window_has_focus,
  absolute_path,
  get_clipboard,
  set_clipboard,
  get_time,
  sleep
}

export default (L) => {
  lauxlib.luaL_newlib(L, lib);
  return 1;
}