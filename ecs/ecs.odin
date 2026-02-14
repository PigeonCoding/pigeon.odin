package ecs_engine

// v0.1

import "core:fmt"
import "core:os"

Entity :: struct {
  components: [dynamic]Component
}

Component :: struct {
  type: typeid,
  data: []byte
}

with_struct    :: struct { type: typeid }
without_struct :: struct { type: typeid }
w_union        :: union {with_struct, without_struct}

with :: proc(T: typeid)    -> with_struct    { return { type = T } }
without :: proc(T: typeid) -> without_struct { return { type = T } }

add_component :: proc(e: ^Entity, $T: typeid) -> ^T {
  for i in e.components {
    if i.type == T {
      fmt.eprintfln("INFO: Entity already has the component '{}' skipping", typeid_of(T))
      return nil
    }
  }
  c: Component
  c.type = T
  c.data = make([]byte, size_of(T))
  append(&e.components, c)
  return cast(^T)(&e.components[len(e.components) - 1].data[0])
}

get_component :: proc(e: ^Entity, $T: typeid) -> Maybe(^T) {
  for i in e.components {
    if i.type == T {
      return cast(^T)&i.data[0]
    }
  }

  return nil
}

clear_components :: proc(e: ^Entity) {
  for &c in e.components {
    free(&c.data[0])
  }
  clear(&e.components)
}

has_componenent :: proc(e: ^Entity, T: typeid) -> bool {
  for c in e.components {
    if c.type == T {
      return true
    }
  }
  return false
}

querry :: proc{querry_entity_array}

querry_entity_array :: proc(pool: union {[]Entity, []^Entity}, args: ..w_union, allocator := context.allocator) -> []^Entity{
  res: [dynamic]^Entity
  res.allocator = allocator

  switch v in pool {
  case []Entity:
    for &e in v { append(&res, &e) }
  case []^Entity:
    for &e in v { append(&res, e) }
  }

  i := 0
  for a in args {
    i = 0
    switch v in a {
    case with_struct:
      for i < len(res) {
        if !has_componenent(res[i], v.type) {
          unordered_remove(&res, i)
        } else {
          i += 1
        }
      }
    case without_struct:
      for i < len(res) {
        if has_componenent(res[i], v.type) {
          unordered_remove(&res, i)
        } else {
          i += 1
        }
      }
    }
  }

  return res[:]
}

unwrap_maybe :: proc(m: Maybe($T), file := #file, line := #line) -> T {
  val, ok := m.?
  if ok do return val
  fmt.eprintfln("%s:%d tried to unwrap but failed", file, line)
  os.exit(1)
}

unwrap :: proc{unwrap_maybe}
