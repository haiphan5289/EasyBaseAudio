//
//  EasyManageFiles.swift
//  EasyManageFiles
//
//  Created by haiphan on 31/07/2022.
//

import Foundation
import AVFoundation
import CoreLocation
import UIKit
import Zip

public protocol ManageAppDelegate: AnyObject {
    func pinHomes(pins: [FolderModel])
    func updateFirstApp(isFirst: Bool)
    func callAgain()
    func updateOrInsertConfig(folder: FolderModel)
    func deleteFolder(folder: FolderModel)
}

public struct FolderModel: Codable {
    public let imgName: String?
    public let url: URL
    public let id: Double
}

public struct SortModel {
    public let sort: ManageApp.Sort
    public let isAscending: Bool
    
    public static let valueDefault = SortModel(sort: .date, isAscending: false)
}

public class ManageApp {

    public enum Sort: Int, CaseIterable {
        case name, date, type, size
    }
    public enum ImageType: CaseIterable {
        case jpeg, png, jpg, zip, video, mp4, mp3, m4a, wav, m4r, pdf, txt
        
        public var text: String {
            switch self {
            case .jpeg: return ".jpeg"
            case .png: return ".png"
            case .jpg: return ".jpg"
            case .zip: return ".zip"
            case .video: return ".MOV"
            case .mp4: return ".mp4"
            case .mp3: return ".mp3"
            case .m4a: return ".m4a"
            case .wav: return ".wav"
            case .m4r: return ".m4r"
            case .pdf: return ".pdf"
            case .txt: return ".txt"
            }
        }
        
        public var value: String {
            return text.replacingOccurrences(of: ".", with: "")
        }
    }
    
    enum ErrorAsync: Error {
        case unknown
    }
    
    public enum PushNotificationKeys : String {
        case addedFolder = "addedFolder"
        case deleteFolder = "deleteFolder"

    }
    
    static var shared = ManageApp()
    public var delegate: ManageAppDelegate?
    public var folders: [FolderModel] = []
    public var foldersRoot: [FolderModel] = []
    public var files: [FolderModel] = []
    public var filesHome: [FolderModel] = []
    public var pinHomes: [FolderModel] = []
    private var folderStr: [String] = []
    public init() {
        //        self.removeAllRecording()
        self.start()    }
    
    private func start() {
        
    }
    
    public func setFolder(folderStr: [String]) {
        self.folderStr = folderStr
    }
    
    public func setupFolders(folders: [String]) {
        folders.forEach { folder in
            self.createFolder(path: folder, success: nil, failure: nil)
        }
    }
    
//    private func setupRX() {
//        let getList = Observable.just(RealmManager.shared.getFolders())
//        let updateList = NotificationCenter.default.rx.notification(NSNotification.Name(PushNotificationKeys.addedFolder.rawValue))
//            .map { _ in RealmManager.shared.getFolders() }
//        let deleteList = NotificationCenter.default.rx.notification(NSNotification.Name(PushNotificationKeys.deleteFolder.rawValue))
//            .map { _ in RealmManager.shared.getFolders() }
//        let refreshValue = self.refreshValue.map { _ in RealmManager.shared.getFolders() }
//        Observable.merge(getList, updateList, deleteList, refreshValue).bind { [weak self] list in
//            guard let wSelf = self else { return }
//            wSelf.$folders.accept(list)
//            var file: [FolderModel] = []
//            var filesHome: [FolderModel] = []
//            file += wSelf.getDirectory(filesStr: wSelf.folderStr)
//            filesHome += wSelf.getDirectory(filesStr: wSelf.folderStr)
//            wSelf.$foldersRoot.accept(wSelf.getFoldersRoot(filesStr: wSelf.folderStr))
//
//            list.forEach { folder in
//                let folderName: String = wSelf.detectPathFolder(url: folder.url)
//                let n = folderName.count
//                if folderName.index(folderName.startIndex, offsetBy: n, limitedBy: folderName.endIndex) != nil {
//                    let files = wSelf.getItemsFolder(folder: folderName).filter{ !$0.hasDirectoryPath }
//                        .map { url in
//                            return FolderModel(imgName: nil, url: url, id: Date().convertDateToLocalTime().timeIntervalSince1970)
//                        }
//                    filesHome += files
//                }
//            }
//            wSelf.$files.accept(file)
//            wSelf.$filesHome.accept(filesHome)
//        }.disposed(by: disposeBag)
//
//        self.$pinHomes.asObservable().bind { [weak self] list in
//            guard let self = self else { return }
//            self.delegate?.pinHomes(pins: list)
//        }.disposed(by: self.disposeBag)
//
//    }
    
    func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
            
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
            
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
    
    //MARK: SORT FOLDER MODEL
    public func sortDatasource(folders: [FolderModel], sort: SortModel) -> [FolderModel] {
        switch sort.sort {
        case .name:
            let list = folders.sorted { f1, f2 in
                if sort.isAscending {
                    return f1.url.getName() < f2.url.getName()
                }
                return f1.url.getName() > f2.url.getName()
            }
            return list
        case .type:
            let list = folders.sorted { f1, f2 in
                if sort.isAscending {
                    return (f1.url.getType() ?? "") < (f2.url.getType() ?? "")
                }
                return  (f1.url.getType() ?? "") > (f2.url.getType() ?? "")
            }
            return list
        case .date:
            let list = folders.sorted { f1, f2 in
                guard let date1 = f1.url.getCreateDate(), let date2 = f2.url.getCreateDate() else {
                    return false
                }
                if sort.isAscending {
                    return date1.compare(date2) == ComparisonResult.orderedAscending
                }
                return date1.compare(date2) == ComparisonResult.orderedDescending
            }
            return list
        case .size:
            let list = folders.sorted { f1, f2 in
                guard let size1 = f1.url.getSize(), let size2 = f2.url.getSize() else {
                    return false
                }
                if sort.isAscending {
                    return size1 < size2
                }
                return size1 > size2
            }
            return list
        }
    }
    
    //MARK: DEFAULT VALUE FOLDERS
    private func defaultValueFolders(isFirstApp: Bool, icons: [String], folders: [String]) {
        if isFirstApp {
            var l: [FolderModel] = []
            folders.enumerated().forEach { item in
                let offset = item.offset
                let f = FolderModel(imgName: icons[offset],
                                    url: self.getUrlFolder(folder: folders[offset]),
                                    id: Date().convertDateToLocalTime().timeIntervalSince1970)
                l.append(f)
            }
            self.pinHomes = l
            self.delegate?.updateFirstApp(isFirst: false)
//            let photos = FolderModel(imgName: "ic_photos_folder",
//                                     url: self.getUrlFolder(folder: ConstantApp.shared.folderPhotos),
//                                     id: Date().convertDateToLocalTime().timeIntervalSince1970)
//            RealmManager.shared.updateOrInsertConfig(model: photos)
//            let videos = FolderModel(imgName: "ic_video_folder",
//                                     url: self.getUrlFolder(folder: ConstantApp.shared.folderVideos),
//                                     id: Date().convertDateToLocalTime().timeIntervalSince1970)
//            RealmManager.shared.updateOrInsertConfig(model: videos)
//            let music = FolderModel(imgName: "ic_music_folder",
//                                    url: self.getUrlFolder(folder: ConstantApp.shared.folderMusics),
//                                    id: Date().convertDateToLocalTime().timeIntervalSince1970)
//            RealmManager.shared.updateOrInsertConfig(model: music)
//            let docs = FolderModel(imgName: "ic_doc_folder",
//                                   url: self.getUrlFolder(folder: ConstantApp.shared.folderDocuments),
//                                   id: Date().convertDateToLocalTime().timeIntervalSince1970)
//            RealmManager.shared.updateOrInsertConfig(model: docs)
//            let trash = FolderModel(imgName: "ic_trash_folder",
//                                    url: self.getUrlFolder(folder: ConstantApp.shared.folderTrashs),
//                                    id: Date().convertDateToLocalTime().timeIntervalSince1970)
//            RealmManager.shared.updateOrInsertConfig(model: trash)
//
//            self.pinHomes = [photos, videos, music, docs, trash]
//            self.dataDefault()
//            AppSettings.isFirstApp = false
        }
    }
    
    func dataDefault() {
        let sampleVideo = Bundle.main.url(forResource: "Sample Video", withExtension: "mp4")
        let sampleImage = Bundle.main.url(forResource: "Sample Image", withExtension: "jpg")
        let samplePdf = Bundle.main.url(forResource: "Sample PDF", withExtension: "pdf")
        let sampleMp3 = Bundle.main.url(forResource: "Sample Sound", withExtension: "mp3")
        let sampletxt = Bundle.main.url(forResource: "Sample Text File", withExtension: "txt")
        let urls: [URL] = [sampleVideo, sampleImage, samplePdf, sampleMp3, sampletxt].compactMap { $0 }
        
        Task.init {
            do {
                let result = try await ManageApp.shared.secureCopyItemstoFolder(at: urls, folderName: "", isId: false)
                switch result {
                case .success(_):
                    DispatchQueue.main.sync {
                        self.delegate?.callAgain()
                    }
                    
                case .failure(_): break
                }
            } catch _ {
            }
        }
    }
    
    
    
    public func getSpaceDisk() -> (Int64?, Int64?) {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard
            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber,
            let size = systemAttributes[.systemSize] as? NSNumber
        else {
            // something failed
            return (nil, nil)
        }
        return (freeSize.int64Value, size.int64Value)
    }
    
//    func saveImage(image: UIImage) {
//        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
//            return
//        }
//        let name = "\(Date().convertDateToLocalTime().timeIntervalSince1970)"
//        let directory = self.createURL(folder: "", name: name).appendingPathExtension(ImageType.png.value)
//        do {
//            try data.write(to: directory)
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
    
    //MARK: WRITE TEXT TO FIILE
    public func write(text: String, nameFile: String) async throws -> Result<URL, Error> {
//        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
//        guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent(folder) else { return }
//        try? FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)
//        let file = writePath.appendingPathComponent(fileNamed + ".txt")
//        try? text.write(to: file, atomically: false, encoding: String.Encoding.utf8)
        
        let file = self.createURL(folder: "", name: nameFile)
        do {
            try text.write(to: file, atomically: false, encoding: String.Encoding.utf8)
            return .success(file)
        } catch {
            return .failure(error)
        }
    }
    
    public func createFolderModeltoFiles(url: URL) {
        self.files.append(FolderModel(imgName: nil, url: url, id: Date().convertDateToLocalTime().timeIntervalSince1970))
    }
    
    public func createFoldertoRealm(url: URL, imgName: String) {
        let folder = FolderModel(imgName: imgName,
                                 url: url,
                                 id: Date().convertDateToLocalTime().timeIntervalSince1970)
        RealmManager.shared.updateOrInsertConfig(model: folder)
    }
    
    public func addPinFolder(folder: FolderModel) {
        self.pinHomes.append(folder)
    }
    
    //MARK: DEFAULT VALUE INAPP
//    func listRawSKProduct() -> [INAPPVC.SKProductModel] {
//        var list: [INAPPVC.SKProductModel] = []
//        let w = INAPPVC.SKProductModel(productID: .weekly, price: 0.99)
//        let m = INAPPVC.SKProductModel(productID: .monthly, price: 1.99)
//        let y = INAPPVC.SKProductModel(productID: .yearly, price: 9.99)
//        list.append(w)
//        list.append(m)
//        list.append(y)
//        return list
//    }
    
    func removeAllRecording() {
    }
    
    public func fetchImage(image: UIImage, folder: String) async throws -> Result<URL, Error> {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return .failure(ErrorAsync.unknown)
        }
        guard let dirc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return .failure(ErrorAsync.unknown)
        }
        let documentDirectoryPath = URL(fileURLWithPath: dirc)
        let photosPath = documentDirectoryPath.appendingPathComponent(folder)
            .appendingPathComponent("\(Date().convertDateToLocalTime().timeIntervalSince1970)")
            .appendingPathExtension("jpg")
        do {
            try data.write(to: photosPath)
            return .success(photosPath)
        } catch {
            return .failure(error)
        }
    }
    
    //MARK: DETECT FILE TYPE
    func detectFile(url: URL) -> ImageType? {
        var typeImage: ImageType?
        
        ImageType.allCases.forEach { type in
            if url.absoluteString.uppercased().contains( type.text.uppercased() ) {
                typeImage = type
            }
        }
        
        if let type = typeImage {
            return type
        }
        
        return nil
    }
    
    public func savePdf(data: Data, fileName: String) async throws -> Result<URL, Error> {
        let resourceDocPath = self.createURL(folder: "", name: fileName).appendingPathExtension(ImageType.pdf.value)
        do {
            try data.write(to: resourceDocPath, options: .atomic)
            return .success(resourceDocPath)
        } catch {
            return .failure(error)
        }
    }
    
    //MARK: SAVE IMAGE
    public func saveImage(image: UIImage, folder: String) {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return
        }
        guard let dirc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let documentDirectoryPath = URL(fileURLWithPath: dirc)
        let photosPath = documentDirectoryPath.appendingPathComponent(folder)
            .appendingPathComponent("\(Date().convertDateToLocalTime().timeIntervalSince1970)")
            .appendingPathExtension(ImageType.jpg.text)
        do {
            try data.write(to: photosPath)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    public func createURL(folder: String, name: String) -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        if folder.count <= 0 {
            return documentURL.appendingPathComponent("\(folder)\(name)")
        }
        
        let outputURL = documentURL.appendingPathComponent("\(folder)\(name)")
        return outputURL
    }
    
    public func getItemDefault() -> [URL] {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return []
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        do {
            let contentsEditAudio = try FileManager.default.contentsOfDirectory(at: appURL , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let list = contentsEditAudio
            
//            let l =  list.sorted { ( u1: URL, u2: URL) -> Bool in
//                do{
//                    let values1 = try u1.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
//                    let values2 = try u2.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
//                    if let date1 = values1.contentModificationDate, let date2 = values2.contentModificationDate {
//                        return date1.compare(date2) == ComparisonResult.orderedDescending
//                    }
//                }catch _{
//                }
//
//                return true
//            }
            return list
        } catch let err {
            print("\(err.localizedDescription)")
        }
        return []
    }
    
    public func getNameOrigin(string: String) -> String {
        let att = NSMutableAttributedString(string: string)
        let list = self.rangeTexts(source: att, searchText: "/")
        if list.count > 1 {
            return ""
        }
        let last = list.first
        let start = att.string.index(att.string.startIndex, offsetBy: 0)
        let end = att.string.index(att.string.startIndex, offsetBy: (last?.location ?? 0))
        let range = start..<end
        let updateString = String(att.string[range])
        return updateString
    }
    
    //MARK: CUT THE PREVIOUS FOLDER
    public func removePreviousFolder(url: URL) -> String {
        let att = NSMutableAttributedString(string: self.detectPathFolder(url: url))
        let list = self.rangeTexts(source: att, searchText: "/")
        let last = list.last
        let start = att.string.index(att.string.startIndex, offsetBy: 0)
        let end = att.string.index(att.string.startIndex, offsetBy: (last?.location ?? 0))
        let range = start..<end
        let updateString = String(att.string[range])
        
        let att2 = NSMutableAttributedString(string: updateString)
        let list2 = self.rangeTexts(source: att2, searchText: "/")
        let last2 = list2.last
        let start2 = att2.string.index(att2.string.startIndex, offsetBy: 0)
        let end2 = att2.string.index(att2.string.startIndex, offsetBy: (last2?.location ?? 0) + 1)
        let range2 = start2..<end2
        return (String(att2.string[range2]))
    }
    
    //MARK: CUT THE PREVIOUS FOLDER
    public func getNameFolderToCompress(url: URL) -> String {
        let att = NSMutableAttributedString(string: self.detectPathFolder(url: url))
        let list = self.rangeTexts(source: att, searchText: "/")
        if list.count <= 1 {
            return ""
        }
        let last = list.last
        let start = att.string.index(att.string.startIndex, offsetBy: 0)
        let end = att.string.index(att.string.startIndex, offsetBy: (last?.location ?? 0))
        let range = start..<end
        let updateString = String(att.string[range])
        
        let att2 = NSMutableAttributedString(string: updateString)
        let list2 = self.rangeTexts(source: att2, searchText: "/")
        let last2 = list2.last
        let start2 = att2.string.index(att2.string.startIndex, offsetBy: 0)
        let end2 = att2.string.index(att2.string.startIndex, offsetBy: (last2?.location ?? 0) + 1)
        let range2 = start2..<end2
        return (String(att2.string[range2]))
    }

    
    public func cutThePreviousFolder(url: URL) -> String {
        let att = NSMutableAttributedString(string: self.detectPathFolder(url: url))
        let list = self.rangeTexts(source: att, searchText: "/")
        let last = list.last
        let start = att.string.index(att.string.startIndex, offsetBy: 0)
        let end = att.string.index(att.string.startIndex, offsetBy: (last?.location ?? 0))
        let range = start..<end
        return String(att.string[range])
    }
    
    //MARK: GET URL FOLDER
    public func getUrlFolder(folder: String) -> URL {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return URL(fileURLWithPath: "")
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let fodlerURL = appURL.appendingPathComponent(folder)
        return fodlerURL
    }
    
    public func getfolders(url: URL, text: String) -> [URL] {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])

            let onlyFileNames = directoryContents.filter{ !$0.hasDirectoryPath }
            let _ = onlyFileNames.map { $0.lastPathComponent }

            let subdirs = directoryContents.filter{ $0.hasDirectoryPath }
                .filter{ !$0.absoluteString.contains(text) }
            let _ = subdirs.map{ $0.lastPathComponent }
            return self.convertToURLwithoutPrivate(list: subdirs)
            // now do whatever with the onlyFileNamesStr & subdirNamesStr
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return []
    }
    
    public func detectPathFileInFolder(url: URL) -> String {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return ""
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        if url.absoluteString.count < appURL.absoluteString.count {
            return ""
        }
        let att = NSMutableAttributedString(string: self.detectPathFolder(url: url))
        let list = self.rangeTexts(source: att, searchText: "/")
        let last = list.last
        let start = att.string.index(att.string.startIndex, offsetBy: 0)
        let end = att.string.index(att.string.startIndex, offsetBy: (last?.location ?? 0) + 1)
        let range = start..<end
        return String(att.string[range])
    }
    
    public func getDirectory(filesStr: [String]) -> [FolderModel] {
        var file: [FolderModel] = []
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return []
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let folderName: String = self.detectPathFolder(url: appURL)
        let n = folderName.count
        if folderName.index(folderName.startIndex, offsetBy: n, limitedBy: folderName.endIndex) != nil {
            let files = self.getItemsFolderFiles(folder: folderName)
                .filter{ !$0.hasDirectoryPath }
               
            var url = files
            filesStr.forEach { text in
                url = url.filter { !$0.absoluteString.contains(text) }
            }
            let f = url .map { url in
                return FolderModel(imgName: nil, url: url, id: Date().convertDateToLocalTime().timeIntervalSince1970)
            }
            file += f
        }
        return file
    }
    
    public func getFoldersRoot(filesStr: [String]) -> [FolderModel] {
        var file: [FolderModel] = []
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return []
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let folderName: String = self.detectPathFolder(url: appURL)
        let n = folderName.count
        if folderName.index(folderName.startIndex, offsetBy: n, limitedBy: folderName.endIndex) != nil {
            let files = self.getItemsFolder(folder: folderName)
                .filter{ $0.hasDirectoryPath }
            var url = files
            filesStr.forEach { text in
                url = url.filter { !$0.absoluteString.contains(text) }
            }
            let f = url .map { url in
                return FolderModel(imgName: nil, url: url, id: Date().convertDateToLocalTime().timeIntervalSince1970)
            }
            file += f
        }
        return file
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
    
    public func detectNumberofFolder(url: URL) -> Int {
        let att = NSMutableAttributedString(string: self.detectPathFolder(url: url))
        let list = self.rangeTexts(source: att, searchText: "/")
        //1 the first folder
        return list.count - 1
    }
    
    public func rangeTexts(source: NSMutableAttributedString, searchText: String) -> [NSRange] {
        do {
            let regEx = try NSRegularExpression(pattern: searchText, options: NSRegularExpression.Options.ignoreMetacharacters)
            
            let matchesRanges = regEx.matches(in: source.string, options: [], range: NSMakeRange(0, source.length))
            
            return matchesRanges.map { item -> NSRange in
                return item.range
            }
            
        } catch {
            print(error)
        }
        return []
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
    
    public func gettURL(folder: String) -> URL {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return URL.init(fileURLWithPath: "")
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        return appURL.appendingPathComponent(folder)
    }
    
    public func getItemsFolderFiles(folder: String) -> [URL] {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return []
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        var editAudioPath: URL
        
        if folder.count > 0 {
            editAudioPath = appURL.appendingPathComponent(folder)
        } else {
            editAudioPath = appURL
        }
        
        do {
            let contentsEditAudio = try FileManager.default.contentsOfDirectory(at: editAudioPath , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
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
    
    public func getItemsFolder(folder: String) -> [URL] {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return []
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let editAudioPath = appURL.appendingPathComponent(folder)
        do {
            let contentsEditAudio = try FileManager.default.contentsOfDirectory(at: editAudioPath , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
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
    
    public func getItemsFolderCloud(cloudURL: URL) -> [URL] {
        do {
            let contentsEditAudio = try FileManager.default.contentsOfDirectory(at: cloudURL , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
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
            return l
        } catch let err {
            print("\(err.localizedDescription)")
        }
        return []
    }
    
    public func changeNameFile(folderName: String, oldURL: URL, newName: String, complention: ((URL) -> Void)?, failure: ((String) -> Void)?) {
        do {
            let createURL = self.createURL(folder: folderName, name: "\(newName).\(oldURL.getDate() )")
            try FileManager.default.moveItem(at: oldURL, to: createURL)
            complention?(createURL)
        } catch {
            failure?(error.localizedDescription)
        }
    }
    
    public func onlyChangeFile(old: URL, new: String) async throws -> Result<URL, Error> {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return .failure(ErrorAsync.unknown)
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        
        do {
            
            let name: String
            
            switch self.detectFile(url: old) {
            case .none:
                name = "\(new).\(old.getType() ?? "")"
            default:
                name = "\(new)"
            }
            
            var destinationPath = appURL.appendingPathComponent("\(name)")
            
            if let imageType = self.detectFile(url: old) {
                destinationPath.appendPathExtension(imageType.value)
            }
            
            try FileManager.default.moveItem(at: old, to: destinationPath)
            return .success(destinationPath)
        } catch {
            return .failure(error)
        }
    }
    
    public func deletePinHome(url: URL) {
        if let index = self.pinHomes.firstIndex(where: { $0.url.getNamePath().uppercased().contains(url.getNamePath().uppercased()) }) {
            self.pinHomes.remove(at: index)
        }
    }
    
    public func changefile(old: String, new: String, failure: ((String) -> Void)?) {
        let oldPath = self.getUrlFolder(folder: old)
        self.createFolder(path: new) { outputURL in
            do {
                try FileManager.default.removeItem(at: oldPath)
                if let index = self.folders.firstIndex(where: { $0.url.getNamePath().uppercased().contains(oldPath.getNamePath().uppercased()) }) {
//                    RealmManager.shared.deleteFolder(model: ManageApp.shared.folders[index])
                    self.delegate?.deleteFolder(folder: self.folders[index])
                }
                if outputURL.hasDirectoryPath {
                    let folderModel = FolderModel(imgName: "ic_other_folder", url: outputURL, id: Double(Date().convertDateToLocalTime().timeIntervalSince1970))
                    RealmManager.shared.updateOrInsertConfig(model: folderModel)
                }
            } catch {
                failure?(error.localizedDescription)
            }
        } failure: { err in
            failure?(err)
        }
    }
    
    public func changeName(old: String, new: String, failure: ((String) -> Void)?) {
        let listURL = self.getItemsFolder(folder: old)
        self.createFolder(path: new, success: { newURL in
            listURL.enumerated().forEach { item in
                do {
                    let createURL = self.createURL(folder: new, name: self.getNamefromURL(url: item.element))
                    try FileManager.default.moveItem(at: item.element, to: createURL)
                } catch {
                    failure?(error.localizedDescription)
                }
            }
            self.removeFolder(name: old)
        }, failure: nil)
    }
    
    public func getNamefromURL(url: URL) -> String {
        return url.deletingPathExtension().deletingPathExtension().lastPathComponent
    }
    
    public func createInFolder(imagesDirectoryPath: String, success: ((URL) -> Void)?, failure: ((String) -> Void)?) {
        // path to documents directory
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: imagesDirectoryPath) {
            do {
                try fileManager.createDirectory(atPath: imagesDirectoryPath,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
                let appURL = URL(fileURLWithPath: imagesDirectoryPath)
                success?(appURL)
            } catch {
                print("Error creating images folder in documents dir: \(error.localizedDescription)")
                failure?(error.localizedDescription)
            }
        } else {
            failure?("Folder is exist")
        }
//        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
//        if let documentDirectoryPath = documentDirectoryPath {
            // create the custom folder path
//            let imagesDirectoryPath = documentDirectoryPath.appending("/\(path)")
//        }
    }
    
    public func createFolder(path: String, success: ((URL) -> Void)?, failure: ((String) -> Void)?) {
        // path to documents directory
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let documentDirectoryPath = documentDirectoryPath {
            // create the custom folder path
            let imagesDirectoryPath = documentDirectoryPath.appending("/\(path)")
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: imagesDirectoryPath) {
                do {
                    try fileManager.createDirectory(atPath: imagesDirectoryPath,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
                    let appURL = URL(fileURLWithPath: imagesDirectoryPath)
                    success?(appURL)
                } catch {
                    print("Error creating images folder in documents dir: \(error.localizedDescription)")
                    failure?(error.localizedDescription)
                }
            } else {
                failure?("Folder is exist")
            }
        }
    }
    
    //MARK: ZIP ITEMS
    public func unZipItems(sourceURL: URL, folderName: String, folders: [String], failure: (String) -> Void?) {
        var listName: [String] = []
        let destination = self.createURL(folder: folderName, name: "/")
        do {
            _ = try Zip.unzipFile(sourceURL, destination: destination, overwrite: true, password: nil, progress: nil, fileOutputHandler: { unzippedFile in
                let name = self.getNameFolderToCompress(url: unzippedFile)
                
                listName.append(name)
            })
            if let index = listName.firstIndex(where: { $0.uppercased().contains("__MACOSX".uppercased()) }) {
                self.removeFolder(name: listName[index])
                listName.remove(at: index)
            }
            if let last = listName.last {
                var removeText = last
                if last.count > 0 {
                    removeText.removeLast()
                } else {
                    self.delegate?.callAgain()
                    return
                }
                
                var isFolderExist: Bool = false
                
                folders.forEach { text in
                    if text.uppercased() == removeText.uppercased() {
                        isFolderExist = true
                    }
                }
                
                if !isFolderExist {
                    let folder = FolderModel(imgName: "ic_other_folder",
                                             url: self.createURL(folder: "", name: last),
                                             id: Date().convertDateToLocalTime().timeIntervalSince1970)
                    RealmManager.shared.updateOrInsertConfig(model: folder)
                }
            }
        }
        catch {
          failure("Folder is empty")
        }
    }
    
    public func zipItems(sourceURL: [URL], nameZip: String) {
        do {
            _ = try Zip.quickZipFiles(sourceURL, fileName: nameZip) // Zip
        }
        catch {
          print("Something went wrong")
        }
    }
    
    //MARK: REMOVE FILES
    public func removeFilesFolder(name: String) {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let fileManager = FileManager.default
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let pdfPath: URL = appURL.appendingPathComponent(name)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: pdfPath , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for item in contents {
                try fileManager.removeItem(at: item)
            }
        } catch let err {
            print("\(err.localizedDescription)")
        }
    }
    
    public func removeFileAtHome(url: URL) {
        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: url)
        } catch _ {
            
        }
    }
    
    public func removeFilesinFolder(name: String, listIndex: [URL]) {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let fileManager = FileManager.default
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let pdfPath: URL = appURL.appendingPathComponent(name)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: pdfPath , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for _ in contents.enumerated() {
                listIndex.forEach { url in
                    if let index = contents.firstIndex(where: { $0.absoluteString.uppercased().contains((url.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.uppercased() ?? "")) }) {
                        try? fileManager.removeItem(at: contents[index])
                    }
                    self.deletePinHome(url: url)
                    if url.hasDirectoryPath, let index = ManageApp.shared.folders.firstIndex(where: { $0.url.getNamePath().uppercased().contains(url.getNamePath().uppercased())}) {
                        RealmManager.shared.deleteFolder(model: ManageApp.shared.folders[index])
                    }
                    if url.hasDirectoryPath, let index = ManageApp.shared.folders.firstIndex(where: { $0.url.getNamePathPlus().uppercased().contains(url.getNamePath().uppercased())}) {
                        RealmManager.shared.deleteFolder(model: ManageApp.shared.folders[index])
                    }
                }
            }
        } catch let err {
            print("\(err.localizedDescription)")
        }
    }
    
    public func removeFilesFolder(folderName: String) {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let fileManager = FileManager.default
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let pdfPath: URL = appURL.appendingPathComponent(folderName)
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: pdfPath , includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for filePath in contents {
                try fileManager.removeItem(at: filePath)
            }
        } catch let err {
            print("\(err.localizedDescription)")
        }
    }
    
//    func removeRecordingHomeModel(items: [RecordingHomeModel]) {
//        items.forEach { item in
//            self.removeFolder(name: item.title)
//        }
//        RealmManager.shared.deleteRecording(listRecord: items)
//    }
    
    public func removeFolderAllfiles(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        } catch let err {
            print("\(err.localizedDescription)")
        }
    }
    
    public func removeFolder(name: String) {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let fileManager = FileManager.default
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let pdfPath: URL = appURL.appendingPathComponent(name)
        
        do {
            try fileManager.removeItem(at: pdfPath)
            if let index = ManageApp.shared.folders.firstIndex(where: { $0.url.getNamePath().uppercased().contains(pdfPath.getNamePath().uppercased()) }) {
                RealmManager.shared.deleteFolder(model: ManageApp.shared.folders[index])
            }
            self.deletePinHome(url: pdfPath)
        } catch let err {
            print("\(err.localizedDescription)")
        }
    }
    
    //MARK: Copy Item from iCloud
    public func covertToCAF(url: URL, completion: @escaping((URL) -> Void)) {
//        self.createFolder(path: ConstantApp.shared.convertFolder, success: nil, failure: nil)
//
//        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
//        let outputURL = URL(string: documentsPath).appendingPathComponent("\(ConstantApp.shared.convertFolder)/\(url.getName())\(url.getType() ?? "")")
//        let ex = SongExporter.init(exportPath: outputURL.path)
//        ex.exportSongWithURL(url) { outputURL in
//            print(outputURL)
//        } failure: { string in
//            print(string)
//        }

    }
    
    //MARK: DUPLICATE ITEMS
    public func duplicateItemHome(folderName: String, at srcURL: URL) async throws -> Result<URL, Error> {
        var  dstURL = self.createURL(folder: folderName, name: "\(Int(Date().convertDateToLocalTime().timeIntervalSince1970))\(srcURL.getName())")
        if let imageType = self.detectFile(url: srcURL) {
            dstURL.appendPathExtension(imageType.value)
        }
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            return .success(dstURL)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    public func duplicateItem(folderName: String, at srcURL: URL) async throws -> Result<URL, Error> {
        
        let name: String
        
        switch self.detectFile(url: srcURL) {
        case .none:
            name =  "\(Int(Date().convertDateToLocalTime().timeIntervalSince1970))\(srcURL.getName())" + ".\(srcURL.getType() ?? "")"
        default:
            name = "\(Int(Date().convertDateToLocalTime().timeIntervalSince1970))\(srcURL.getName())"
        }
        
        
        var  dstURL = self.createURL(folder: folderName, name: "\(name)")
        if let imageType = self.detectFile(url: srcURL) {
            dstURL.appendPathExtension(imageType.value)
        }
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            return .success(dstURL)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    //MARK: COPY ITEM
    
    public func moveToItemText(at srcURLs: [URL], folderName: String, complention: @escaping (() -> Void), failure: @escaping ((String) -> Void)) {
        var e: Error?
        srcURLs.forEach { srcURL in
            
            var dstURL = self.createURL(folder: folderName, name: "\(srcURL.getName()).\(srcURL.getType() ?? "")")
            
            if let imagetype = self.detectFile(url: srcURL) {
                dstURL.appendPathExtension(imagetype.value)
            }
            
            do {
                try FileManager.default.copyItem(at: srcURL, to: dstURL)
                if srcURL.hasDirectoryPath {
                    let folder = FolderModel(imgName: "ic_other_folder", url: dstURL, id: Double(Date().convertDateToLocalTime().timeIntervalSince1970))
                    RealmManager.shared.updateOrInsertConfig(model: folder)
                }
                try FileManager.default.removeItem(at: srcURL)
                if srcURL.hasDirectoryPath, let index = ManageApp.shared.folders.firstIndex(where: { $0.url.getNamePath().uppercased().contains(srcURL.getNamePath().uppercased())}) {
                    RealmManager.shared.deleteFolder(model: ManageApp.shared.folders[index])
                }
            } catch (let error) {
                e = error
            }
        }
        if let e = e {
            failure(e.localizedDescription)
        } else {
            complention()
        }
        
    }
    
    
    public  func moveToItem(at srcURLs: [URL], folderName: String, complention: @escaping (() -> Void), failure: @escaping ((String) -> Void)) {
        var e: Error?
        srcURLs.forEach { srcURL in
            
            let name: String
            
            switch self.detectFile(url: srcURL) {
            case .none:
                name = "\(srcURL.getName()).\(srcURL.getType() ?? "")"
            default:
                name = "\(srcURL.getName())"
            }
            
            var dstURL = self.createURL(folder: folderName, name: "\(name)")
            
            if let imagetype = self.detectFile(url: srcURL) {
                dstURL.appendPathExtension(imagetype.value)
            }
            
            do {
                try FileManager.default.copyItem(at: srcURL, to: dstURL)
                if srcURL.hasDirectoryPath {
                    let folder = FolderModel(imgName: "ic_other_folder", url: dstURL, id: Double(Date().convertDateToLocalTime().timeIntervalSince1970))
                    RealmManager.shared.updateOrInsertConfig(model: folder)
                }
                try FileManager.default.removeItem(at: srcURL)
                if srcURL.hasDirectoryPath, let index = ManageApp.shared.folders.firstIndex(where: { $0.url.getNamePath().uppercased().contains(srcURL.getNamePath().uppercased())}) {
                    RealmManager.shared.deleteFolder(model: ManageApp.shared.folders[index])
                }
            } catch (let error) {
                e = error
            }
        }
        if let e = e {
            failure(e.localizedDescription)
        } else {
            complention()
        }
        
    }
    
    public func secureCopyItemstoFolder(at srcURLs: [URL], folderName: String, isId: Bool = true) async throws -> Result<Void, Error> {
        var e: Error?
        srcURLs.forEach { srcURL in
            if srcURL.hasDirectoryPath {
                let id = Int(Date().convertDateToLocalTime().timeIntervalSince1970)
                
                let name: String
                
                switch self.detectFile(url: srcURL) {
                case .none:
                    if isId {
                        name = "\(srcURL.getName())\(id).\(srcURL.getType() ?? "")"
                    } else {
                        name = "\(srcURL.getName()).\(srcURL.getType() ?? "")"
                    }
                    
                default:
                    if isId {
                        name = "\(srcURL.lastPathComponent)\(id)"
                    } else {
                        name = "\(srcURL.lastPathComponent)"
                    }
                    
                }
                
                let dstURL = self.createURL(folder: folderName, name: "\(name)" )
                do {
                    try FileManager.default.copyItem(at: srcURL, to: dstURL)
                    if srcURL.hasDirectoryPath {
                        let folder = FolderModel(imgName: "ic_other_folder", url: dstURL, id: Double(Date().convertDateToLocalTime().timeIntervalSince1970))
                        RealmManager.shared.updateOrInsertConfig(model: folder)
                    }
                } catch (let error) {
                   e = error
                }
            } else {
                let id = Int(Date().convertDateToLocalTime().timeIntervalSince1970)
                let name: String
                if isId {
                    name = "\(id)\(srcURL.lastPathComponent)"
                } else {
                    name = "\(srcURL.lastPathComponent)"
                }
                
                let dstURL = self.createURL(folder: folderName, name: "\(name)")
                do {
                    try FileManager.default.copyItem(at: srcURL, to: dstURL)
                } catch (let error) {
                   e = error
                }
            }
        }
        if let e = e {
            return .failure(e)
        } else {
            return .success(())
        }
    }
    
    public func secureCopyItemfromiCloud(at srcURL: URL, folderName: String) async throws -> Result<URL, Error> {
        let id = Int(Date().convertDateToLocalTime().timeIntervalSince1970)
        
        let name: String
        
        switch self.detectFile(url: srcURL) {
        case .none:
            name = "\(id)\(srcURL.getName())\(id).\(srcURL.getType() ?? "")"
        default:
            name = "\(id)\(srcURL.lastPathComponent)"
        }
        
        let dstURL = self.createURL(folder: folderName, name: "\(name)")
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            return .success(dstURL)
        } catch (let error) {
            print("==== \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    public func secureCopyItemtoFolder(at srcURL: URL, folderName: String) async throws -> Result<URL, Error> {
        let id = Int(Date().convertDateToLocalTime().timeIntervalSince1970)
        let dstURL = self.createURL(folder: folderName, name: "\(srcURL.lastPathComponent)\(id)")
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            return .success(dstURL)
        } catch (let error) {
            return .failure(error)
        }
    }

    
    public func secureCopyItemfromLibrary(at srcURL: URL, folderName: String, complention: @escaping ((URL) -> Void), failure: @escaping ((String) -> Void)) {
        let dstURL = self.createURL(folder: folderName, name: "\(srcURL.lastPathComponent)")
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            complention(dstURL)
        } catch (let error) {
            failure(error.localizedDescription)
        }
    }
    
    public func secureCopyItem(at srcURL: URL, folderName: String, complention: @escaping (() -> Void), failure: @escaping ((String) -> Void)) {
        let dstURL = self.createURL(folder: folderName, name: "\(srcURL.getName()).\(Date().convertDateToLocalTime().timeIntervalSince1970)")
        do {
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            complention()
        } catch (let error) {
            failure(error.localizedDescription)
        }
    }
    
    //MARK: Save to Camera Roll
    public func saveToCameraRoll(savePathUrl: URL) {
        //let assetsLib = ALAssetsLibrary()
        //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
        UISaveVideoAtPathToSavedPhotosAlbum(savePathUrl.path,nil, nil, nil)
    }
    
    //MARK: SHOW ACTIVITIES
    public func showActivies(urls: [URL], viewcontroller: UIViewController, complention: (() -> Void)?) {
        let objectsToShare: [URL] = urls
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.airDrop, .addToReadingList, .assignToContact,
                                            .mail, .message, .postToFacebook]
        activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
//            if !completed {
//                return
//            }
            activityVC.dismiss(animated: true) {
                complention?()
            }
        }
        viewcontroller.present(activityVC, animated: true, completion: nil)
        
    }
    
    //MARK: SHOW ACTIVITIES
    public func showActiviesString(urls: [String], viewcontroller: UIViewController, complention: (() -> Void)?) {
        let objectsToShare: [String] = urls
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.airDrop, .addToReadingList, .assignToContact,
                                            .mail, .message, .postToFacebook]
        activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
//            if !completed {
//                return
//            }
            activityVC.dismiss(animated: true) {
                complention?()
            }
        }
        viewcontroller.present(activityVC, animated: true, completion: nil)
        
    }
    
    //MARK: COVERT TO AUDIO
    public func covertToCAF(url: URL, type: ExportFileAV, folder: String, completion: @escaping((URL) -> Void), failure: @escaping ((String) -> Void)) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let name = url.deletingPathExtension().lastPathComponent
        let outputURL = URL(fileURLWithPath: documentsPath)
            .appendingPathComponent("\(folder)/\(name)")
            .appendingPathExtension("\(ManageApp.shared.parseDatetoString())")
            .appendingPathExtension("\(type.nameExport)")
        let ex = SongExporter.init(exportPath: outputURL.path)
        ex.exportSongWithURL(url) { url in
            completion(url)
        } failure: { text in
            failure(text)
        }
    }
    
    public func parseDatetoString() -> String {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .second, .hour], from: date)

        let year =  components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let h = components.hour ?? 0
        let second = components.second ?? 0
        return "\(year)\(month)\(day)\(h)\(second)"
    }
    
    public func openLink(link: String) {
        if let url = URL(string:link), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(URL(string:link)!)
        }
    }
    
    //MARK: OPEN SETTINGS
    public func openSettingApps() {
        if UIApplication.shared.canOpenURL(URL(string:UIApplication.openSettingsURLString)!) {
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        }
    }
    
}

public enum ExportFileAV: Int, CaseIterable {
    case mp3, m4a, wav, m4r, caf, aiff, aifc, aac, flac, mp4
    
    public var typeExport: AVFileType {
        switch self {
        case .m4a:
            return .m4a
        case .caf:
            return .caf
        default:
            return .mp4
        }
    }
    
    public var nameExport: String {
        switch self {
        case .m4a:
            return "m4a"
        case .m4r:
            return "m4r"
        case .wav:
            return "wav"
        case .caf:
            return "caf"
        case .aiff:
            return "aiff"
        case .aifc:
            return "aifc"
        case .flac:
            return "flac"
        default:
            return "mp4"
        }
    }
    
    public  var presentName: String {
        switch self {
        case .m4a:
            return AVAssetExportPresetAppleM4A
        case .caf:
            return AVAssetExportPresetPassthrough
        default:
            return AVAssetExportPresetHighestQuality
            
        }
    }
    
    //Export 9
    public var defaultExport: String {
        return ".m4a"
    }
    
    var nameUrl: String {
        return "\(self)"
    }
}

public class DiskStatus {

    //MARK: Formatter MB only
    public class func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }


    //MARK: Get String Value
    public class var totalDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }

    public class var freeDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }

    public class var usedDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }


    //MARK: Get raw value
    public class var totalDiskSpaceInBytes:Int64 {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
                return space!
            } catch {
                return 0
            }
        }
    }

    public class var freeDiskSpaceInBytes:Int64 {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
                return freeSpace!
            } catch {
                return 0
            }
        }
    }

    public class var usedDiskSpaceInBytes:Int64 {
        get {
            let usedSpace = totalDiskSpaceInBytes - freeDiskSpaceInBytes
            return usedSpace
        }
    }

}
