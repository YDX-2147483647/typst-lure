#import "lib.typ": (
  join, make-relative, normalize, parse, parse-supplementary, with-query-pairs,
)

// Import test files
// https://myriad-dreamin.github.io/tinymist/feature/testing.html#label-Test%20Discovery
#import "example-wrap-link.typ"
#import "example-parse.typ"

/// Test examples in doc comments
///
/// Examples should be written in the tinymist style, exactly.
/// https://myriad-dreamin.github.io/tinymist/feature/docs.html#label-Examples%20in%20Docstrings
///
/// That is:
///
/// ```typ
/// /// #example(`
/// ///   $ sum f(x) = 10 $
/// ///   #assert.eq(1 + 1, 2)
/// /// `)
/// ```
#let test-doc-examples() = {
  let file = "lure.typ"
  let file-content = read(file)

  // Extract `doc-examples`
  //
  // The state is implemented in two fields:
  // - *`focus`*
  //   Either of the following variants.
  //   - `none`: outside any example
  //   - `array<str>`: lines of the focused example
  // - *`examples`*
  //   `array<str>`, parsed examples
  let doc-examples = file-content
    .split(regex("\r?\n"))
    .fold(
      (
        focus: none,
        examples: (),
      ),
      (last, line) => {
        if line == "/// #example(`" {
          assert.eq(last.focus, none)
          (
            focus: (),
            examples: last.examples,
          )
        } else if line == "/// `)" {
          assert.ne(last.focus, none)
          (
            focus: none,
            examples: last.examples + (last.focus.join("\n"),),
          )
        } else {
          (
            focus: if last.focus == none {
              none
            } else {
              last.focus + (line.trim(regex("^///\s+"), at: start),)
            },
            examples: last.examples,
          )
        }
      },
    )
    .examples

  assert(doc-examples.len() > 0, message: "failed to find any doc examples")
  assert.eq(
    doc-examples.len(),
    file-content.matches("#example").len(),
    message: "doc-example parsing might be erroneous; please check manually",
  )

  // Execute `doc-examples`
  for example in doc-examples {
    eval(
      ```typ
      #import "{file}": *
      {example}
      ```
        .text
        .replace("{file}", file)
        .replace("{example}", example),
      mode: "markup",
    )
  }
}

#let test-normalize() = {
  let inputs = ```
  https://law.go.kr/법령/보건의료기본법/제3조
  https://w3c.github.io/clreq/README.zh-Hans.html#讨论
  https://w3c.github.io/clreq/README.zh-Hant.html#討論
  https://ja.wikipedia.org/wiki/アルベルト・アインシュタイン
  ```
    .text
    .split(regex("\r?\n"))

  for input in inputs {
    let encoded = normalize(input)

    assert("%" in encoded, message: "should be UTF-8 percent-encoded")
    assert(
      encoded.match(regex(`^[\x00-\x7F]+$`.text)) != none,
      message: "should be fully ASCII",
    )
    assert.eq(
      normalize(encoded),
      encoded,
      message: "normalization should be idempotent",
    )
  }
}

#let test-make-relative-and-then-join() = {
  let cases = (
    ("https://example.net/a/b.html", "https://example.net/a/c.png"),
    ("https://example.net/a/b/", "https://example.net/a/b/c.png"),
    ("https://example.net/a/b/", "https://example.net/a/d/c.png"),
    ("https://example.net/a/b.html?c=d", "https://example.net/a/b.html?e=f"),
  )

  for (base, url) in cases {
    let relative = make-relative(base, url)
    assert.eq(join(base, relative), url)
  }
}

#let test-make-relative-returns-none() = {
  assert.eq(
    make-relative("https://a.org", "https://b.org"),
    none,
  )
}

#let test-with-query-pairs() = {
  assert.eq(
    with-query-pairs("https://example.com", none),
    "https://example.com/",
  )
  assert.eq(
    with-query-pairs("https://example.com", ()),
    "https://example.com/?",
  )

  // Preserve order
  assert.eq(
    with-query-pairs("https://example.com", (a: "1", c: "2", b: "3")),
    "https://example.com/?a=1&c=2&b=3",
  )

  // Duplicate keys
  assert.eq(
    with-query-pairs("https://example.com", (("a", "b"), ("a", "c"))),
    "https://example.com/?a=b&a=c",
  )

  // Encoding
  assert.eq(
    with-query-pairs("https://validator.citationstyles.org", (
      version: "1.0.2",
      url: "https://typst-doc-cn.github.io/csl-sanitizer/chinese/src/GB-T-7714—2025（顺序编码，双语）/GB-T-7714—2025（顺序编码，双语）.csl",
    )),
    "https://validator.citationstyles.org/?version=1.0.2&url=https%3A%2F%2Ftypst-doc-cn.github.io%2Fcsl-sanitizer%2Fchinese%2Fsrc%2FGB-T-7714%E2%80%942025%EF%BC%88%E9%A1%BA%E5%BA%8F%E7%BC%96%E7%A0%81%EF%BC%8C%E5%8F%8C%E8%AF%AD%EF%BC%89%2FGB-T-7714%E2%80%942025%EF%BC%88%E9%A1%BA%E5%BA%8F%E7%BC%96%E7%A0%81%EF%BC%8C%E5%8F%8C%E8%AF%AD%EF%BC%89.csl",
  )

  // The syntax is not well defined…
  assert.eq(
    parse-supplementary("https://lib.rs?url").query-pairs,
    (url: "").pairs(),
  )
  assert.eq(
    with-query-pairs("https://lib.rs", (url: "")),
    "https://lib.rs/?url=",
  )
}
