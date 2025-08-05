#let p = plugin("./lure.wasm")

/// Normalize an URL.
///
/// If necessary, `input` will be UTF-8 percent-encoded.
///
/// See also #link("https://docs.rs/url/latest/url/struct.Url.html#method.parse")[`Url::parse`]
/// and #link("https://docs.rs/url/latest/url/struct.Url.html#impl-Display-for-Url")[`Display::fmt`] in rust docs.
///
/// = Examples
///
/// #example(`
///   // Unchanged for regular URLs
///   #assert.eq(
///     normalize("https://en.wikipedia.org/w/index.php?title=%25&redirect=no"),
///     "https://en.wikipedia.org/w/index.php?title=%25&redirect=no",
///   )
///
///   // Encoded for non-ASCII URLs
///   #assert.eq(
///     normalize("https://law.go.kr/법령/보건의료기본법/제3조"),
///     "https://law.go.kr/%EB%B2%95%EB%A0%B9/%EB%B3%B4%EA%B1%B4%EC%9D%98%EB%A3%8C%EA%B8%B0%EB%B3%B8%EB%B2%95/%EC%A0%9C3%EC%A1%B0",
///   )
///   #assert.eq(
///     normalize("https://w3c.github.io/clreq/README.zh-Hans.html#讨论"),
///     "https://w3c.github.io/clreq/README.zh-Hans.html#%E8%AE%A8%E8%AE%BA",
///   )
///   #assert.eq(
///     normalize("https://w3c.github.io/clreq/README.zh-Hant.html#討論"),
///     "https://w3c.github.io/clreq/README.zh-Hant.html#%E8%A8%8E%E8%AB%96",
///   )
///   #assert.eq(
///     normalize("https://ja.wikipedia.org/wiki/アルベルト・アインシュタイン"),
///     "https://ja.wikipedia.org/wiki/%E3%82%A2%E3%83%AB%E3%83%99%E3%83%AB%E3%83%88%E3%83%BB%E3%82%A2%E3%82%A4%E3%83%B3%E3%82%B7%E3%83%A5%E3%82%BF%E3%82%A4%E3%83%B3",
///   )
/// `)
///
/// = Panics
///
/// If the function can not parse an URL from the given string
/// with this URL as the base URL, a `ParseError` will be thrown.
///
/// - input (str):
/// -> str
#let normalize(input) = str(p.parse_display_fmt(bytes(input)))

// TODO: Document `parse` and `parse-supplementary`
#let parse(input) = cbor(p.parse_debug_fmt(bytes(input)))
#let parse-supplementary(input) = cbor(p.parse_supplementary(bytes(input)))

/// Parse a string as an URL, with this URL as the base URL.
///
/// The inverse of this is `make-relative`.
///
/// See also #link("https://docs.rs/url/latest/url/struct.Url.html#method.join")[`Url::join` in rust docs].
///
/// = Notes
///
/// - A trailing slash is significant.
///   Without it, the last path component is considered to be a “file” name
///   to be removed to get at the “directory” that is used as the base.
/// - A #link("https://url.spec.whatwg.org/#scheme-relative-special-url-string")[scheme relative special URL]
///   as input replaces everything in the base URL after the scheme.
/// - An absolute URL (with a scheme) as input replaces the whole base URL (even the scheme).
///
/// = Examples
///
/// #example(`
///   // Base without a trailing slash
///   #assert.eq(
///     join("https://example.net/a/b.html", "c.png"),
///     "https://example.net/a/c.png", // Not /a/b.html/c.png
///   )
///
///   // Base with a trailing slash
///   #assert.eq(
///     join("https://example.net/a/b/", "c.png"),
///     "https://example.net/a/b/c.png",
///   )
///
///   // Input as scheme relative special URL
///   #assert.eq(
///     join("https://alice.com/a", "//eve.com/b"),
///     "https://eve.com/b",
///   )
///
///   // Input as absolute URL
///   #assert.eq(
///     join("https://alice.com/a", "http://eve.com/b"),
///     "http://eve.com/b", // http instead of https
///   )
/// `)
///
/// = Panics
///
/// If the function can not parse an URL from the given string
/// with this URL as the base URL, a `ParseError` will be thrown.
///
/// - base (str):
/// - url (str):
/// -> str
#let join(base, url) = str(p.join(bytes(base), bytes(url)))

/// Creates a relative URL if possible, with this URL as the base URL.
///
/// This is the inverse of `join`.
///
/// See also #link("https://docs.rs/url/latest/url/struct.Url.html#method.make_relative")[`Url::make_relative` in rust docs].
///
/// = Examples
///
/// #example(`
///   #assert.eq(
///     make-relative("https://example.net/a/b.html", "https://example.net/a/c.png"),
///     "c.png",
///   )
///
///   #assert.eq(
///     make-relative("https://example.net/a/b/", "https://example.net/a/b/c.png"),
///     "c.png",
///   )
///
///   #assert.eq(
///     make-relative("https://example.net/a/b/", "https://example.net/a/d/c.png"),
///     "../d/c.png",
///   )
///
///   #assert.eq(
///     make-relative("https://example.net/a/b.html?c=d", "https://example.net/a/b.html?e=f"),
///     "?e=f",
///   )
/// `)
///
/// = Errors
///
/// If this URL can’t be a base for the given URL, `none` is returned. This is for example the case if the scheme, host or port are not the same.
///
/// - base (str):
/// - url (str):
/// -> str
#let make-relative(base, url) = cbor(p.make_relative(bytes(base), bytes(url)))
