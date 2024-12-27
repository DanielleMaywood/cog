# cog

[![Package Version](https://img.shields.io/hexpm/v/cog)](https://hex.pm/packages/cog)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cog/)

```sh
gleam add --dev cog@2
```

## Introduction

Do you want to embed a file into your gleam source code? Well now you can!

Given some text file `src/input.txt`

```
hello, joe!
```

And a Gleam source file

```gleam
//cog:embed src/input.txt
const input = ""
```

If you run the following command

```sh
gleam run -m cog
```

You'll find your Gleam source file has been updated to

```gleam
//cog:embed src/input.txt
const input = "\u{68}\u{65}\u{6C}\u{6C}\u{6F}\u{2C}\u{20}\u{6A}\u{6F}\u{65}\u{21}"
```
