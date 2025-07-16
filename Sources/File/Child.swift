import Foundation
import Logging

private let logger = Logger(label: "Child")

// MARK: - Child
public extension Folder {
    struct ChildSequence<Child: FileSystem> {
        let folder: Folder
        let fileManager: FileManager
        var recursive: Bool
        var includeStatus: Bool
    }

    struct ChildIterator<Child: FileSystem> {
        private let folder: Folder
        private let fileManager: FileManager
        private let recursive: Bool
        private let includeStatus: Bool
        private let reversingTopLevel: Bool
        private var index = 0
        private var itemIterators = [ChildIterator<Child>]()
        private lazy var itemNames = loadingItemNames()

        init(
            folder: Folder,
            fileManager: FileManager,
            recursive: Bool,
            includeStatus: Bool,
            reversingTopLevel: Bool
        ) {
            self.folder = folder
            self.fileManager = fileManager
            self.recursive = recursive
            self.includeStatus = includeStatus
            self.reversingTopLevel = reversingTopLevel
        }
    }
}

// MARK: - Child Sequence
extension Folder.ChildSequence: Sequence {
    public func makeIterator() -> Folder.ChildIterator<Child>  {
        return Folder.ChildIterator(
            folder: folder,
            fileManager: fileManager,
            recursive: recursive,
            includeStatus: includeStatus,
            reversingTopLevel: false
        )
    }
}

extension Folder.ChildSequence: CustomStringConvertible {
    public var description: String {
        return lazy.map({ $0.description }).joined(separator: "\n")
    }
}

public extension Folder.ChildSequence {
    var recursiveStatus: Folder.ChildSequence<Child> {
        var sequence = self
        sequence.recursive = true
        return sequence
    }
    var includingStatus: Folder.ChildSequence<Child> {
        var sequence = self
        sequence.includeStatus = true
        return sequence
    }
}

public extension Folder.ChildSequence {
    /// move all of the fileSystem with in this sequence
    func move(to folder: Folder) throws {
        try forEach { try $0.move(to: folder) }
    }

    /// delete all of the fileSystem with in this sequence
    func delete() throws {
        try forEach { try $0.delete() }
    }
}

// MARK: - Child Iterator
extension Folder.ChildIterator: IteratorProtocol {
    public mutating func next() -> Child? {
        guard index < itemNames.count else {
            guard var item = itemIterators.first else { return nil }
            guard let child = item.next() else {
                itemIterators.removeFirst()
                return next()
            }
            itemIterators[0] = item
            return child
        }
        let name = itemNames[index]
        index += 1

        if !includeStatus {
            guard !name.hasPrefix(".") else { return next() }
        }

        let childPath = folder.store.path.rawValue + name.removeSafePrefix("/")
        let childStore = try? Store<Child> (path: Path(childPath), fileManager: fileManager)
        let child = childStore as? Child
        
        if recursive {
            let childFolder = (child as? Folder) ?? (try? Folder(store: Store(path: Path(childPath), fileManager: fileManager)))
            
            if let childFolder = childFolder {
                let iteratorItem = Folder.ChildIterator<Child> (
                    folder: childFolder,
                    fileManager: fileManager,
                    recursive: true,
                    includeStatus: includeStatus,
                    reversingTopLevel: false
                )
                itemIterators.append(iteratorItem)
            }
        }

        return child ?? next()
    }

    fileprivate mutating func loadingItemNames() -> [String] {
        let contents = try? fileManager.contentsOfDirectory(atPath: folder.store.path.rawValue)
        let names = contents?.sorted() ?? []
        return reversingTopLevel ? names.reversed() : names
    }
}
