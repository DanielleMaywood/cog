import cog
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn simple_embed_test() {
  let source =
    "
// normal comment
fn wibble() { todo }

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
pub const input0 = \"\"

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
pub const input0: String = \"\"

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
const input0 = \"\"

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
const input0: String = \"\"

// normal comment
fn wobble() { todo }
"

  let assert Ok(output) = cog.run(on: source, in: "./")

  should.equal(
    output,
    "
// normal comment
fn wibble() { todo }

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
pub const input0 = \"hello, \\\"joe\\\"!\n\"

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
pub const input0: String = \"hello, \\\"joe\\\"!\n\"

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
const input0 = \"hello, \\\"joe\\\"!\n\"

//cog:embed test/input0.txt
/// This is a wibble
/// This is a wobble
const input0: String = \"hello, \\\"joe\\\"!\n\"

// normal comment
fn wobble() { todo }
",
  )
}

pub fn text_already_present_test() {
  let source =
    "
// normal comment
fn wibble() { todo }

//cog:embed test/input1.txt
const input1 = \"data already here\"

// normal comment
fn wobble() { todo }
"

  let assert Ok(output) = cog.run(on: source, in: "./")

  should.equal(
    output,
    "
// normal comment
fn wibble() { todo }

//cog:embed test/input1.txt
const input1 = \"goodbye, joe!\\\\n\n\"

// normal comment
fn wobble() { todo }
",
  )
}
