import Foundation
import Logging

private let logger = Logger(label: "File")

/// File functionality in PLFile
public struct File: FileSystem {
    public var store: Store<File>

    public init(store: Store<File>) {
        self.store = store
    }
}

// MARK: - Property
extension File {
    /// PLFile File Type
    public static var type: FileType {
        return .file
    }
}

// MARK: - Function
public extension File {
    /// write binary data in the file and replace current contexts
    func write(_ data: Data) throws {
        do {
            try data.write(to: url)
        } catch {
            throw FileError.writeFailed(path: store.path, error: error)
        }
    }

    /// write new string into the file and replace current contexts.
    func write(_ string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw FileError.writeStringEncodingFailed(path: store.path)
        }
        return try write(data)
    }

    /// append binary data in the file, exist contexts
    func append(_ data: Data) throws {
        do {
            let handler = try FileHandle(forWritingTo: url)
            _ = handler.seekToEndFactory()
            handler.writeFactory(data)
            handler.closeFileFactory()
        } catch {
            throw FileError.writeFailed(path: store.path, error: error)
        }
    }

    /// append string into the file, exist contexts
    func append(_ string: String, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw FileError.writeStringEncodingFailed(path: store.path)
        }
        return try append(data)
    }

    /// read the contents binary data in the file
    func read() throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw FileError.readFailed(path: store.path, error: error)
        }
    }
}

// MARK: - Existence
public extension File {
    /// Checks if the file actually exists in the file system.
    func exists() -> Bool {
        return FileManager.default.fileExists(atPath: store.path.rawValue)
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public extension File {
    /// open file
    func open() {
        NSWorkspace.shared.open(URL(fileURLWithPath: store.path.rawValue))
    }
}
#endif
