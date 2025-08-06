export TYPST_FEATURES := "html"

# List available recipes
list:
    @just --list

# Build WebAssembly and documents
build:
    cargo bw
    typst compile typ/lib.typ - --format=svg >/dev/null

# Initial setup (install necessary toolchains, create symlinks, etc.)
setup:
    rustup default stable
    rustup target add wasm32-unknown-unknown
    cd typ/ && ln --symbolic {{ quote(clean("../target/wasm32-unknown-unknown/release/lure.wasm")) }} lure.wasm

# Format rust and typst codes (requires typstyle)
fmt:
    cargo fmt
    typstyle typ/ --inplace

# Test the typst library (requires tinymist)
test *ARGS:
    # typst gives better error messages than tinymist
    typst compile typ/tests.typ - --format=html >/dev/null
    tinymist test typ/tests.typ --ignore-system-fonts {{ ARGS }}

# Run typship
[private]
typship *ARGS:
    typship {{ ARGS }}

# Test examples in README (requires typship)
test-readme: (typship "dev") && (typship "clean")
    #!/usr/bin/env python
    import re
    from pathlib import Path
    from subprocess import run

    readme = Path("README.md").read_text(encoding="utf-8")
    assert "lib.typ" not in readme

    docs: list[str] = re.findall(r"```typst\n(.+?)\n```", readme, re.DOTALL)

    assert docs
    print(f"Found {len(docs)} examples in README.")

    for doc in docs:
        result = run(
            ["typst", "compile", "-", "-", "--format=svg"],
            text=True,
            input=doc,
            check=True,
            capture_output=True,
        )
        assert not result.stderr, f"stderr should be empty, but not: {result.stderr}"
        print("✅", end="")
    
    print("\nAll examples compiled successfully.")
