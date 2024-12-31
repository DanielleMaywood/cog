import glexer/token

@internal
pub fn print(tokens: List(token.Token)) -> String {
  do_print(tokens, "")
}

fn do_print(tokens: List(token.Token), source: String) -> String {
  case tokens {
    [] -> source
    [token, ..tokens] -> do_print(tokens, source <> print_token(token))
  }
}

@internal
pub fn print_token(token: token.Token) -> String {
  case token {
    token.AmperAmper -> "&&"
    token.As -> "as"
    token.Assert -> "assert"
    token.At -> "@"
    token.Auto -> "auto"
    token.Bang -> "!"
    token.Case -> "case"
    token.Colon -> ":"
    token.Comma -> ","
    token.CommentDoc(comment) -> "///" <> comment
    token.CommentModule(comment) -> "////" <> comment
    token.CommentNormal(comment) -> "//" <> comment
    token.Const -> "const"
    token.Delegate -> "delegate"
    token.Derive -> "derive"
    token.DiscardName(name) -> "_" <> name
    token.Dot -> "."
    token.DotDot -> ".."
    token.Echo -> "echo"
    token.Else -> "else"
    token.EndOfFile -> ""
    token.Equal -> "="
    token.EqualEqual -> "=="
    token.Float(value) -> value
    token.Fn -> "fn"
    token.Greater -> ">"
    token.GreaterDot -> ">."
    token.GreaterEqual -> ">="
    token.GreaterEqualDot -> ">=."
    token.GreaterGreater -> ">>"
    token.Hash -> "#"
    token.If -> "if"
    token.Implement -> "implement"
    token.Import -> "import"
    token.Int(value) -> value
    token.LeftArrow -> "<-"
    token.LeftBrace -> "{"
    token.LeftParen -> "("
    token.LeftSquare -> "["
    token.Less -> "<"
    token.LessDot -> "<."
    token.LessEqual -> "<="
    token.LessEqualDot -> "<=."
    token.LessGreater -> "<>"
    token.LessLess -> "<<"
    token.Let -> "let"
    token.Macro -> "macro"
    token.Minus -> "-"
    token.MinusDot -> "-."
    token.Name(name) -> name
    token.NotEqual -> "!="
    token.Opaque -> "opaque"
    token.Panic -> "panic"
    token.Percent -> "%"
    token.Pipe -> "|>"
    token.Plus -> "+"
    token.PlusDot -> "+."
    token.Pub -> "pub"
    token.RightArrow -> "->"
    token.RightBrace -> "}"
    token.RightParen -> ")"
    token.RightSquare -> "]"
    token.Slash -> "/"
    token.SlashDot -> "/."
    token.Space(space) -> space
    token.Star -> "*"
    token.StarDot -> "*."
    token.String(value) -> "\"" <> value <> "\""
    token.Test -> "test"
    token.Todo -> "todo"
    token.Type -> "type"
    token.UnexpectedGrapheme(value) -> value
    token.UnterminatedString(value) -> "\"" <> value
    token.UpperName(name) -> name
    token.Use -> "use"
    token.VBar -> "|"
    token.VBarVBar -> "||"
  }
}
