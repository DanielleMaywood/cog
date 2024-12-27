import cog
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

const source = "
// normal comment
fn wibble() { todo }

//cog:embed test/input0.txt
const input0 = \"\"

//cog:embed test/input1.txt
const input1 = \"data already here\"

// normal comment
fn wobble() { todo }
"

pub fn simple_embed_test() {
  let assert Ok(output) = cog.run(on: source)

  should.equal(
    output,
    "
// normal comment
fn wibble() { todo }

//cog:embed test/input0.txt
const input0 = \"\\u{68}\\u{65}\\u{6C}\\u{6C}\\u{6F}\\u{2C}\\u{20}\\u{6A}\\u{6F}\\u{65}\\u{21}\\u{A}\"

//cog:embed test/input1.txt
const input1 = \"\\u{67}\\u{6F}\\u{6F}\\u{64}\\u{62}\\u{79}\\u{65}\\u{2C}\\u{20}\\u{6A}\\u{6F}\\u{65}\\u{21}\\u{A}\"

// normal comment
fn wobble() { todo }
",
  )
}
