package lexer

import "core:fmt"

main :: proc() {
  l: lexer = init_lexer("test.txt")

  for get_token(&l) {
    fmt.printfln("%s:%d:%d => {}", l.token.file, l.token.row, l.token.col, l.token)
  }
}