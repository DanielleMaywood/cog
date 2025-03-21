import cog/glexer_printer
import filepath
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glexer
import glexer/token
import simplifile

pub type CogError {
  InvalidPathError(String)
  UnexpectedToken(token.Token)
  FileError(simplifile.FileError)
}

pub fn main() {
  let result = {
    // Get project root
    use root <- result.try(find_project_root())

    // Get all source files
    use source_files <- result.try(collect_project_files(in: root, at: "src"))
    use test_files <- result.try(collect_project_files(in: root, at: "test"))

    let files = list.append(source_files, test_files)

    // Filter them down to gleam source files
    let gleam_files = list.filter(files, string.ends_with(_, ".gleam"))

    // Attempt to run cog for each gleam source file
    use _ <- result.try({
      gleam_files
      |> list.map(fn(file) {
        use content <- result.try({
          simplifile.read(file)
          |> result.map_error(FileError)
        })

        use source <- result.try(run(on: content, in: root))

        // Only write to the file if there are changes
        case source != content {
          True ->
            simplifile.write(to: file, contents: source)
            |> result.map_error(FileError)

          False -> Ok(Nil)
        }
      })
      |> result.all
    })

    Ok(Nil)
  }

  case result {
    Ok(Nil) -> Nil
    Error(UnexpectedToken(token)) -> {
      io.println_error("unexpected token: " <> string.inspect(token))
    }
    Error(InvalidPathError(path)) -> {
      io.println_error("invalid path found: " <> path)
    }
    Error(FileError(error)) -> {
      io.println_error("file error: " <> string.inspect(error))
    }
  }
}

pub fn run(on content: String, in dir: String) -> Result(String, CogError) {
  let tokens = glexer.new(content) |> glexer.lex
  let tokens = list.map(tokens, fn(token) { token.0 })

  // Perform code generation
  use tokens <- result.try(perform_actions(tokens, in: dir))

  Ok(glexer_printer.print(tokens))
}

fn collect_project_files(
  in root: String,
  at path: String,
) -> Result(List(String), CogError) {
  let path = filepath.join(root, path)

  use is_directory <- result.try({
    simplifile.is_directory(path)
    |> result.map_error(FileError)
  })

  use <- bool.guard(when: !is_directory, return: Ok([]))

  simplifile.get_files(in: path)
  |> result.map_error(FileError)
}

fn find_project_root() -> Result(String, CogError) {
  use cwd <- result.try({
    simplifile.current_directory()
    |> result.map_error(FileError)
  })

  do_find_project_root(cwd)
}

fn do_find_project_root(dir: String) -> Result(String, CogError) {
  use is_file <- result.try({
    filepath.join(dir, "gleam.toml")
    |> simplifile.is_file
    |> result.map_error(FileError)
  })

  case is_file {
    True -> Ok(dir)
    False -> do_find_project_root(filepath.directory_name(dir))
  }
}

fn perform_actions(
  tokens: List(token.Token),
  in dir: String,
) -> Result(List(token.Token), CogError) {
  do_perform_actions(tokens, in: dir, generated: [])
  |> result.map(list.reverse)
}

fn do_perform_actions(
  tokens: List(token.Token),
  in dir: String,
  generated acc: List(token.Token),
) -> Result(List(token.Token), CogError) {
  case tokens {
    [] -> Ok(acc)
    [token.CommentNormal("cog:embed " <> path) as t1, ..tokens] -> {
      let #(comments, tokens) =
        list.split_while(tokens, fn(token) {
          case token {
            token.Space(_)
            | token.CommentDoc(_)
            | token.CommentNormal(_)
            | token.CommentModule(_) -> True
            _ -> False
          }
        })

      case tokens {
        [
          token.Const as t2,
          token.Space(_) as t3,
          token.Name(_) as t4,
          token.Space(_) as t5,
          token.Equal as t6,
          token.Space(_) as t7,
          token.String(_),
          ..tokens
        ] -> {
          use generated <- result.try({
            cog_embed(
              list.flatten([[t1], comments, [t2, t3, t4, t5, t6, t7]]),
              path,
              in: dir,
            )
          })

          do_perform_actions(
            tokens,
            in: dir,
            generated: list.append(generated, acc),
          )
        }
        [
          token.Pub as t2,
          token.Space(_) as t3,
          token.Const as t4,
          token.Space(_) as t5,
          token.Name(_) as t6,
          token.Space(_) as t7,
          token.Equal as t8,
          token.Space(_) as t9,
          token.String(_),
          ..tokens
        ] -> {
          use generated <- result.try({
            cog_embed(
              list.flatten([[t1], comments, [t2, t3, t4, t5, t6, t7, t8, t9]]),
              path,
              in: dir,
            )
          })

          do_perform_actions(
            tokens,
            in: dir,
            generated: list.append(generated, acc),
          )
        }
        [] -> Error(UnexpectedToken(token.EndOfFile))
        [token, ..] -> Error(UnexpectedToken(token))
      }
    }
    [token, ..tokens] ->
      do_perform_actions(tokens, in: dir, generated: [token, ..acc])
  }
}

fn cog_embed(
  tokens: List(token.Token),
  path: String,
  in dir: String,
) -> Result(List(token.Token), CogError) {
  use path <- result.try({
    filepath.expand(path)
    |> result.map_error(fn(_) { InvalidPathError(path) })
  })

  use data <- result.try({
    simplifile.read(filepath.join(dir, path))
    |> result.map_error(FileError)
  })

  let codepoints =
    data
    |> string.to_utf_codepoints
    |> list.map(fn(codepoint) {
      "\\u{" <> int.to_base16(string.utf_codepoint_to_int(codepoint)) <> "}"
    })
    |> string.join(with: "")

  Ok([token.String(codepoints), ..list.reverse(tokens)])
}
