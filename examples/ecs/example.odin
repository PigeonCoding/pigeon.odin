package ecs_engine_example

import rb "vendor:raylib"
import "core:mem"
import ecs "../../ecs"

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

  pool: [4]ecs.Entity
  
  // if you don't use an arena you have to manually free the 
  // result of querries or reuse a [dynamic]^Entity
  backing_buffer := make([]u8, 1 * mem.Megabyte)
  defer delete(backing_buffer)
  arena: mem.Arena
  mem.arena_init(&arena, backing_buffer)
  querries_alloc := mem.arena_allocator(&arena)
  
  y := 0
  i := &pool[y]
  ecs.add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  ecs.add_component(i, Velocity2D)^   = {(auto_cast y - 2)*2 + 1, (auto_cast y - 2)*2 - 1}
  ecs.add_component(i, moves)
  ecs.add_component(i, rb.Color)^     = rb.GRAY
  ecs.add_component(i, Circle).radius = 10
  ecs.add_component(i, BoundBox)^     = { height = 11, width = 11 }
  
  y = 1
  i = &pool[y]
  ecs.add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  ecs.add_component(i, Velocity2D)^   = {(auto_cast y - 2)*2 + 1, (auto_cast y - 2)*2 - 1}
  ecs.add_component(i, moves)
  ecs.add_component(i, Drawn)
  ecs.add_component(i, rb.Color)^     = rb.WHITE
  ecs.add_component(i, Circle).radius = 10
  ecs.add_component(i, BoundBox)^     = { height = 11, width = 11 }
  
  y = 2
  i = &pool[y]
  ecs.add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  ecs.add_component(i, rb.Color)^     = rb.BLUE
  ecs.add_component(i, Rectangle)^    = { height = 10, width = 20 }
  ecs.add_component(i, Drawn)


  y = 3
  i = &pool[y]
  ecs.add_component(i, Pos2D)^        = {WIDTH / 2, HEIGHT / 2}
  ecs.add_component(i, Velocity2D)^   = {(auto_cast y - 2)*2 + 1, (auto_cast y - 2)*2 - 1}
  ecs.add_component(i, moves)
  ecs.add_component(i, rb.Color)^     = rb.RED
  ecs.add_component(i, Drawn)
  ecs.add_component(i, Rectangle)^    = { height = 10, width = 20 }
  ecs.add_component(i, BoundBox)^     = { height = 11, width = 21 }

  rb.InitWindow(WIDTH, HEIGHT, "ECS test")
  rb.SetTargetFPS(60)

  for !rb.WindowShouldClose() {

    for e in ecs.querry(pool[:], ecs.with(moves), ecs.with(Pos2D), ecs.with(Velocity2D), ecs.with(BoundBox), allocator = querries_alloc) {
      vel       := ecs.unwrap(ecs.get_component(e, Velocity2D))
      pos       := ecs.unwrap(ecs.get_component(e, Pos2D))
      bound     := ecs.unwrap(ecs.get_component(e, BoundBox))

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


    if d := ecs.querry(pool[:], ecs.with(Drawn), allocator = querries_alloc); len(d) > 0 {
      for c in ecs.querry(d, ecs.with(Circle), ecs.with(rb.Color), allocator = querries_alloc) {
        pos         := ecs.unwrap(ecs.get_component(c, Pos2D))
        circle      := ecs.unwrap(ecs.get_component(c, Circle))
        color       := ecs.unwrap(ecs.get_component(c, rb.Color))
        rb.DrawCircle(pos.x, pos.y, circle.radius, color^)
      }
      for r in ecs.querry(d, ecs.with(Rectangle), ecs.with(rb.Color), allocator = querries_alloc) {
        pos         := ecs.unwrap(ecs.get_component(r, Pos2D))
        rect        := ecs.unwrap(ecs.get_component(r, Rectangle))
        color       := ecs.unwrap(ecs.get_component(r, rb.Color))
        rb.DrawRectangle(pos.x - (rect.width/2), pos.y - (rect.height/2), rect.width, rect.height, color^)
      }
    }

    rb.EndDrawing()
    mem.arena_free_all(&arena)
  }

  rb.CloseWindow()

  for &e in pool {
    ecs.free_entity(&e)
  }

}
