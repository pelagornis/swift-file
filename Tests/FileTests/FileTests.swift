import XCTest
import Logging
@testable import File

final class FileTests: XCTestCase {
    private var folder: Folder!
    
    override func setUp() {
        super.setUp()
        folder = try! Folder(path: .home).createSubfolder(at: ".plfileTest")
        try! folder.empty()
    }
    
    override func tearDown() {
        try? folder.delete()
        super.tearDown()
    }
    
    func testingCreateFile() {
        let file = try! folder.createFile(at: "test.swift")
        XCTAssertEqual(file.name, "test.swift")
        XCTAssertEqual(file.store.path.rawValue, folder.store.path.rawValue + "test.swift")
        XCTAssertEqual(file.extension, "swift")
        
        try XCTAssertEqual(file.read(), Data())
    }
    
    func testingFileWrite() {
        let file = try? folder.createFile(at: "testWrite.swift")
        try? file?.write("print(1)")
        
        try XCTAssertEqual(String(data: file!.read(), encoding: .utf8), "print(1)")
    }
    
    func testingFileMove() {
        let originFolder = try? folder.createSubfolder(at: "folderA")
        let targetFolder = try? folder.createSubfolder(at: "folderB")
        
        try? originFolder?.move(to: targetFolder!)
        XCTAssertEqual(originFolder?.store.path.rawValue, folder.store.path.rawValue + "folderB/folderA/" )
    }
    
    func testingPathStringLiteralConvertible() {
        let user: Path = "/Users"
        let userPath = Path("/Users")
        XCTAssertEqual(user, userPath)
    }

    func testingPathRoot() {
        let root = Path.root
        let pathRoot: Path = "/"
        XCTAssertEqual(root, pathRoot)
    }

    func testingPathCurrent() {
        let oldCurrent: Path = .current
        let newCurrent: Path = .userTemporary
        XCTAssertNotEqual(oldCurrent, newCurrent)
    }
    
    func testingPathHome() {
        let home = Path.home
        XCTAssertEqual(home.rawValue, NSHomeDirectory())
    }

    func testingPathDocuments() {
        XCTAssertNotEqual(Path.documents, Path())
    }

    func testingPathLibrary() {
        XCTAssertNotEqual(Path.library, Path())
    }

    func testFileAndFolderExistence() {
        let file = try! folder.createFile(at: "existTest.txt")
        XCTAssertTrue(file.exists())
        XCTAssertTrue(folder.exists())
        try! file.delete()
        XCTAssertFalse(file.exists())
    }

    func testSymbolicLink() {
        let target = try! folder.createFile(at: "target.txt")
        let linkPath = folder.store.path.rawValue + "link.txt"
        let linkStore = try! Store<File>(path: Path(linkPath), fileManager: .default)
        try! linkStore.createSymbolicLink(to: target.store.path)
        XCTAssertTrue(linkStore.isSymbolicLink())
        XCTAssertEqual(linkStore.destinationOfSymbolicLink()?.rawValue, target.store.path.rawValue)
    }

    func testPermissions() {
        let file = try! folder.createFile(at: "perm.txt")
        let originalPerm = file.store.getPermissions()
        try! file.store.setPermissions(0o600)
        let newPerm = file.store.getPermissions()
        XCTAssertEqual(newPerm, 0o600)
        if let orig = originalPerm { try? file.store.setPermissions(orig) }
    }

    func testWatch() {
        let file = try! folder.createFile(at: "watch.txt")
        let exp = expectation(description: "File change detected")
        #if os(macOS) || os(iOS)
        let source = file.store.watch {
            exp.fulfill()
        }
        try! file.write("changed!")
        wait(for: [exp], timeout: 2.0)
        if let src = source as? DispatchSourceFileSystemObject { src.cancel() }
        #else
        XCTAssertNil(file.store.watch { })
        #endif
    }
    
    func testAllFilesAndFolders() {
        // Create a directory structure for testing
        // .plfileTest/
        //   - file1.txt
        //   - subfolder1/
        //     - file2.txt
        //     - subfolder2/
        //       - file3.txt
        
        let file1 = try! folder.createFile(at: "file1.txt")
        let subfolder1 = try! folder.createSubfolder(at: "subfolder1")
        let file2 = try! subfolder1.createFile(at: "file2.txt")
        let subfolder2 = try! subfolder1.createSubfolder(at: "subfolder2")
        let file3 = try! subfolder2.createFile(at: "file3.txt")
        
        // Test non-recursive allFiles
        let files = folder.allFiles()
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first?.name, "file1.txt")
        
        // Test recursive allFiles
        let allFilesRecursive = folder.allFiles(recursive: true)
        XCTAssertEqual(allFilesRecursive.count, 3)
        let allFileNames = allFilesRecursive.map { $0.name }.sorted()
        XCTAssertEqual(allFileNames, ["file1.txt", "file2.txt", "file3.txt"])

        // Test non-recursive allFolders
        let folders = folder.allFolders()
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders.first?.name, "subfolder1")
        
        // Test recursive allFolders
        let allFoldersRecursive = folder.allFolders(recursive: true)
        XCTAssertEqual(allFoldersRecursive.count, 2)
        let allFolderNames = allFoldersRecursive.map { $0.name }.sorted()
        XCTAssertEqual(allFolderNames, ["subfolder1", "subfolder2"])
        
        // Clean up created files and folders
        try! file1.delete()
        try! file2.delete()
        try! file3.delete()
        try! subfolder1.delete()
    }

    func testHiddenFiles() {
        // Create hidden and non-hidden files and folders
        let file = try! folder.createFile(at: "file.txt")
        let hiddenFile = try! folder.createFile(at: ".hidden.txt")
        let subfolder = try! folder.createSubfolder(at: "sub")
        let hiddenSubfolder = try! folder.createSubfolder(at: ".hiddenSub")

        // Test that hidden files are excluded by default
        XCTAssertEqual(folder.allFiles().count, 1)
        XCTAssertEqual(folder.allFiles().first?.name, "file.txt")
        XCTAssertEqual(folder.allFolders().count, 1)
        XCTAssertEqual(folder.allFolders().first?.name, "sub")

        // Test that hidden files are included when requested
        XCTAssertEqual(folder.allFiles(includeHidden: true).count, 2)
        XCTAssertEqual(folder.allFolders(includeHidden: true).count, 2)

        // Test emptying the folder
        try! folder.empty()
        XCTAssertEqual(folder.allFiles(includeHidden: true).count, 1) // .hidden.txt should still be there
        XCTAssertEqual(folder.allFolders(includeHidden: true).count, 1) // .hiddenSub should still be there

        try! folder.empty(includingHidden: true)
        XCTAssertEqual(folder.allFiles(includeHidden: true).count, 0)
        XCTAssertEqual(folder.allFolders(includeHidden: true).count, 0)
        
        // Cleanup
        try? file.delete()
        try? hiddenFile.delete()
        try? subfolder.delete()
        try? hiddenSubfolder.delete()
    }

    func testFileExtensionParsing() {
        let file1 = try! folder.createFile(at: "test.txt")
        XCTAssertEqual(file1.extension, "txt")

        let file2 = try! folder.createFile(at: "archive.tar.gz")
        XCTAssertEqual(file2.extension, "gz")

        let file3 = try! folder.createFile(at: "noext")
        XCTAssertNil(file3.extension)

        let file4 = try! folder.createFile(at: ".hiddenfile")
        XCTAssertNil(file4.extension)

        let file5 = try! folder.createFile(at: "file.")
        XCTAssertEqual(file5.extension, "")

        // Clean up
        try! file1.delete()
        try! file2.delete()
        try! file3.delete()
        try! file4.delete()
        try! file5.delete()
    }

    func testXcodeprojExtension() {
        let file = try! folder.createFile(at: "MyApp.xcodeproj")
        XCTAssertEqual(file.extension, "xcodeproj")
        try! file.delete()
    }
    
    func testPathConcatenation() {
        // Basic path concatenation
        let path1 = Path("Desktop")
        let path2 = Path("AA")
        let combined = path1 + path2
        XCTAssertEqual(combined.rawValue, "Desktop/AA")
        
        // Multiple path concatenation
        let path3 = Path("Desktop") + Path("AA") + Path("BB")
        XCTAssertEqual(path3.rawValue, "Desktop/AA/BB")
        
        // Absolute path handling
        let absolutePath = Path("/Users")
        let relativePath = Path("Desktop")
        let combined2 = absolutePath + relativePath
        XCTAssertEqual(combined2.rawValue, "/Users/Desktop")
        
        // If rhs is absolute, it should override
        let combined3 = Path("Desktop") + Path("/Users")
        XCTAssertEqual(combined3.rawValue, "/Users")
        
        // Empty path handling
        let emptyPath = Path("")
        let result1 = emptyPath + Path("Desktop")
        XCTAssertEqual(result1.rawValue, "Desktop")
        
        let result2 = Path("Desktop") + emptyPath
        XCTAssertEqual(result2.rawValue, "Desktop")
    }
    
    func testPathProperties() {
        // Test lastComponent
        XCTAssertEqual(Path("Desktop/file.txt").lastComponent, "file.txt")
        XCTAssertEqual(Path("Desktop/AA").lastComponent, "AA")
        XCTAssertEqual(Path("/Users/john").lastComponent, "john")
        
        // Test extension
        XCTAssertEqual(Path("file.txt").extension, "txt")
        XCTAssertEqual(Path("Desktop/file.swift").extension, "swift")
        XCTAssertNil(Path("file").extension)
        XCTAssertNil(Path("Desktop/folder").extension)
        
        // Test stem
        XCTAssertEqual(Path("file.txt").stem, "file")
        XCTAssertEqual(Path("Desktop/file.swift").stem, "file")
        XCTAssertEqual(Path("file").stem, "file")
        
        // Test isAbsolute and isRelative
        XCTAssertTrue(Path("/Users").isAbsolute)
        XCTAssertFalse(Path("/Users").isRelative)
        XCTAssertFalse(Path("Desktop").isAbsolute)
        XCTAssertTrue(Path("Desktop").isRelative)
        
        // Test depth - be careful with pathComponent which may have edge cases
        let desktopPath = Path("Desktop")
        let components = desktopPath.pathComponent
        XCTAssertEqual(desktopPath.depth, components.count)
        
        let desktopAAPath = Path("Desktop/AA")
        XCTAssertEqual(desktopAAPath.depth, desktopAAPath.pathComponent.count)
        
        let desktopAABBPath = Path("Desktop/AA/BB")
        XCTAssertEqual(desktopAABBPath.depth, desktopAABBPath.pathComponent.count)
        
        // Test isEmpty
        XCTAssertTrue(Path("").isEmpty)
        XCTAssertTrue(Path(".").isEmpty)
        XCTAssertFalse(Path("Desktop").isEmpty)
    }
    
    func testPathManipulation() {
        // Test appending(String)
        let path1 = Path("Desktop").appending("AA")
        XCTAssertEqual(path1.rawValue, "Desktop/AA")
        
        // Test appending(Path)
        let path2 = Path("Desktop").appending(Path("AA"))
        XCTAssertEqual(path2.rawValue, "Desktop/AA")
        
        // Test removingLastComponent
        let path3 = Path("Desktop/AA/BB").removingLastComponent()
        XCTAssertEqual(path3.rawValue, "Desktop/AA")
        let path4 = Path("Desktop").removingLastComponent()
        XCTAssertEqual(path4.rawValue, ".")
        
        // Test replacingExtension
        let path5 = Path("file.txt").replacingExtension("swift")
        XCTAssertEqual(path5.rawValue, "file.swift")
        let path6 = Path("Desktop/file.txt").replacingExtension("md")
        XCTAssertEqual(path6.rawValue, "Desktop/file.md")
        let path7 = Path("file.txt").replacingExtension("")
        XCTAssertEqual(path7.rawValue, "file")
    }
    
    func testPathRelationships() {
        // Test isParent
        let parent = Path("/Users/john")
        let child = Path("/Users/john/Desktop")
        XCTAssertTrue(parent.isParent(of: child))
        XCTAssertFalse(child.isParent(of: parent))
        
        // Test isChild
        XCTAssertTrue(child.isChild(of: parent))
        XCTAssertFalse(parent.isChild(of: child))
        
        // Test commonPrefix
        let path1 = Path("/Users/john/Desktop")
        let path2 = Path("/Users/john/Documents")
        let common = path1.commonPrefix(with: path2)
        XCTAssertNotNil(common)
        XCTAssertEqual(common?.rawValue, "/Users/john")
        
        let path3 = Path("/Users/john/A")
        let path4 = Path("/Users/john/B")
        let common2 = path3.commonPrefix(with: path4)
        XCTAssertNotNil(common2)
        XCTAssertEqual(common2?.rawValue, "/Users/john")
    }
    
    func testRelativePath() {
        // Test relative path calculation
        let base = Path("/Users/john")
        let target = Path("/Users/john/Desktop")
        let relative = base.relative(to: target)
        XCTAssertNotNil(relative)
        XCTAssertEqual(relative?.rawValue, "Desktop")
        
        let base2 = Path("/Users/john/Desktop")
        let target2 = Path("/Users/john/Documents")
        let relative2 = base2.relative(to: target2)
        XCTAssertNotNil(relative2)
        XCTAssertEqual(relative2?.rawValue, "../Documents")
        
        // Same path should return "."
        let same = Path("/Users/john").relative(to: Path("/Users/john"))
        XCTAssertNotNil(same)
        XCTAssertEqual(same?.rawValue, ".")
    }
}
