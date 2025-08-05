export TYPST_FEATURES := "html"

# Build WebAssembly and documents
build:
    cargo bw
    typst compile typ/lib.typ - --format=svg >/dev/null

# List available recipes
list:
    @just --list

# Initial setup (install necessary toolchains, create symlinks, etc.)
setup:
    rustup default stable
    rustup target add wasm32-unknown-unknown
    cd typ/ && ln --symbolic {{ quote(clean("../target/wasm32-unknown-unknown/release/lure.wasm")) }} lure.wasm

# Format rust and typst codes
fmt:
    cargo fmt
    typstyle typ/ --inplace

# Test the typst library
test *ARGS:
    # typst gives better error messages than tinymist
    typst compile typ/tests.typ - --format=html >/dev/null
    tinymist test typ/tests.typ --ignore-system-fonts {{ ARGS }}
