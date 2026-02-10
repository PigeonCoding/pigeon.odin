package coroutine

// v0.1

import "core:fmt"
import "core:os"
import "base:runtime"

coroutine :: struct($T: typeid) {
  func: proc(state: T) -> Maybe(T),
  state: T,
}

Any_Coroutine :: struct {
  data: rawptr,
  step: proc(data: rawptr) -> bool,
}

cpool :: struct {
  coroutines: [dynamic]Any_Coroutine,
  current: int
}

coroutine_to_any :: proc(c: coroutine($T)) -> Any_Coroutine {
  raw, ok := new(coroutine(T))
  if ok != runtime.Allocator_Error.None {
    fmt.eprintln("failed to allocate memory")
    os.exit(1)
  }
  raw^ = c
  return Any_Coroutine {
    data = raw,
    step = proc(data: rawptr) -> bool {
      c := (^coroutine(T))(data)
      if next_state, ok := c.func(c.state).?; ok {
        c.state = next_state
        return true
      }

      return false
    },
  }
}

step_pool :: proc(pool: ^cpool) -> bool {
  if len(pool.coroutines) == 0 {
    fmt.eprintln("ERROR: pool is empty")
    return false
  }
    
  idx := pool.current % len(pool.coroutines)
  curr := &pool.coroutines[idx]
    
  if curr.step(curr.data) {
    pool.current += 1
  } else {
    free(curr.data)
    unordered_remove(&pool.coroutines, idx)
  }
  return len(pool.coroutines) > 0
}

free_pool :: proc(pool: ^cpool) {
  for i in 0..<len(pool.coroutines) {
    free(pool.coroutines[i].data)
  }
  free(&pool.coroutines)
}

