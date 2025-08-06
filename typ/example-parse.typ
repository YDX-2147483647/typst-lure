#metadata(none) <test-html-example>

#import "lib.typ": parse, parse-supplementary

#let urls = (
  ```
  https://github.com/example/repo.git
  ssh://git@github.com/example/repo.git
  ssh://git@ssh.github.com:443/example/repo.git
  git://github.com/whatwg/url.git
  https://law.go.kr/법령/보건의료기본법/제3조
  https://w3c.github.io/clreq/README.zh-Hans.html#讨论
  https://w3c.github.io/clreq/README.zh-Hant.html#討論
  https://ja.wikipedia.org/wiki/アルベルト・アインシュタイン
  https://w3c.github.io/clreq/README.zh-Hans.html#%E8%AE%A8%E8%AE%BA
  ```
    .text
    .split(regex("\r?\n"))
)

#for u in urls {
  repr(parse(u))
  repr(parse-supplementary(u))

  parbreak()
}
