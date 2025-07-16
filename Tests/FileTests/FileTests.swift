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
}
