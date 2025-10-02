import Foundation
import Logging
private let logger = Logger(label: "Path")

/// Manage the path of the PLFile.
public struct Path: Sendable {
    /// Root path.
    public static let root = Path("/")

    /// Home path.
    public static var home: Path {
        return Path(NSHomeDirectory())
    }
    
    /// System Temporary path.
    public static var temporary: Path {
        return Path(NSTemporaryDirectory())
    }

    /// Documents path.
    public static var documents: Path {
        return search(.documentDirectory)
    }

    /// Library path.
    public static var library: Path {
        return search(.libraryDirectory)
    }

    /// user's temporary directory path.
    public static var userTemporary: Path {
        return Path(NSTemporaryDirectory()).standardized
    }

    /// Standardized path
    public var standardized: Path {
        return Path((self.rawValue as NSString).standardizingPath)
    }

    /// Resolving all symlinks path.
    public var resolved: Path {
        return Path((self.rawValue as NSString).resolvingSymlinksInPath)
    }

    /// Absolute path.
    public var absolutePath: Path {
        if rawValue.hasPrefix("/") {
            return self.standardized
        } else {
            return Path(Path.current.rawValue + self.rawValue).standardized
        }
    }

    /// Parent path.
    public var parents: Path {
        if rawValue.hasPrefix("/") {
            return Path((absolutePath.rawValue as NSString).deletingLastPathComponent)
        } else {
            let component = pathComponent
            if component.isEmpty {
                return Path("..")
            } else if component.last?.rawValue == ".." {
                return Path(".." + self[component.count - 1].rawValue)
            } else if pathComponent.count == 1 {
                return Path("")
            } else {
                return self[component.count - 2]
            }
        }
    }

    /// Path component.
    public var pathComponent: [Path] {
        if rawValue.isEmpty || rawValue == "." { return .init() }
        if rawValue.hasPrefix("/") {
            return (absolutePath.rawValue as NSString).pathComponents.enumerated().compactMap {
                (($0 == 0 || $1 != "/") && $1 != ".") ? Path($1) : nil
            }
        } else {
            let component = (self.rawValue as NSString).pathComponents.enumerated()
            let safeComponent = component.compactMap {
                (($0 == 0 || $1 != "/") && $1 != ".") ? Path($1) : nil
            }
            return safeComponents(safeComponent)
        }
    }

    /// Current path
    public static var current: Path {
        get {
            return Path(FileManager.default.currentDirectoryPath)
        } set {
            FileManager.default.changeCurrentDirectoryPath(newValue.safeRawValue)
        }
    }

    /// Stored Path String value.
    public var rawValue: String

    /// Safe Raw Value with path.
    var safeRawValue: String {
        return rawValue.isEmpty ? "." : rawValue
    }

    /// Standardized path string value
    public var standardRawValue: String {
        return (self.rawValue as NSString).standardizingPath
    }

    /// Resolving path '..'.
    fileprivate func safeComponents(_ component: [Path]) -> [Path] {
        var result = false
        let count = component.count
        let safecomponent: [Path] = component.enumerated().compactMap {
            if ($1.rawValue != ".." && component[$0 + 1].rawValue == ".." && $0 < count - 1) ||
                ($1.rawValue == ".." && component[$0 - 1].rawValue != ".." && $0 > 0) {
                result = true
                return nil
            } else {
                return $1
            }
        }
        return result ? safeComponents(safecomponent) : safecomponent
    }

    /// Initalizer.
    public init() {
        self = .root
    }

    /// Initalizer with swift path.
    public init(_ path: String, expandingTilde: Bool = false, _ fileManager: FileManager = .default) {
        if expandingTilde {
            self.rawValue = (path as NSString).expandingTildeInPath
        } else {
            self.rawValue = path
        }
    }

    private static func search(
        _ searchPath: FileManager.SearchPathDirectory,
        domain: FileManager.SearchPathDomainMask = .userDomainMask,
        fileManage: FileManager = .default
    ) -> Path {
        let url = fileManage.urls(for: searchPath, in: domain)
        guard let path = url.first else {
            return Path()
        }
        return Path(path.relativePath)
    }
}

extension Path: RawRepresentable {
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Path: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

extension Path: CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return "Path(\(rawValue.debugDescription))"
    }
}

// MARK: - subscript
extension Path {
    /// A subscript that identifies the position of the path.
    public subscript(_ position: Int) -> Path {
        let component = pathComponent
        guard position >= 0 && position < component.count else {
            fatalError("Path index out of range")
        }
        guard let first = component.first else {
            fatalError("Path component is empty")
        }
        var result = first
        for index in 1...position {
            result = Path(result.rawValue + component[index].rawValue)
        }
        return result
    }
    /// A subscript that identifies the bound out of the path.
    public subscript(_ bounds: Range<Int>) -> Path {
        let component = self.pathComponent
        guard bounds.lowerBound >= 0 && bounds.upperBound <= component.count && bounds.lowerBound < bounds.upperBound else {
            fatalError("Path bounds out of range")
        }
        var result = component[bounds.lowerBound]
        for index in (bounds.lowerBound + 1)..<bounds.upperBound {
            result = Path(result.rawValue + component[index].rawValue)
        }
        return result
    }
}

// MARK: - Hashable
extension Path: Hashable {
    /// To compute the hash value of the path
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
