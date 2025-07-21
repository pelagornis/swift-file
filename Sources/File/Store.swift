import Foundation
import Dispatch
import Logging

/// A common part of the File and Folder functionality that allows you to set up the required paths and FileManager that the file system should use.
public final class Store<fileSystem: FileSystem> {
    public var path: Path
    private let fileManager: FileManager

    init(path: Path, fileManager: FileManager) throws {
        self.path = path
        self.fileManager = fileManager
        try translatePath()
    }

    var attributes: [FileAttributeKey : Any] {
        return (try? fileManager.attributesOfItem(atPath: path.rawValue)) ?? [:]
    }
}

extension Store {
    /// Move FileSystem.
    func move(to newPath: Path) throws {
        do {
            try fileManager.moveItem(atPath: path.rawValue, toPath: newPath.rawValue)
            switch fileSystem.type {
            case .file:
                path.rawValue = newPath.rawValue
            case .folder:
                path.rawValue = newPath.rawValue.appendSafeSuffix("/")
            }
        } catch {
            throw FileError.moveError(path: path, error: error)
        }
    }

    /// Copy FileSystem.
    func copy(to newPath: Path) throws {
        do {
            try fileManager.copyItem(atPath: path.rawValue, toPath: newPath.rawValue)
        } catch {
            throw FileError.copyError(path: path, error: error)
        }
    }

    /// Delete FileSystem.
    func delete() throws {
        do {
            try fileManager.removeItem(atPath: path.rawValue)
        } catch {
            throw FileError.deleteError(path: path, error: error)
        }
    }

    /// Path translate.
    private func translatePath() throws {
        switch fileSystem.type {
        case .file:
            try storeFileEmpty()
        case .folder:
            try storeFolderEmpty()
        }

        if path.rawValue.hasPrefix("~") {
            let home = ProcessInfo.processInfo.environment["HOME"]!
            path.rawValue = home + path.rawValue.dropFirst()
        }

        while let parentRange = path.rawValue.range(of: "../") {
            let folderPath = path.rawValue[..<parentRange.lowerBound]
            let parentsPath = Path(String(folderPath)).parents
            try filesystemExists()

            path.rawValue.replaceSubrange(..<parentRange.upperBound, with: parentsPath.rawValue)
        }

        try filesystemExists()
    }

    /// Verify that the store file is empty.
    private func storeFileEmpty() throws {
        if path.rawValue.isEmpty {
            throw FileError.filePathEmpty(path: path)
        }
    }

    /// Verify that the store folder is empty.
    private func storeFolderEmpty() throws {
        if path.rawValue.isEmpty {
            path = Path(fileManager.currentDirectoryPath)
        }
        if !path.rawValue.hasSuffix("/") {
            path.rawValue += "/"
        }
    }

    /// File System Exists.
    private func filesystemExists() throws {
        var isFolder: ObjCBool = false
        var fileSystemStatus: Bool = false

        if !fileManager.fileExists(atPath: path.rawValue, isDirectory: &isFolder) {
            fileSystemStatus = false
        }

        switch fileSystem.type {
        case .file:
            fileSystemStatus = !isFolder.boolValue
        case .folder:
            fileSystemStatus = isFolder.boolValue
        }

        guard fileSystemStatus else {
            throw FileError.missing(path: path)
        }
    }
}

extension Store where fileSystem == Folder {
    /// Make Child Sequence.
    func makeChildSequence<T: FileSystem>() -> Folder.ChildSequence<T> {
        return Folder.ChildSequence(
            folder: Folder(store: self),
            fileManager: fileManager,
            recursive: false,
            includeStatus: false
        )
    }

    /// Subfolder information.
    func subfolder(at folderPath: Path) throws -> Folder {
        let folderPath = path.rawValue + folderPath.rawValue.removeSafePrefix("/")
        let store = try Store(path: Path(folderPath), fileManager: fileManager)
        return Folder(store: store)
    }

    /// File information
    func file(at filePath: Path) throws -> File {
        let filePath = path.rawValue + filePath.rawValue.removeSafePrefix("/")
        let store = try Store<File>(path: Path(filePath), fileManager: fileManager)
        return File(store: store)
    }

    /// Create subfolder to path.
    func createSubfolder(at folderPath: Path) throws -> Folder {
        let folderPath = path.rawValue + folderPath.rawValue.removeSafePrefix("/")
        if folderPath == path.rawValue { throw FileError.emptyPath(path: path) }
        do {
            try fileManager.createDirectory(
                atPath: folderPath,
                withIntermediateDirectories: true
            )
            let store = try Store(path: Path(folderPath), fileManager: fileManager)
            return Folder(store: store)
        } catch {
            throw FileError.folderCreateError(path: path, error: error)
        }
    }

    /// Create File to path.
    func createFile(at filePath: Path, contents: Data?) throws -> File {
        let filePath = path.rawValue + filePath.rawValue.removeSafePrefix("/")
        let parentPath = Path(filePath).parents.rawValue
        if parentPath != path.rawValue {
            do {
                try fileManager.createDirectory(
                    atPath: parentPath,
                    withIntermediateDirectories: true
                )
            } catch {
                throw FileError.folderCreateError(path: Path(parentPath), error: error)
            }
        }
        guard fileManager.createFile(atPath: filePath, contents: contents),
            let store = try? Store<File>(path: Path(filePath), fileManager: fileManager) else {
            throw FileError.fileCreateError(path: Path(filePath))
        }
        return File(store: store)
    }
}

// MARK: - Permission
public extension Store {
    /// Returns the file or folder permissions as a POSIX mode_t (Int).
    func getPermissions() -> Int? {
        let attributes = try? fileManager.attributesOfItem(atPath: path.rawValue)
        return attributes?[.posixPermissions] as? Int
    }

    /// Sets the file or folder permissions using a POSIX mode_t (Int).
    func setPermissions(_ permissions: Int) throws {
        do {
            try fileManager.setAttributes([.posixPermissions: permissions], ofItemAtPath: path.rawValue)
        } catch {
            throw FileError.writeFailed(path: path, error: error)
        }
    }
}

// MARK: - Symbolic Link
public extension Store {
    /// Checks if the path is a symbolic link.
    func isSymbolicLink() -> Bool {
        let attributes = try? fileManager.attributesOfItem(atPath: path.rawValue)
        let fileType = attributes?[.type] as? FileAttributeType
        return fileType == .typeSymbolicLink
    }

    /// Creates a symbolic link at this path pointing to the destination path.
    func createSymbolicLink(to destinationPath: Path) throws {
        do {
            try fileManager.createSymbolicLink(atPath: path.rawValue, withDestinationPath: destinationPath.rawValue)
        } catch {
            throw FileError.writeFailed(path: path, error: error)
        }
    }

    /// Returns the destination path of the symbolic link, if this is a symbolic link.
    func destinationOfSymbolicLink() -> Path? {
        do {
            let dest = try fileManager.destinationOfSymbolicLink(atPath: path.rawValue)
            return Path(dest)
        } catch {
            return nil
        }
    }
}

// MARK: - File/Folder Change Watch
public extension Store {
    /// Starts watching for changes to the file or folder at this path.
    /// - Parameters:
    ///   - eventHandler: Called when a change is detected.
    /// - Returns: A DispatchSourceFileSystemObject? (macOS, iOS), or nil if not supported. Uses swift-log for logging.
    @discardableResult
    func watch(eventHandler: @escaping () -> Void) -> Any? {
#if os(macOS) || os(iOS)
        let fd = open(path.rawValue, O_EVTONLY)
        guard fd != -1 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .all, queue: .main)
        source.setEventHandler(handler: eventHandler)
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        return source
#elseif os(Linux)
        // Linux: inotify-based implementation needed (not implemented here)
        let logger = Logger(label: "Store.Watch")
        logger.warning("Watch is not implemented for Linux in this version.")
        return nil
#else
        let logger = Logger(label: "Store.Watch")
        logger.warning("Watch is not supported on this platform.")
        return nil
#endif
    }
}
