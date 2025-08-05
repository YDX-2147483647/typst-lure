use std::{borrow::Cow, str::Utf8Error};

use ciborium::ser::into_writer;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use url::{self, ParseError, Url};
use wasm_minimal_protocol::{initiate_protocol, wasm_func};

initiate_protocol!();

#[derive(Error, Debug, PartialEq)]
pub enum TypstError {
    #[error("failed parse bytes as UTF-8: {{ input: {input:?}, error: {error:?} }}")]
    InputError { input: Vec<u8>, error: Utf8Error },
    #[error("failed to parse URL: {{ input: {input:?}, error: {error:?} }}")]
    ParseError { input: String, error: ParseError },
}

fn parse_str(input: &[u8]) -> Result<&str, TypstError> {
    str::from_utf8(input).map_err(|error| TypstError::InputError {
        input: input.to_vec(),
        error,
    })
}

/// https://docs.rs/url/2.5.4/url/struct.Url.html#method.parse
fn parse_url(input: &[u8]) -> Result<Url, TypstError> {
    let input = parse_str(input)?;
    Url::parse(input).map_err(|error| TypstError::ParseError {
        input: input.to_string(),
        error,
    })
}

/// https://docs.rs/url/2.5.4/url/struct.Url.html#impl-Display-for-Url
#[wasm_func]
pub fn parse_display_fmt(input: &[u8]) -> Result<Vec<u8>, TypstError> {
    let url = parse_url(input)?;
    Ok(url.as_str().as_bytes().to_vec())
}

/// https://docs.rs/url/2.5.4/url/struct.Url.html#impl-Debug-for-Url
#[derive(Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
struct UrlRepr<'a> {
    scheme: &'a str,
    cannot_be_a_base: bool,
    username: &'a str,
    password: Option<&'a str>,
    host: Option<&'a str>,
    port: Option<u16>,
    path: &'a str,
    query: Option<&'a str>,
    fragment: Option<&'a str>,
}

/// https://docs.rs/url/2.5.4/url/struct.Url.html#impl-Debug-for-Url
#[wasm_func]
pub fn parse_debug_fmt(input: &[u8]) -> Result<Vec<u8>, TypstError> {
    let url = parse_url(input)?;

    let repr = UrlRepr {
        scheme: url.scheme(),
        cannot_be_a_base: url.cannot_be_a_base(),
        username: url.username(),
        password: url.password(),
        // `url.host()` is too complicated
        host: url.host_str(),
        port: url.port(),
        path: url.path(),
        query: url.query(),
        fragment: url.fragment(),
    };

    let mut out = Vec::new();
    into_writer(&repr, &mut out).unwrap();
    Ok(out)
}

#[derive(Serialize)]
#[serde(rename_all = "kebab-case")]
struct UrlReprSupplementary<'a> {
    origin: Option<(String, String, u16)>,
    is_special: bool,
    authority: &'a str,
    domain: Option<&'a str>,
    port_or_known_default: Option<u16>,
    path_segments: Option<Vec<&'a str>>,
    query_pairs: Vec<(Cow<'a, str>, Cow<'a, str>)>,
}

#[wasm_func]
pub fn parse_supplementary(input: &[u8]) -> Result<Vec<u8>, TypstError> {
    let url = parse_url(input)?;

    let repr = UrlReprSupplementary {
        origin: match url.origin() {
            url::Origin::Opaque(_) => None,
            url::Origin::Tuple(scheme, host, port) => Some((scheme, host.to_string(), port)),
        },
        is_special: url.is_special(),
        authority: url.authority(),
        domain: url.domain(),
        port_or_known_default: url.port_or_known_default(),
        path_segments: url.path_segments().map(|c| c.collect()),
        query_pairs: url.query_pairs().collect(),
    };

    let mut out = Vec::new();
    into_writer(&repr, &mut out).unwrap();
    Ok(out)
}

#[wasm_func]
pub fn join(base: &[u8], url: &[u8]) -> Result<Vec<u8>, TypstError> {
    let base = parse_url(base)?;
    let url = parse_str(url)?;
    let result = base.join(url).map_err(|error| TypstError::ParseError {
        input: url.to_string(),
        error,
    })?;

    Ok(result.as_str().as_bytes().to_vec())
}

#[wasm_func]
pub fn make_relative(base: &[u8], url: &[u8]) -> Result<Vec<u8>, TypstError> {
    let base = parse_url(base)?;
    let url = parse_url(url)?;
    let relative = base.make_relative(&url);

    let mut out = Vec::new();
    into_writer(&relative, &mut out).unwrap();
    Ok(out)
}
