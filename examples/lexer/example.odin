package lexer_example

import "core:fmt"
import lx "../../lexer"

main :: proc() {
  l: lx.lexer = lx.init_lexer("./examples/lexer/test.txt")

  for lx.get_token(&l) {
    fmt.printfln("%s:%d:%d => {}", l.token.file, l.token.row, l.token.col, l.token)
  }
}