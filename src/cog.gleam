import cog/glexer_printer
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glexer
import glexer/token
import simplifile

pub fn main() {
  // Get all source files
  use source_files <- result.try(simplifile.get_files(in: "./src"))
  use test_files <- result.try(simplifile.get_files(in: "./test"))

  let files = list.append(source_files, test_files)

  // Filter them down to gleam source files
  let gleam_files = list.filter(files, string.ends_with(_, ".gleam"))

  // Attempt to run cog for each gleam source file
  use _ <- result.try({
    gleam_files
    |> list.map(fn(file) {
      use content <- result.try(simplifile.read(file))
      use source <- result.try(run(on: content))

      simplifile.write(to: file, contents: source)
    })
    |> result.all
  })

  Ok(Nil)
}

pub fn run(on content: String) -> Result(String, simplifile.FileError) {
  let tokens = glexer.new(content) |> glexer.lex
  let tokens = list.map(tokens, fn(token) { token.0 })

  // Perform code generation
  use tokens <- result.try(perform_actions(tokens))

  Ok(glexer_printer.print(tokens))
}

fn perform_actions(
  tokens: List(token.Token),
) -> Result(List(token.Token), simplifile.FileError) {
  do_perform_actions(tokens, [])
  |> result.map(list.reverse)
}

fn do_perform_actions(
  tokens: List(token.Token),
  generated: List(token.Token),
) -> Result(List(token.Token), simplifile.FileError) {
  case tokens {
    [] -> Ok(generated)
    [
      token.CommentNormal("cog:embed " <> path) as t1,
      token.Space(_) as t2,
      token.Const as t3,
      token.Space(_) as t4,
      token.Name(_) as t5,
      token.Space(_) as t6,
      token.Equal as t7,
      token.Space(_) as t8,
      token.String(_),
      ..tokens
    ] -> {
      use data <- result.try(simplifile.read(path))

      let codepoints =
        data
        |> string.to_utf_codepoints
        |> list.map(fn(codepoint) {
          "\\u{" <> int.to_base16(string.utf_codepoint_to_int(codepoint)) <> "}"
        })
        |> string.join(with: "")

      let new =
        [t1, t2, t3, t4, t5, t6, t7, t8, token.String(codepoints)]
        |> list.reverse

      do_perform_actions(tokens, list.append(new, generated))
    }
    [token, ..tokens] -> do_perform_actions(tokens, [token, ..generated])
  }
}
