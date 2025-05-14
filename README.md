# File

![Official](https://badge.pelagornis.com/official.svg)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg)
[![License](https://img.shields.io/github/license/pelagornis/swift-file)](https://github.com/pelagornis/swift-file/blob/main/LICENSE)
![Platform](https://img.shields.io/badge/platforms-iOS%2013.0%7C%20tvOS%2013.0%7C%20macOS%2010.15%7C%20watchOS%206.0-red.svg)

📁 **File** is a powerful and intuitive file management library for Swift. It simplifies file and folder operations, providing a consistent API across different platforms. File is designed to make working with the file system a breeze, whether you're reading, writing, creating, or deleting files and folders.

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

## Documentation
The documentation for releases and ``main`` are available here:
- [``main``](https://pelagornis.github.io/swift-file/main/documentation/file)


## Using

Path Setting.
```swift
let path = Path("/Users/ji-hoonahn/Desktop/") // example
```

Easy access path.
```swift
Path.current
Path.root
Path.library
Path.temporary
Path.home
Path.documents
```

#### Writing String Data

This example demonstrates how to create a file and write a string to it.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "example.txt")
try file.write("Hello, File!")
```

#### Writing Binary Data

This example shows how to write binary data to a file.

```swift
import Foundation
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "binary.data")
let data = Data([0x00, 0x01, 0x02, 0x03])
try file.write(data)
```

#### Appending String Data

This example demonstrates how to append a string to an existing file.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "example.txt")
try file.append(" This is appended content.")
```

#### Appending Binary Data

This example shows how to append binary data to an existing file.

```swift
import Foundation
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "binary.data")
let data = Data([0x04, 0x05, 0x06, 0x07])
try file.append(data)
```

#### Reading Data

This example demonstrates how to read data from a file.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "example.txt")
try file.write("Hello, File!")
let readData = try file.read()
if let readString = String(data: readData, encoding: .utf8) {
    print(readString) // Output: Hello, File!
}
```

#### Opening a File (AppKit)

If `AppKit` is available, this example shows how to open a file using `AppKit`.

```swift
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "example.txt")
file.open()
#endif
```

#### Handling FileError

This example shows how to catch and handle `FileError`.

```swift
import File

let path = Path.root
let filePath = Path("/path/that/do/not/exist/example.txt")

do {
    let folder = try Folder(path: path)
    let file = try folder.createFile(at: filePath)
    try file.write("this will fail")
} catch let error as FileError {
    print("FileError: \(error.message)")
    if let underlyingError = error.error {
        print("Underlying error: \(underlyingError)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Folder Examples

#### Creating Subfolders and Files

This example demonstrates how to create subfolders and files within a folder.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let subfolder = try folder.createSubfolder(at: "subfolder")
let newFile = try subfolder.createFile(at: "newFile.txt")
try newFile.write("Content of the new file")
```

#### Retrieving Files and Subfolders

This example shows how to retrieve files and subfolders from a folder.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
_ = try folder.createSubfolder(at: "subfolder")
_ = try folder.createFile(at: "example.txt")
let files = folder.files
let subfolders = folder.subfolders
print(files) // Output: Contains "example.txt"
print(subfolders) // Output: Contains "subfolder"
```

#### Moving and Copying Contents

This example shows how to move and copy the contents of a folder to another folder.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let destinationFolder = try Folder(path: Path(path.rawValue + "destination"))
_ = try folder.createFile(at: "example.txt")
_ = try folder.createSubfolder(at: "subfolder")
try folder.moveContents(to: destinationFolder)
let files = destinationFolder.files
let subfolders = destinationFolder.subfolders
print(files) // Output: Contains "example.txt"
print(subfolders) // Output: Contains "subfolder"

let copyFolder = try Folder(path: Path(path.rawValue + "copy"))
try destinationFolder.copy(to: copyFolder)

```

#### Emptying the Folder

This example shows how to empty a folder (delete all its contents).

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
_ = try folder.createFile(at: "example.txt")
_ = try folder.createSubfolder(at: "subfolder")
try folder.empty()
```

#### Deleting Content

This example show how to delete subfolders and file

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "example.txt")
let subfolder = try folder.createSubfolder(at: "subfolder")
try file.delete()
try subfolder.delete()
```

### FileSystem Examples

#### Renaming

This example demonstrates how to rename a file or a folder.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "oldName.txt")
try file.rename(to: "newName")
print(file.name) // Output: newName.txt
```

#### Moving

This example shows how to move a file or a folder to a new location.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let destinationFolder = try Folder(path: Path(path.rawValue + "destination"))
let file = try folder.createFile(at: "example.txt")
try file.move(to: destinationFolder)
```

#### Copying

This example shows how to copy a file or a folder to a new location.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let destinationFolder = try Folder(path: Path(path.rawValue + "destination"))
let file = try folder.createFile(at: "example.txt")
try file.copy(to: destinationFolder)
```

#### Deleting

This example shows how to delete a file or a folder.

```swift
import File

let path = Path.temporary
let folder = try Folder(path: path)
let file = try folder.createFile(at: "example.txt")
try file.delete()
```


## License
**swift-file** is under MIT license. See the [LICENSE](LICENSE) file for more info.

