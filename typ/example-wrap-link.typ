#metadata(none) <test-html-example>

#import "lib.typ": normalize

#let link(dest, ..body) = {
  assert.eq(body.named(), (:))
  assert(body.pos().len() <= 1)

  std.link(
    normalize(dest),
    body.pos().at(0, default: dest.replace(regex("^(mailto|tel)://"), "")),
  )
}

- #link("mailto://carmen@silicon.com")
- #link("https://w3c.github.io/clreq/README.zh-Hans.html#讨论")
