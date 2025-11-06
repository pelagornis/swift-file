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

    /// Last path component (file name or folder name).
    /// - Example: `Path("Desktop/file.txt").lastComponent` returns `"file.txt"`
    public var lastComponent: String {
        return (rawValue as NSString).lastPathComponent
    }

    /// File extension without the leading dot.
    /// - Example: `Path("file.txt").extension` returns `"txt"`
    public var `extension`: String? {
        let ext = (rawValue as NSString).pathExtension
        return ext.isEmpty ? nil : ext
    }

    /// File name without extension (stem).
    /// - Example: `Path("file.txt").stem` returns `"file"`
    public var stem: String {
        return (lastComponent as NSString).deletingPathExtension
    }

    /// Whether this path is absolute (starts with `/`).
    public var isAbsolute: Bool {
        return rawValue.hasPrefix("/")
    }

    /// Whether this path is relative (does not start with `/`).
    public var isRelative: Bool {
        return !isAbsolute
    }

    /// Depth of the path (number of components).
    /// - Example: `Path("Desktop/AA/BB").depth` returns `3`
    public var depth: Int {
        return pathComponent.count
    }

    /// Whether the path is empty or represents the current directory.
    public var isEmpty: Bool {
        return rawValue.isEmpty || rawValue == "."
    }

    /// Resolving path '..'.
    fileprivate func safeComponents(_ component: [Path]) -> [Path] {
        var result = false
        let count = component.count
        let safecomponent: [Path] = component.enumerated().compactMap { index, path in
            // Check if current is not ".." and next is ".."
            if path.rawValue != ".." && index < count - 1 && component[index + 1].rawValue == ".." {
                result = true
                return nil
            }
            // Check if current is ".." and previous is not ".."
            if path.rawValue == ".." && index > 0 && component[index - 1].rawValue != ".." {
                result = true
                return nil
            }
            return path
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

// MARK: - Path Concatenation
extension Path {
    /// Concatenates two paths using the `/` separator.
    /// - Parameters:
    ///   - lhs: The left-hand side path.
    ///   - rhs: The right-hand side path.
    /// - Returns: A new path combining both paths.
    /// - Example: `Path("Desktop") + Path("AA")` returns `Path("Desktop/AA")`
    public static func + (lhs: Path, rhs: Path) -> Path {
        // If rhs is an absolute path, return it directly
        if rhs.rawValue.hasPrefix("/") {
            return rhs
        }
        
        // If lhs is empty, return rhs
        if lhs.rawValue.isEmpty || lhs.rawValue == "." {
            return rhs
        }
        
        // If rhs is empty, return lhs
        if rhs.rawValue.isEmpty || rhs.rawValue == "." {
            return lhs
        }
        
        // Use NSString's appendingPathComponent for proper path joining
        let combined = (lhs.rawValue as NSString).appendingPathComponent(rhs.rawValue)
        return Path(combined)
    }

    /// Appends a path component to this path.
    /// - Parameter component: The path component to append.
    /// - Returns: A new path with the component appended.
    /// - Example: `Path("Desktop").appending("AA")` returns `Path("Desktop/AA")`
    public func appending(_ component: String) -> Path {
        return self + Path(component)
    }

    /// Appends a path to this path.
    /// - Parameter path: The path to append.
    /// - Returns: A new path with the path appended.
    /// - Example: `Path("Desktop").appending(Path("AA"))` returns `Path("Desktop/AA")`
    public func appending(_ path: Path) -> Path {
        return self + path
    }

    /// Removes the last path component.
    /// - Returns: A new path with the last component removed.
    /// - Example: `Path("Desktop/AA").removingLastComponent()` returns `Path("Desktop")`
    public func removingLastComponent() -> Path {
        let result = (rawValue as NSString).deletingLastPathComponent
        // If result is empty, return "."
        return result.isEmpty ? Path(".") : Path(result)
    }

    /// Replaces the file extension with a new one.
    /// - Parameter newExtension: The new extension (without leading dot).
    /// - Returns: A new path with the extension replaced.
    /// - Example: `Path("file.txt").replacingExtension("swift")` returns `Path("file.swift")`
    public func replacingExtension(_ newExtension: String) -> Path {
        let withoutExt = (rawValue as NSString).deletingPathExtension
        if newExtension.isEmpty {
            return Path(withoutExt)
        }
        return Path(withoutExt + "." + newExtension)
    }

    /// Returns a relative path from this path to another path.
    /// - Parameter other: The target path.
    /// - Returns: A relative path from this path to the other path, or nil if no relative path exists.
    /// - Example: `Path("/Users/john").relative(to: Path("/Users/john/Desktop"))` returns `Path("Desktop")`
    public func relative(to other: Path) -> Path? {
        let selfAbs = self.absolutePath.standardized
        let otherAbs = other.absolutePath.standardized
        
        let selfComponents = selfAbs.pathComponent
        let otherComponents = otherAbs.pathComponent
        
        // Find common prefix
        var commonLength = 0
        let minLength = min(selfComponents.count, otherComponents.count)
        for i in 0..<minLength {
            if selfComponents[i].rawValue == otherComponents[i].rawValue {
                commonLength += 1
            } else {
                break
            }
        }
        
        // Build relative path
        var relativeComponents: [String] = []
        
        // Go up from self to common ancestor
        for _ in commonLength..<selfComponents.count {
            relativeComponents.append("..")
        }
        
        // Go down from common ancestor to other
        for i in commonLength..<otherComponents.count {
            relativeComponents.append(otherComponents[i].rawValue)
        }
        
        if relativeComponents.isEmpty {
            return Path(".")
        }
        
        return Path(relativeComponents.joined(separator: "/"))
    }

    /// Checks if this path is a parent of another path.
    /// - Parameter other: The path to check.
    /// - Returns: `true` if this path is a parent of the other path.
    /// - Example: `Path("/Users").isParent(of: Path("/Users/john"))` returns `true`
    public func isParent(of other: Path) -> Bool {
        let selfAbs = self.absolutePath.standardized
        let otherAbs = other.absolutePath.standardized
        
        let selfStr = selfAbs.rawValue
        let otherStr = otherAbs.rawValue
        
        // Ensure self ends with / for proper comparison
        let normalizedSelf = selfStr.hasSuffix("/") ? selfStr : selfStr + "/"
        
        return otherStr.hasPrefix(normalizedSelf) && otherStr != normalizedSelf
    }

    /// Checks if this path is a child of another path.
    /// - Parameter other: The path to check.
    /// - Returns: `true` if this path is a child of the other path.
    /// - Example: `Path("/Users/john").isChild(of: Path("/Users"))` returns `true`
    public func isChild(of other: Path) -> Bool {
        return other.isParent(of: self)
    }

    /// Returns the common prefix path shared with another path.
    /// - Parameter other: The other path.
    /// - Returns: The common prefix path, or nil if no common prefix exists.
    /// - Example: `Path("/Users/john/A").commonPrefix(with: Path("/Users/john/B"))` returns `Path("/Users/john")`
    public func commonPrefix(with other: Path) -> Path? {
        let selfAbs = self.absolutePath.standardized
        let otherAbs = other.absolutePath.standardized
        
        let selfComponents = selfAbs.pathComponent
        let otherComponents = otherAbs.pathComponent
        
        var commonComponents: [Path] = []
        let minLength = min(selfComponents.count, otherComponents.count)
        
        for i in 0..<minLength {
            if selfComponents[i].rawValue == otherComponents[i].rawValue {
                commonComponents.append(selfComponents[i])
            } else {
                break
            }
        }
        
        guard !commonComponents.isEmpty else {
            return nil
        }
        
        var result = commonComponents[0]
        for i in 1..<commonComponents.count {
            result = result + commonComponents[i]
        }
        
        return result
    }
}
