import Foundation
import Logging

private let logger = Logger(label: "FileError")

/// Error can be thrown by PLFile
public enum FileError: Error, Sendable {
    /// File Create Error
    case fileCreateError(path: Path)
    /// Verify that file path is empty.
    case filePathEmpty(path: Path)
    /// Folder Create Error
    case folderCreateError(path: Path, error: Error)
    /// Verify that path is empty.
    case emptyPath(path: Path)
    /// Write Failed Error.
    case writeFailed(path: Path, error: Error)
    /// Write String Encoding Error.
    case writeStringEncodingFailed(path: Path)
    /// Read Failed Error.
    case readFailed(path: Path, error: Error)
    /// Can Not Renamed Error.
    case cannotRename(path: Path)
    /// Move Failed Error
    case moveError(path: Path, error: Error)
    /// Copy Failed Error
    case copyError(path: Path, error: Error)
    /// Delete Failed Error
    case deleteError(path: Path, error: Error)
    /// Missing Error
    case missing(path: Path)
}

extension FileError {
    /// PLFile Error Return Error Context
    public var error: Error? {
        switch self {
        case .writeFailed(_, let error),
                .folderCreateError(_, let error),
                .readFailed(_, let error),
                .moveError(_, let error),
                .copyError(_, let error),
                .deleteError(_, let error):
            return error
        case .writeStringEncodingFailed,
                .fileCreateError,
                .cannotRename,
                .emptyPath,
                .filePathEmpty,
                .missing:
            return nil
        }
    }
    /// PLFile Error Reason Message
    public var message: String {
        switch self {
        case let .writeFailed(path, _):
            return "Could not write to file -> \(path)"
        case let .fileCreateError(path):
            return "Could not Create File -> \(path)"
        case let .filePathEmpty(path):
            return "File Path is Empty -> \(path)"
        case let .folderCreateError(path, _):
            return "Could not Create Folder -> \(path)"
        case let .writeStringEncodingFailed(path):
            return "Could not write String Encoding to file -> \(path)"
        case let .emptyPath(path):
            return "Could not write to empty path -> \(path)"
        case let .readFailed(path, _):
            return "Could not read to file -> \(path)"
        case let .moveError(path, _):
            return "Could not move to new path -> \(path)"
        case let .copyError(path, _):
            return "Could not copy to file -> \(path)"
        case let .deleteError(path, _):
            return "Could not delete to file -> \(path)"
        case let .cannotRename(path):
            return "Could not rename -> \(path)"
        case let .missing(path):
            return "Could not find missing -> \(path)"
        }
    }
}

// MARK: - CustomStringConvertible
extension FileError: CustomStringConvertible {
    /// Representation of `self`
    public var description: String {
        return String(describing: type(of: self)) + ": (\(message)"
    }
}

// MARK: - CustomDebugStringConvertible
extension FileError: CustomDebugStringConvertible {
    /// Representation of instance, suitable for debugging
    public var debugDescription: String {
        guard let error = error else {
            return self.description
        }
        return self.description + ":) \(error)"
    }
}
