package lexer

import "core:fmt"

main :: proc() {
  l: lexer
  l = init_lexer("test.txt")

  for l.token.type != .either_end_or_failure {
    get_token(&l)
    fmt.printfln("%s:%d:%d => {}", l.token.file, l.token.row, l.token.col, l.token)
  }
}