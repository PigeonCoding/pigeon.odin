package coroutine

import "core:fmt"

main :: proc() {
  
  pool: cpool

  st_counter :: struct {
    i: int,
    max: int
  }
  
  c: coroutine(st_counter)
  c.state.i = 0
  c.state.max = 10
  c.func = proc(s: st_counter) -> Maybe(st_counter) {
    if s.i >= s.max do return nil

    fmt.println("-", s.i)
    ss := s
    ss.i += 1
    return ss
  }

  c2: coroutine(st_counter)
  c2.state.i = 9
  c2.state.max = 0
  c2.func = proc(s: st_counter) -> Maybe(st_counter) {
    if s.i < 0 do return nil

    fmt.println("--", s.i)
    ss := s
    ss.i -= 1
    return ss
  }
  append(&pool.coroutines, coroutine_to_any(c))
  append(&pool.coroutines, coroutine_to_any(c2))

  for step_pool(&pool) {}

}