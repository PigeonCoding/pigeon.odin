package flag

import "core:fmt"
import "core:os"

main :: proc() {

  f_container: flag_container
  f_container.skip_triple_dash = true
  f_container.skip_pogram_name = true

  add_flag(&f_container, "name", "", "give your name")       // string
  add_flag(&f_container, "age", 0, "give your age")          // int
  add_flag(&f_container, "single", false, "are you single?") // bool

  if len(os.args) == 1 {
    fmt.println("usage", os.args[0])
    print_usage(&f_container)
    os.exit(1)
  }

  check_flags(&f_container)

  fmt.println("-----------------")
  
  name: ^string = auto_cast get_flag_value(&f_container, "name")
  age: ^int = auto_cast get_flag_value(&f_container, "age")
  single: ^bool = auto_cast get_flag_value(&f_container, "single")
  
  if name   != nil do fmt.println("your name is", name^)
  if age    != nil do fmt.println("your age is", age^)
  if single != nil do fmt.println("you are single")

  fmt.println("-----------------")
  fmt.println("remaining args:", f_container.remaining)
  fmt.println("-----------------")

  free_flag_container(&f_container)
}