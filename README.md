# swSTL

A lightweight Swift command-line tool for inspecting, scaling, and converting STL files.

## Requirements

- A platform that supports Swift
- Swift 6.2 or higher

Check your Swift version:

```bash
swift --version
```

## Installation

### Build

Build using Swift Package Manager:

```bash
swift build -c release
```

The compiled binary will be located at:

```bash
.build/release/swSTL
```

### Install Globally

Move the binary to a directory in your `$PATH` (e.g., `/usr/local/bin`):

```bash
cp .build/release/swSTL /usr/local/bin/swSTL
```

Verify installation:

```bash
swSTL --help
```

## Usage Examples

```bash
# query STL file
swSTL info my3dpart.stl

# Scale 3x and convert to ASCII format
swSTL convert 3:1 -f ascii my3dpart.stl my3dpart.scaled3x.stl
```

## Running Without Installing

You can run the tool directly:

```bash
.build/release/swSTL
```

Or via Swift:

```bash
swift run swSTL
```

## Uninstall

If installed manually:

```bash
rm /usr/local/bin/swSTL
```

## Development

Build in debug mode:

```bash
swift build
```

Run tests:

```bash
swift test
```

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## License

MIT
