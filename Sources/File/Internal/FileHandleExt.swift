import Foundation

extension FileHandle {

    /// Seeks to the end of the file handle.
    ///
    /// - Returns: The current offset from the beginning of the file.
    ///
    /// - Note: Uses the modern `seekToEnd()` method for Swift 6.0 compatibility.
    @available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.2, visionOS 1.0, *)
    func seekToEndFactory() -> UInt64 {
        do {
            return try self.seekToEnd()
        } catch {
            return 0
        }
    }
    
    ///  Writes the given data to the file handle.
    ///
    /// - Parameter data: The data to write.
    ///
    /// - Note: Uses the modern `write(contentsOf:)` method for Swift 6.0 compatibility.
    @available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.2, visionOS 1.0, *)
    func writeFactory(_ data: Data) {
        do {
            try self.write(contentsOf: data)
        } catch {
            return
        }
    }
    
    /// Closes the file handle.
    ///
    /// - Note: Uses the modern `close()` method for Swift 6.0 compatibility.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, *)
    func closeFileFactory() {
        do {
            try self.close()
        } catch { 
            return 
        }
    }
}
