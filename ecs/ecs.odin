package ecs_engine

// v0.3
// v0.3 changelog:
// - Entity now uses map[typeid]Component instead of a dynamic array
// - added default message for unwrap functions
// - added unwrap_ptr function

import "core:fmt"
import "core:os"

Entity :: struct {
  comps : map[typeid]Component
}

Component :: struct {
  type: typeid,
  data: []byte
}

with_struct    :: struct { type: typeid }
without_struct :: struct { type: typeid }

// add_component           :: proc(e: ^Entity, $T: typeid, allocator := context.allocator)                             -> ^T
// get_component           :: proc(e: ^Entity, $T: typeid)                                                             -> Maybe(^T)
// has_component           :: proc(e: ^Entity, T: typeid)                                                              -> bool
// with                    :: proc(T: typeid)                                                                          -> with_struct
// without                 :: proc(T: typeid)                                                                          -> without_struct
// querry                  :: proc{querry_entity_array, querry_entity_array_ptr}                                       -> []^Entity
// querry_entity_array     :: proc(pool: union {[]Entity, []^Entity}, args: ..w_union, allocator := context.allocator) -> []^Entity
// querry_entity_array_ptr :: proc(pool: union {[]Entity, []^Entity}, res: ^[dynamic]^Entity, args: ..w_union)         -> []^Entity
// unwrap                  :: proc{unwrap_maybe, unwrap_ptr}                                                           -> T
// unwrap_maybe            :: proc(m: Maybe($T), msg := "default message", ctx := #caller_location)                    -> T
// unwrap_ptr              :: proc(m: ^($T), msg := "default message", ctx := #caller_location)                        -> T
// clear_entity            :: proc(e: ^Entity)
// free_entity             :: proc(e: ^Entity)

with    :: proc(T: typeid)    -> with_struct    { return { type = T } }
without :: proc(T: typeid)    -> without_struct { return { type = T } }

add_component :: proc(e: ^Entity, $T: typeid, allocator := context.allocator) -> ^T {
  if e.comps[T].type != nil {
    fmt.eprintfln("INFO: Entity already has the component '{}' skipping", typeid_of(T))
    return nil
  }

  e.comps[T] = {
    type = T,
    data = make([]byte, size_of(T), allocator)
  }

  return cast(^T)(&e.comps[T].data[0])
}

get_component :: proc(e: ^Entity, $T: typeid) -> Maybe(^T) {
  if e.comps[T].type != nil {
    return cast(^T)&e.comps[T].data[0]
  }
  return nil
}

has_component :: proc(e: ^Entity, T: typeid) -> bool {
  return e.comps[T].type != nil
}

querry :: proc{querry_entity_array_alloc, querry_entity_array_ptr}

querry_entity_array_alloc :: proc(pool: union {[]Entity, []^Entity}, args: ..union {with_struct, without_struct}, allocator := context.allocator) -> []^Entity {
  res: [dynamic]^Entity
  res.allocator = allocator

  return querry_entity_array_ptr(pool, &res, ..args)
}

querry_entity_array_ptr :: proc(pool: union {[]Entity, []^Entity}, res: ^[dynamic]^Entity, args: ..union {with_struct, without_struct}) -> []^Entity {

  start := len(res)

  switch v in pool {
  case []Entity:
    for &e in v { append(res, &e) }
  case []^Entity:
    for &e in v { append(res, e) }
  }

  i := 0
  for a in args {
    i = 0
    switch v in a {
    case with_struct:
      for i < len(res) {
        if !has_component(res[i], v.type) {
          unordered_remove(res, i)
        } else {
          i += 1
        }
      }
    case without_struct:
      for i < len(res) {
        if has_component(res[i], v.type) {
          unordered_remove(res, i)
        } else {
          i += 1
        }
      }
    }
  }

  return res[start:]
}

clear_entity :: proc(e: ^Entity) {
  for k, v in e.comps {
    delete(v.data)
  }
  clear_map(&e.comps)
}

free_entity :: proc(e: ^Entity) {
  for k, v in e.comps {
    delete(v.data)
    delete_key(&e.comps, k)
  }
  free(&e.comps)
}

unwrap :: proc{unwrap_maybe, unwrap_ptr}

unwrap_maybe :: proc(m: Maybe($T), msg := "default message", ctx := #caller_location) -> T {
  val, ok := m.?
  if ok do return val
  fmt.eprintfln("%s tried to unwrap but failed with message '%s'", ctx, msg)
  os.exit(1)
}
unwrap_ptr :: proc(m: ^($T), msg := "default message", ctx := #caller_location) -> T {
  if m != nil do return m^
  fmt.eprintfln("%s tried to unwrap but failed with message '%s'", ctx, msg)
  os.exit(1)
}

