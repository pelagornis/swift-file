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
}
