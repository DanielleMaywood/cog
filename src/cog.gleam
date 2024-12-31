import argv
import cog/glexer_printer
import filepath
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glexer
import glexer/token
import glint
import simplifile

pub type CogError {
  InvalidPathError(String)
  UnexpectedToken(token.Token)
  FileNotFound(String)
  FileError(simplifile.FileError)
}

//cog:embed /not-found.toml
pub const reason = "\u{6E}\u{61}\u{6D}\u{65}\u{20}\u{3D}\u{20}\u{22}\u{63}\u{6F}\u{67}\u{22}\u{A}\u{76}\u{65}\u{72}\u{73}\u{69}\u{6F}\u{6E}\u{20}\u{3D}\u{20}\u{22}\u{32}\u{2E}\u{30}\u{2E}\u{31}\u{22}\u{A}\u{64}\u{65}\u{73}\u{63}\u{72}\u{69}\u{70}\u{74}\u{69}\u{6F}\u{6E}\u{20}\u{3D}\u{20}\u{22}\u{41}\u{20}\u{70}\u{61}\u{63}\u{6B}\u{61}\u{67}\u{65}\u{20}\u{66}\u{6F}\u{72}\u{20}\u{70}\u{65}\u{72}\u{66}\u{6F}\u{72}\u{6D}\u{69}\u{6E}\u{67}\u{20}\u{63}\u{6F}\u{64}\u{65}\u{20}\u{67}\u{65}\u{6E}\u{65}\u{72}\u{61}\u{74}\u{69}\u{6F}\u{6E}\u{20}\u{61}\u{63}\u{74}\u{69}\u{6F}\u{6E}\u{73}\u{2E}\u{22}\u{A}\u{6C}\u{69}\u{63}\u{65}\u{6E}\u{63}\u{65}\u{73}\u{20}\u{3D}\u{20}\u{5B}\u{22}\u{4D}\u{49}\u{54}\u{22}\u{5D}\u{A}\u{72}\u{65}\u{70}\u{6F}\u{73}\u{69}\u{74}\u{6F}\u{72}\u{79}\u{20}\u{3D}\u{20}\u{7B}\u{20}\u{74}\u{79}\u{70}\u{65}\u{20}\u{3D}\u{20}\u{22}\u{67}\u{69}\u{74}\u{68}\u{75}\u{62}\u{22}\u{2C}\u{20}\u{75}\u{73}\u{65}\u{72}\u{20}\u{3D}\u{20}\u{22}\u{44}\u{61}\u{6E}\u{69}\u{65}\u{6C}\u{6C}\u{65}\u{4D}\u{61}\u{79}\u{77}\u{6F}\u{6F}\u{64}\u{22}\u{2C}\u{20}\u{72}\u{65}\u{70}\u{6F}\u{20}\u{3D}\u{20}\u{22}\u{63}\u{6F}\u{67}\u{22}\u{20}\u{7D}\u{A}\u{A}\u{A}\u{5B}\u{64}\u{65}\u{70}\u{65}\u{6E}\u{64}\u{65}\u{6E}\u{63}\u{69}\u{65}\u{73}\u{5D}\u{A}\u{67}\u{6C}\u{65}\u{61}\u{6D}\u{5F}\u{73}\u{74}\u{64}\u{6C}\u{69}\u{62}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{30}\u{2E}\u{33}\u{34}\u{2E}\u{30}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{32}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}\u{73}\u{69}\u{6D}\u{70}\u{6C}\u{69}\u{66}\u{69}\u{6C}\u{65}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{32}\u{2E}\u{32}\u{2E}\u{30}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{33}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}\u{67}\u{6C}\u{65}\u{78}\u{65}\u{72}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{32}\u{2E}\u{30}\u{2E}\u{30}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{33}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}\u{66}\u{69}\u{6C}\u{65}\u{70}\u{61}\u{74}\u{68}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{31}\u{2E}\u{31}\u{2E}\u{30}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{32}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}\u{61}\u{72}\u{67}\u{76}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{31}\u{2E}\u{30}\u{2E}\u{32}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{32}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}\u{67}\u{6C}\u{69}\u{6E}\u{74}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{31}\u{2E}\u{32}\u{2E}\u{30}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{32}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}\u{A}\u{5B}\u{64}\u{65}\u{76}\u{2D}\u{64}\u{65}\u{70}\u{65}\u{6E}\u{64}\u{65}\u{6E}\u{63}\u{69}\u{65}\u{73}\u{5D}\u{A}\u{67}\u{6C}\u{65}\u{65}\u{75}\u{6E}\u{69}\u{74}\u{20}\u{3D}\u{20}\u{22}\u{3E}\u{3D}\u{20}\u{31}\u{2E}\u{30}\u{2E}\u{30}\u{20}\u{61}\u{6E}\u{64}\u{20}\u{3C}\u{20}\u{32}\u{2E}\u{30}\u{2E}\u{30}\u{22}\u{A}"

fn cog_error_to_string(error: CogError, file: String) -> String {
  let reason = case error {
    InvalidPathError(path) -> "Given path not valid: `" <> path <> "`"
    UnexpectedToken(token) ->
      "Did not expect to see token: `"
      <> glexer_printer.print_token(token)
      <> "`"
    FileNotFound(path) -> "File not found with path: `" <> path <> "`"
    FileError(error) ->
      "An unexpected file error occurred: " <> string.inspect(error)
  }

  "Encountered an error whilst processing file `" <> file <> "`:\n\t" <> reason
}

pub fn main() {
  glint.new()
  |> glint.with_name("cog")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: main_command())
  |> glint.run(argv.load().arguments)
}

fn main_command() -> glint.Command(Nil) {
  use <- glint.command_help("Runs cog on the current project")
  use _, _, _ <- glint.command()

  let _ =
    in_project(fn(root, files) {
      dict.each(files, fn(path, content) {
        let result = {
          use source <- result.try(run(on: content, in: root))

          simplifile.write(to: path, contents: source)
          |> result.map_error(FileError)
        }

        case result {
          Ok(Nil) -> Nil
          Error(error) -> io.println_error(cog_error_to_string(error, path))
        }
      })
    })

  Nil
}

pub fn run(on content: String, in dir: String) -> Result(String, CogError) {
  let tokens = glexer.new(content) |> glexer.lex
  let tokens = list.map(tokens, fn(token) { token.0 })

  // Perform code generation
  use tokens <- result.try(perform_actions(tokens, in: dir))

  Ok(glexer_printer.print(tokens))
}

pub fn is_up_to_date() -> Result(Bool, CogError) {
  result.flatten({
    use root, files <- in_project()

    use matches <- result.try({
      dict.to_list(files)
      |> list.try_map(fn(file) {
        let #(_name, content) = file

        use output <- result.try(run(on: content, in: root))

        Ok(output == content)
      })
    })

    Ok(matches |> list.all(fn(match) { match == True }))
  })
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
    // Handle the cog:embed action
    [token.CommentNormal("cog:embed " <> path) as t1, ..tokens] -> {
      let #(comments, tokens) = skip_space_and_comments(tokens)

      case tokens {
        // const <name> = "<string>"
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
            list.flatten([[t1], comments, [t2, t3, t4, t5, t6, t7]])
            |> cog_embed(path, in: dir)
          })

          do_perform_actions(tokens, dir, list.append(generated, acc))
        }
        // const <name>: String = "<string>"
        [
          token.Const as t2,
          token.Space(_) as t3,
          token.Name(_) as t4,
          token.Colon as t5,
          token.Space(_) as t6,
          token.UpperName("String") as t7,
          token.Space(_) as t8,
          token.Equal as t9,
          token.Space(_) as t10,
          token.String(_),
          ..tokens
        ] -> {
          use generated <- result.try({
            list.flatten([[t1], comments, [t2, t3, t4, t5, t6, t7, t8, t9, t10]])
            |> cog_embed(path, in: dir)
          })

          do_perform_actions(tokens, dir, list.append(generated, acc))
        }
        // pub const <name> = "<string>"
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
            list.flatten([[t1], comments, [t2, t3, t4, t5, t6, t7, t8, t9]])
            |> cog_embed(path, in: dir)
          })

          do_perform_actions(tokens, dir, list.append(generated, acc))
        }
        // pub const <name>: String = "<string>"
        [
          token.Pub as t2,
          token.Space(_) as t3,
          token.Const as t4,
          token.Space(_) as t5,
          token.Name(_) as t6,
          token.Colon as t7,
          token.Space(_) as t8,
          token.UpperName("String") as t9,
          token.Space(_) as t10,
          token.Equal as t11,
          token.Space(_) as t12,
          token.String(_),
          ..tokens
        ] -> {
          use generated <- result.try({
            list.flatten([
              [t1],
              comments,
              [t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12],
            ])
            |> cog_embed(path, in: dir)
          })

          do_perform_actions(tokens, dir, list.append(generated, acc))
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
    let path = filepath.join(dir, path)

    simplifile.read(path)
    |> result.map_error(fn(error) {
      case error {
        simplifile.Enoent -> FileNotFound(path)
        _ -> FileError(error)
      }
    })
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

// ============= //
// Lex Utilities //
// ============= //

fn skip_space_and_comments(
  tokens: List(token.Token),
) -> #(List(token.Token), List(token.Token)) {
  list.split_while(tokens, fn(token) {
    case token {
      token.Space(_)
      | token.CommentDoc(_)
      | token.CommentNormal(_)
      | token.CommentModule(_) -> True
      _ -> False
    }
  })
}

// ============== //
// File Utilities //
// ============== //

fn in_project(
  action: fn(String, Dict(String, String)) -> a,
) -> Result(a, CogError) {
  use root <- result.try(find_project_root())
  use files <- result.try(find_project_files(in: root))

  use files <- result.try(
    list.try_map(files, fn(file) {
      use content <- result.try({
        simplifile.read(file)
        |> result.map_error(FileError)
      })

      Ok(#(file, content))
    }),
  )

  Ok(action(root, files |> dict.from_list))
}

fn find_project_files(in root: String) -> Result(List(String), CogError) {
  // Get all source files
  use source_files <- result.try({
    simplifile.get_files(in: filepath.join(root, "src"))
    |> result.map_error(FileError)
  })

  // Get all test files
  use test_files <- result.try({
    simplifile.get_files(in: filepath.join(root, "test"))
    |> result.map_error(FileError)
  })

  Ok({
    list.append(source_files, test_files)
    |> list.filter(string.ends_with(_, ".gleam"))
  })
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
