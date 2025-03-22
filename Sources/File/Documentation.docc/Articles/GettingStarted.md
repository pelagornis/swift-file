#  Getting started

Learn how to use File.

## Installation
File was deployed as Swift Package Manager. Package to install in a project. Add as a dependent item within the swift manifest.
```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/pelagornis/swift-file", from: "1.1.0")
    ],
    ...
)
```
Then import the File from thr location you want to use.

```swift
import File
```

## Using File
File offers the most commonly used Bash and ZSH, which in addition helps users scale easily.

Path Setting.

```swift
let path = Path("/Users/pelagornis/Desktop/") // example
```
Easy access Path.
```swift
Path.current
Path.root
Path.library
Path.temporary
Path.home
Path.documents
```
Easily create files and folders

```swift
let path = Path.home
let folder = try! Folder(path: path)
let file = try! folder.createFile(at: "test.swift")
try! file.write("print(1)")
```

Easy and quick delete files and folders.
``` swift
try! file.delete()
try! folder.delete()
```
