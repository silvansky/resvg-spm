# resvg-spm

Swift Package Manager distribution of [resvg](https://github.com/linebender/resvg) — a fast, correct SVG rendering library written in Rust — as a prebuilt `xcframework` plus a thin Swift overlay.

> Package versions mirror the bundled resvg version.

> **iOS-only for now.** Ships `ios-arm64` (device) and `ios-arm64-simulator` slices. macOS / Catalyst / tvOS are not yet supported.

## Requirements

- iOS 13+
- Swift 5.9+

## Installation

Add the dependency in Xcode (*File ▸ Add Package Dependencies…*) or in `Package.swift`:

```swift
.package(url: "https://github.com/silvansky/resvg-spm.git", from: "0.47.0")
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Resvg", package: "resvg-spm")
])
```

## Usage

```swift
import ResvgSwift
```

`ResvgSwift` re-exports resvg's C API (via `CResvg`) and adds a Swift `ResvgError` enum that maps the C error codes. The wrapper is intentionally minimal — application-specific concerns (font loading, CSS sanitization, image wrapping) belong in your app.

### Parse + render

```swift
let svgData: Data = …

guard let options = resvg_options_create() else { throw ResvgError.unknown(0) }
defer { resvg_options_destroy(options) }

var tree: OpaquePointer?
let code = svgData.withUnsafeBytes { ptr in
    resvg_parse_tree_from_data(
        ptr.baseAddress?.assumingMemoryBound(to: CChar.self),
        UInt(svgData.count),
        options,
        &tree
    )
}
if let error = ResvgError(code: UInt32(code)) { throw error }
guard let tree else { throw ResvgError.unknown(UInt32(code)) }
defer { resvg_tree_destroy(tree) }

let size = resvg_get_image_size(tree)
let pixelWidth = UInt32(size.width)
let pixelHeight = UInt32(size.height)
let transform = resvg_transform(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0)

var pixels = [UInt8](repeating: 0, count: Int(pixelWidth * pixelHeight * 4))
pixels.withUnsafeMutableBytes { buf in
    resvg_render(tree, transform, pixelWidth, pixelHeight,
                 buf.baseAddress?.assumingMemoryBound(to: CChar.self))
}
// `pixels` is premultiplied RGBA (4 bytes/px) — wrap in CGImage or upload to a texture.
```

### Fonts

`fontdb` (resvg's font database) has no system-font scanner on iOS — `resvg_options_load_system_fonts()` compiles but is effectively a no-op. To render `<text>` you must enumerate faces yourself (CoreText is the usual path) and feed each one to resvg.

`load_font_file` is the recommended path — it mmaps the file and returns an error code on failure:

```swift
let result = url.path.withCString { resvg_options_load_font_file(options, $0) }
if result != RESVG_OK.rawValue { /* log + skip */ }
```

`load_font_data(bytes, len)` is also available but copies the bytes into Rust's heap.

Accepted font formats: TTF, OTF, TTC, OTC. WOFF / WOFF2 are silently skipped — decompress before passing.

### Errors

`ResvgError`: `.parsingFailed`, `.invalidSize`, `.notUTF8String`, `.fileOpenFailed`, `.malformedGzip`, `.elementsLimitReached`, `.unknown(code)`. Map a raw C result with `ResvgError(code:)` — returns `nil` for `RESVG_OK`.

### Logging

resvg's internal Rust logger is off by default. Opt in once at startup if you want the warn-level diagnostics:

```swift
resvg_init_log()
```

## Building the xcframework

```bash
./build.sh           # latest resvg release
./build.sh 0.47.0    # specific tag
```

Produces `resvg.xcframework.zip` and prints the SPM checksum to drop into `Package.swift`.

## License

Dual-licensed under [Apache-2.0](LICENSE-APACHE) or [MIT](LICENSE-MIT), matching upstream resvg.
