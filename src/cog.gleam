import argv
import filepath
import gleam/bit_array
import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glexer
import glexer/token
import glint
import simplifile

pub fn main() {
  glint.new()
  |> glint.with_name("cog")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: main_command())
  |> glint.run(argv.load().arguments)
}

pub type CogError {
  InvalidPathError(String)
  UnexpectedEndOfFile
  UnexpectedToken(#(token.Token, glexer.Position))
  FileNotFound(String)
  FileError(simplifile.FileError)
  MergeError
}

pub fn describe_error(error: CogError, file: String) -> String {
  let reason = case error {
    InvalidPathError(path) -> "Given path not valid: `" <> path <> "`"
    UnexpectedEndOfFile -> "Was expecting another token, found end of file"
    UnexpectedToken(#(token, _)) ->
      "Did not expect to see token: `"
      <> glexer.to_source([#(token, glexer.Position(0))])
      <> "`"
    FileNotFound(path) -> "File not found with path: `" <> path <> "`"
    FileError(error) ->
      "An unexpected file error occurred: " <> string.inspect(error)
    MergeError -> "An unexpected error occurred whilst merging tokens"
  }

  "Encountered an error whilst processing file `" <> file <> "`:\n\t" <> reason
}

pub fn run(on content: String, in dir: String) -> Result(String, CogError) {
  let original = glexer.new(content) |> glexer.lex

  let tokens = drop_space_and_comments(original)
  use tokens <- result.try(perform_actions(tokens, in: dir))

  use merged <- result.try(merge(original, tokens))

  Ok(glexer.to_source(merged))
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

fn main_command() -> glint.Command(Nil) {
  use <- glint.command_help("Runs cog on the current project")
  use verbose <- glint.flag({
    glint.bool_flag("verbose")
    |> glint.flag_default(False)
    |> glint.flag_help("Set verbose logging")
  })
  use _, _, flags <- glint.command()

  let assert Ok(verbose) = verbose(flags)

  let _ =
    in_project(fn(root, files) {
      dict.each(files, fn(path, content) {
        let result = {
          use source <- result.try(run(on: content, in: root))

          simplifile.write(to: path, contents: source)
          |> result.map_error(FileError)
        }

        case result {
          Ok(Nil) ->
            case verbose {
              True ->
                io.println("Successfully processed file: `" <> path <> "`")
              False -> Nil
            }
          Error(error) -> io.println_error(describe_error(error, path))
        }
      })
    })

  io.println("⚙️ Finished")
}

fn perform_actions(
  in dir: String,
  with tokens: List(#(token.Token, glexer.Position)),
) -> Result(List(#(token.Token, glexer.Position)), CogError) {
  do_perform_actions(dir, tokens, [])
  |> result.map(list.reverse)
}

fn do_perform_actions(
  dir: String,
  tokens: List(#(token.Token, glexer.Position)),
  acc: List(#(token.Token, glexer.Position)),
) -> Result(List(#(token.Token, glexer.Position)), CogError) {
  case tokens {
    [] -> Ok(acc)
    // Handle `//cog:embed` directive
    [#(token.CommentNormal("cog:embed " <> path), _) as t1, ..tokens] ->
      case tokens {
        [] -> Error(UnexpectedEndOfFile)

        // const <name> = "<string>"
        [
          #(token.Const, _) as t2,
          #(token.Name(_), _) as t3,
          #(token.Equal, _) as t4,
          #(token.String(_), pos),
          ..tokens
        ] -> {
          use string <- result.try(cog_embed_string(file: path, in: dir))

          [#(token.String(string), pos), t4, t3, t2, t1, ..acc]
          |> do_perform_actions(dir, tokens, _)
        }

        // const <name>: String = "<string>"
        [
          #(token.Const, _) as t2,
          #(token.Name(_), _) as t3,
          #(token.Colon, _) as t4,
          #(token.UpperName("String"), _) as t5,
          #(token.Equal, _) as t6,
          #(token.String(_), pos),
          ..tokens
        ] -> {
          use string <- result.try(cog_embed_string(file: path, in: dir))

          [#(token.String(string), pos), t6, t5, t4, t3, t2, t1, ..acc]
          |> do_perform_actions(dir, tokens, _)
        }

        // pub const <name> = "<string>"
        [
          #(token.Pub, _) as t2,
          #(token.Const, _) as t3,
          #(token.Name(_), _) as t4,
          #(token.Equal, _) as t5,
          #(token.String(_), pos),
          ..tokens
        ] -> {
          use string <- result.try(cog_embed_string(file: path, in: dir))

          [#(token.String(string), pos), t5, t4, t3, t2, t1, ..acc]
          |> do_perform_actions(dir, tokens, _)
        }

        // pub const <name>: String = "<string>"
        [
          #(token.Pub, _) as t2,
          #(token.Const, _) as t3,
          #(token.Name(_), _) as t4,
          #(token.Colon, _) as t5,
          #(token.UpperName("String"), _) as t6,
          #(token.Equal, _) as t7,
          #(token.String(_), pos),
          ..tokens
        ] -> {
          use string <- result.try(cog_embed_string(file: path, in: dir))

          [#(token.String(string), pos), t7, t6, t5, t4, t3, t2, t1, ..acc]
          |> do_perform_actions(dir, tokens, _)
        }

        [token, ..] -> Error(UnexpectedToken(token))
      }
    [token, ..tokens] -> do_perform_actions(dir, tokens, [token, ..acc])
  }
}

fn cog_embed(file path: String, in dir: String) -> Result(BitArray, CogError) {
  use path <- result.try({
    filepath.expand(path)
    |> result.map_error(fn(_) { InvalidPathError(path) })
  })

  let path = filepath.join(dir, path)

  simplifile.read_bits(path)
  |> result.map_error(fn(error) {
    case error {
      simplifile.Enoent -> FileNotFound(path)
      _ -> FileError(error)
    }
  })
}

fn cog_embed_string(
  file path: String,
  in dir: String,
) -> Result(String, CogError) {
  use data <- result.try(cog_embed(path, dir))
  use data <- result.try({
    bit_array.to_string(data)
    |> result.replace_error(FileError(simplifile.NotUtf8))
  })

  let encoded =
    data
    |> string.replace("\\", "\\\\")
    |> string.replace("\"", "\\\"")

  Ok(encoded)
}

//============================//
//       File Utilities       //
//============================//

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
  use source_files <- result.try(find_project_files_at(root, at: "src"))
  use test_files <- result.try(find_project_files_at(root, at: "test"))

  Ok({
    list.append(source_files, test_files)
    |> list.filter(string.ends_with(_, ".gleam"))
  })
}

fn find_project_files_at(
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

//============================//
//         Utilities          //
//============================//

fn drop_space_and_comments(tokens: List(#(token.Token, glexer.Position))) {
  list.filter(tokens, fn(token) {
    case token.0 {
      // We want to keep any "//cog:" comments
      token.CommentNormal("cog:" <> _) -> True
      token.Space(_)
      | token.CommentNormal(_)
      | token.CommentModule(_)
      | token.CommentDoc(_) -> False
      _ -> True
    }
  })
}

fn merge(
  original original: List(#(token.Token, glexer.Position)),
  updated updated: List(#(token.Token, glexer.Position)),
) -> Result(List(#(token.Token, glexer.Position)), CogError) {
  do_merge(original, updated, [])
  |> result.map(list.reverse)
}

fn do_merge(
  original: List(#(token.Token, glexer.Position)),
  updated: List(#(token.Token, glexer.Position)),
  acc: List(#(token.Token, glexer.Position)),
) -> Result(List(#(token.Token, glexer.Position)), CogError) {
  case original, updated {
    [], [] -> Ok(acc)
    // If the position matches, choose the new token
    [#(_, x), ..xs], [#(_, y) as token, ..ys] if x == y ->
      do_merge(xs, ys, [token, ..acc])
    // If the position doesn't match, choose from the original
    [#(_, x) as token, ..xs], [#(_, y), ..] if x != y ->
      do_merge(xs, updated, [token, ..acc])
    // If the original still has data use that
    [token, ..xs], [] -> do_merge(xs, [], [token, ..acc])
    _, _ -> Error(MergeError)
  }
}
