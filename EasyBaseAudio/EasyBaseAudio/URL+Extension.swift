//
//  URL+Extension.swift
//  Audio
//
//  Created by paxcreation on 4/12/21.
//

import Foundation
import UIKit
import MediaPlayer

extension URL {
    public func getNameAudio() -> String {
//        let lastPath = self.lastPathComponent
//        let endIndex = lastPath.index(lastPath.endIndex, offsetBy: -4)
//        let name = String(lastPath.prefix(upTo: endIndex))
        return self.deletingPathExtension().lastPathComponent
    }
    
    public func getThumbnailImage() -> UIImage? {
        let asset: AVAsset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }

        return nil
    }
    
    public func getDuration() -> Double {
        let asset = AVURLAsset(url: self)
        let durationInSeconds = asset.duration.seconds
        return durationInSeconds
    }
    
    public func getName() -> String {
        return self.deletingPathExtension().deletingPathExtension().lastPathComponent
    }
    
    public func getDate() -> String {
        return self.deletingPathExtension().pathExtension
    }
    
    public func getType() -> String? {
        return self.pathExtension
    }
    
    public func removeType() -> String {
        return self.deletingPathExtension().lastPathComponent
    }
    
    public func getSize() -> Double? {
        let filePath = self.path
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                let value = size.doubleValue / 1000000.0
                return Double(round(1000 * value) / 1000)
            }
        } catch {
            print("Error: \(error)")
        }
        return nil
    }
    
    public func detectPathFolder(url: URL) -> String {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return ""
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        if url.absoluteString.count < appURL.absoluteString.count {
            return ""
        }
        var string: String = "file:/"
        url.pathComponents.enumerated().forEach { text in
            let offSet = text.offset
            let element = text.element
            if offSet <= 5 && element == "private" {
                
            } else {
                string += element + "/"
            }
        }
        let start = string.index(string.startIndex, offsetBy: appURL.absoluteString.count)
        let end = string.index(string.endIndex, offsetBy: 0)
        let range = start..<end
        return String(string[range])
    }
    
    public func gettURL(folder: String) -> URL {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return URL.init(fileURLWithPath: "")
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        return appURL.appendingPathComponent(folder)
    }
    
    
    public func timeAgo() -> String? {
        guard let d = self.creation else {
            return nil
        }
        return d.getElapsedInterval()
    }
    
    public func parseURLSystem() -> URL {
        let nameFolder = self.detectPathFolder(url: self)
        let url = self.gettURL(folder: nameFolder)
        return url
    }
    
    public func getCreateDate() -> Date? {
        do {
            let resources = try self.parseURLSystem().resourceValues(forKeys: [.creationDateKey])
            return resources.creationDate
        } catch {
            print(error)
        }
        return nil
    }
    public func getModifyDate() -> Date? {
        do {
            let resources = try self.parseURLSystem().resourceValues(forKeys: [.contentModificationDateKey])
            return resources.contentModificationDate
        } catch {
            print(error)
        }
        return nil
    }
    
    public func getSubURL() -> String {
        let create = self.getCreateDate()?.covertToString(format: .HHmmddMMyyyy)
        var getSize: String = ""
        
        do {
            if let size = try self.parseURLSystem().sizeOnDisk() {
                getSize = size
            }
        } catch {}
        
        return "\(create ?? "") • \(getSize)"
    }
    
    private func convertToURLwithoutPrivate(list: [URL]) -> [URL] {
        var exportURL: [URL] = []
        list.forEach { url in
            var string: String = "file:/"
            url.pathComponents.enumerated().forEach { text in
                let offSet = text.offset
                let element = text.element
                if offSet <= 5 && element == "private" {
                    
                } else if offSet >= url.pathComponents.count - 1 && !url.hasDirectoryPath {
                    string += element
                } else {
                    string += element + "/"
                }
            }
            let final = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: final) {
                exportURL.append(url)
            }
        }
        return exportURL
    }
    
    public func getItemsFolders(folder: URL) -> [URL] {
        do {
            let contentsEditAudio = try FileManager.default.contentsOfDirectory(at: folder , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let list = contentsEditAudio
            
            let l =  list.sorted { ( u1: URL, u2: URL) -> Bool in
                do{
                    let values1 = try u1.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                    let values2 = try u2.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                    if let date1 = values1.contentModificationDate, let date2 = values2.contentModificationDate {
                        return date1.compare(date2) == ComparisonResult.orderedDescending
                    }
                }catch _{
                }
                
                return true
            }
            return self.convertToURLwithoutPrivate(list: l)
        } catch let err {
            print("\(err.localizedDescription)")
        }
        return []
    }
    
    public func getURLFolderNew() -> String {
        let url = self.parseURLSystem()
        let create = url.getCreateDate()?.covertToString(format: .HHmmddMMyyyy)
        let list = self.getItemsFolders(folder: url)
        let total = list.map { $0.getSize() }.compactMap { $0 }.reduce(0, { partialResult, value in partialResult + value }).rounded(toPlaces: 2)
        return "\(create ?? "") • \(total)MB"
    }
    
    public func getURLFolder() -> String {
        let url = self.parseURLSystem()
        let create = url.getCreateDate()?.covertToString(format: .HHmmddMMyyyy)
        let getSize = self.getSize()
        return "\(create ?? "") • \(getSize ?? 0)MB"
    }
    
    public func getNamePath() -> String {
        return self.detectPathFolder(url: self)
    }
    
    public func getNamePathPlus() -> String {
        return self.detectPathFolder(url: self) + "/"
    }
}

extension URL {
    /// The time at which the resource was created.
    /// This key corresponds to an Date value, or nil if the volume doesn't support creation dates.
    /// A resource’s creationDateKey value should be less than or equal to the resource’s contentModificationDateKey and contentAccessDateKey values. Otherwise, the file system may change the creationDateKey to the lesser of those values.
    public var creation: Date? {
        get {
            return (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.creationDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
    /// The time at which the resource was most recently modified.
    /// This key corresponds to an Date value, or nil if the volume doesn't support modification dates.
    public var contentModification: Date? {
        get {
            return (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.contentModificationDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
    /// The time at which the resource was most recently accessed.
    /// This key corresponds to an Date value, or nil if the volume doesn't support access dates.
    ///  When you set the contentAccessDateKey for a resource, also set contentModificationDateKey in the same call to the setResourceValues(_:) method. Otherwise, the file system may set the contentAccessDateKey value to the current contentModificationDateKey value.
    public var contentAccess: Date? {
        get {
            return (try? resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
        }
        // Beginning in macOS 10.13, iOS 11, watchOS 4, tvOS 11, and later, contentAccessDateKey is read-write. Attempts to set a value for this file resource property on earlier systems are ignored.
        set {
            var resourceValues = URLResourceValues()
            resourceValues.contentAccessDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
}
extension URL {
    /// check if the URL is a directory and if it is reachable
    public func isDirectoryAndReachable() throws -> Bool {
        guard try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            return false
        }
        return try checkResourceIsReachable()
    }

    /// returns total allocated size of a the directory including its subFolders or not
    public func directoryTotalAllocatedSize(includingSubfolders: Bool = false) throws -> Int? {
        guard try isDirectoryAndReachable() else { return nil }
        if includingSubfolders {
            guard
                let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return nil }
            return try urls.lazy.reduce(0) {
                    (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil).lazy.reduce(0) {
                 (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                    .totalFileAllocatedSize ?? 0) + $0
        }
    }

    /// returns the directory total size on disk
    public func sizeOnDisk() throws -> String? {
        guard let size = try directoryTotalAllocatedSize(includingSubfolders: true) else { return nil }
        URL.byteCountFormatter.countStyle = .file
        guard let byteCount = URL.byteCountFormatter.string(for: size) else { return nil}
        return byteCount
    }
    private static let byteCountFormatter = ByteCountFormatter()
    
    
}
