import cog/glexer_printer
import gleam/list
import gleam/string
import gleeunit/should
import glexer
import simplifile

pub fn roundtrip_test() {
  // Get all files in the root directory.
  // This also includes all files in the ./build directory
  // so we're testing we can roundtrip all our dependencies.
  let assert Ok(files) = simplifile.get_files("./")

  // Ensure we're only testing .gleam files
  let files = list.filter(files, string.ends_with(_, ".gleam"))

  // Ensure we aren't just testing nothing
  should.not_equal(list.length(files), 0)

  list.each(files, fn(file) {
    let assert Ok(content) = simplifile.read(file)

    let tokens = glexer.new(content) |> glexer.lex
    let tokens = list.map(tokens, fn(token) { token.0 })

    let output = glexer_printer.print(tokens)

    should.equal(content, output)
  })
}
