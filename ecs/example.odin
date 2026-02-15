package ecs_engine

import rb "vendor:raylib"
import "core:mem"

Pos2D      :: distinct [2]i32
Velocity2D :: distinct [2]i32
name       :: distinct string
moves      :: distinct bool

Circle     :: struct { radius: f32 }
Rectangle  :: struct { height: i32, width: i32 }
Drawn      :: distinct bool

BoundBox   :: distinct Rectangle 

WIDTH      :: 800
HEIGHT     :: 600

main :: proc() {
  pool: [4]Entity
  
  // if you don't use an arena you have to manually free the 
  // result of querries
  backing_buffer := make([]u8, 1 * mem.Megabyte)
  defer delete(backing_buffer)
  arena: mem.Arena
  mem.arena_init(&arena, backing_buffer)
  querries_alloc := mem.arena_allocator(&arena)

  y := 0
  i := &pool[y]
  add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  add_component(i, Velocity2D)^   = {(auto_cast y - 2)*2 + 1, (auto_cast y - 2)*2 - 1}
  add_component(i, moves)
  add_component(i, rb.Color)^     = rb.GRAY
  add_component(i, Circle).radius = 10
  add_component(i, BoundBox)^     = { height = 11, width = 11 }
  
  y = 1
  i = &pool[y]
  add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  add_component(i, Velocity2D)^   = {(auto_cast y - 2)*2 + 1, (auto_cast y - 2)*2 - 1}
  add_component(i, moves)
  add_component(i, Drawn)
  add_component(i, rb.Color)^     = rb.WHITE
  add_component(i, Circle).radius = 10
  add_component(i, BoundBox)^     = { height = 11, width = 11 }
  
  y = 2
  i = &pool[y]
  add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  add_component(i, rb.Color)^     = rb.BLUE
  add_component(i, Rectangle)^    = { height = 10, width = 20 }
  add_component(i, Drawn)


  y = 3
  i = &pool[y]
  add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  add_component(i, Velocity2D)^   = {(auto_cast y - 2)*2 + 1, (auto_cast y - 2)*2 - 1}
  add_component(i, moves)
  add_component(i, rb.Color)^     = rb.RED
  add_component(i, Drawn)
  add_component(i, Rectangle)^    = { height = 10, width = 20 }
  add_component(i, BoundBox)^     = { height = 11, width = 21 }

  rb.InitWindow(WIDTH, HEIGHT, "ECS test")
  rb.SetTargetFPS(60)

  for !rb.WindowShouldClose() {

    for e in querry(pool[:], with(moves), with(Pos2D), with(Velocity2D), with(BoundBox), allocator = querries_alloc) {
      vel       := unwrap(get_component(e, Velocity2D))
      pos       := unwrap(get_component(e, Pos2D))
      bound     := unwrap(get_component(e, BoundBox))

      rbpos := pos^ + {bound.height/2, bound.width/2}
      lbpos := pos^ - {bound.height/2, bound.width/2}

      if rbpos.x > WIDTH || lbpos.x < 0 {
        vel.x *= -1
      }
      if rbpos.y > HEIGHT || lbpos.y < 0 {
        vel.y *= -1
      }

      pos^ += auto_cast vel^
    }

    rb.BeginDrawing()
    rb.ClearBackground(rb.BLACK)


    if d := querry(pool[:], with(Drawn), allocator = querries_alloc); len(d) > 0 {
      for c in querry(d, with(Circle), with(rb.Color), allocator = querries_alloc) {
        pos         := unwrap(get_component(c, Pos2D))
        circle      := unwrap(get_component(c, Circle))
        color       := unwrap(get_component(c, rb.Color))
        rb.DrawCircle(pos.x, pos.y, circle.radius, color^)
      }
      for r in querry(d, with(Rectangle), with(rb.Color), allocator = querries_alloc) {
        pos         := unwrap(get_component(r, Pos2D))
        rect        := unwrap(get_component(r, Rectangle))
        color       := unwrap(get_component(r, rb.Color))
        rb.DrawRectangle(pos.x - (rect.width/2), pos.y - (rect.height/2), rect.width, rect.height, color^)
      }
    }

    rb.EndDrawing()
    mem.arena_free_all(&arena)
  }

  rb.CloseWindow()

  for &e in pool {
    free_entity(&e)
  }

}
