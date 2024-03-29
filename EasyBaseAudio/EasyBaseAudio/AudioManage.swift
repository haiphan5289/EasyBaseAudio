//
/////  ManageApp.swift
//  baominh_ios
//
//  Created by haiphan on 09/10/2021.
//

import Foundation
import AVFoundation
import CoreLocation
import UIKit
import MediaPlayer

public class AudioManage {
    
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
        
        public var nameImage: String {
            switch self {
            case .jpeg, .png, .jpg: return ""
            case .zip: return "ic_zip"
            case .video, .mp4, .mp3, .m4a, .wav, .m4r: return "ic_music"
            case .pdf: return "ic_pdf"
            case .txt: return "ic_text"
            }
        }
        
        public var value: String {
            return text.replacingOccurrences(of: ".", with: "")
        }
    }
    
    enum ErrorAsync: Error {
        case unknown
    }
    
    enum StatusApp {
        case bg, foreground
    }
    
    enum FileExport: String {
        case pdf, m4a
    }
    
    public static var shared = AudioManage()
    
    //    func createPdfFromView(aView: UIView, saveToDocumentsWithFileName fileName: String, name: String, completion: @escaping ( (String) -> Void )) {
    //        let pdfData = NSMutableData()
    //        UIGraphicsBeginPDFContextToData(pdfData, aView.bounds, nil)
    //        UIGraphicsBeginPDFPage()
    //
    //        guard let pdfContext = UIGraphicsGetCurrentContext() else { return }
    //
    //        aView.layer.render(in: pdfContext)
    //        UIGraphicsEndPDFContext()
    //        let linkPDF = self.createURL(folder: ConstantApp.shared.folderPDF, name: name, type: .pdf).absoluteString
    //        pdfData.write(toFile: linkPDF , atomically: true)
    //        completion(linkPDF)
    //    }
    
    public func createURL(folder: String, name: String, type: AudioType) -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentURL.appendingPathComponent("\(folder)/\(name)").appendingPathExtension(type.nameExport)
        return outputURL
    }
    
    public func saveAppleMusic(folder: String, mediaItem: MPMediaItem, success: @escaping ((URL) -> Void), failure: @escaping ((Error?) -> Void)) {
        //get media item first
        
        let songUrl = mediaItem.value(forProperty: MPMediaItemPropertyAssetURL) as! URL
        print(songUrl)
        
        // get file extension andmime type
        let str = songUrl.absoluteString
        let str2 = str.replacingOccurrences( of : "ipod-library://item/item", with: "")
        let arr = str2.components(separatedBy: "?")
        var mimeType = arr[0]
        mimeType = mimeType.replacingOccurrences( of : ".", with: "")
        
        let exportSession = AVAssetExportSession(asset: AVAsset(url: songUrl), presetName: AVAssetExportPresetAppleM4A)
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.outputFileType = AVFileType.m4a
        
        //save it into your local directory
        let outputURL = self.createURL(folder: "\(folder)", name: mediaItem.title ?? "", type: .m4a)
        //Delete Existing file
        do
            {
                try FileManager.default.removeItem(at: outputURL)
            }
        catch let error as NSError
        {
            print(error.debugDescription)
        }
        
        if let exportSession = exportSession {
            exportSession.outputURL = outputURL
            /// try to export the file and handle the status cases
            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .failed:
                    if let _error = exportSession.error {
                        failure(_error)
                    }
                    
                case .cancelled:
                    if let _error = exportSession.error {
                        failure(_error)
                    }
                default:
                    print("finished")
                    success(outputURL)
                }
            })
        } else {
            failure(nil)
        }
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
            return l
        } catch let err {
            print("\(err.localizedDescription)")
        }
        return []
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
    
    //MARK: DETECT FILE TYPE
    public func detectFile(url: URL) -> ImageType? {
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
    
    public func changeNameFile(folderName: String, oldURL: URL, newName: String, complention: ((URL) -> Void)?, failure: ((String) -> Void)?) {
        do {
            let createURL = self.createURL(folder: folderName, name: "\(newName)", type: .mp3)
            try FileManager.default.moveItem(at: oldURL, to: createURL)
            complention?(createURL)
        } catch {
            failure?(error.localizedDescription)
        }
    }
    
    public func changeName(old: String, new: String, failure: ((String) -> Void)?) {
        let listURL = self.getItemsFolder(folder: old)
        self.createFolder(path: new, success: { newURL in
            listURL.enumerated().forEach { item in
                do {
                    let createURL = self.createURL(folder: new, name: self.getNamefromURL(url: item.element), type: .m4a)
                    try FileManager.default.moveItem(at: item.element, to: createURL)
                } catch {
                    failure?(error.localizedDescription)
                }
            }
            self.removeFolder(name: old)
        }, failure: nil)
    }
    
    public func getUrlFolder(folder: String) -> URL {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return URL(fileURLWithPath: "")
        }
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let fodlerURL = appURL.appendingPathComponent(folder)
        return fodlerURL
    }
    
    public func getNamefromURL(url: URL) -> String {
        return url.deletingPathExtension().deletingPathExtension().lastPathComponent
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
    
    public func encodeVideo(folderName: String,
                            videoURL: URL,
                            success: @escaping ((URL) -> Void))  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)

        //Create Export session
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else { return }

        // exportSession = AVAssetExportSession(asset: composition, presetName: mp4Quality)
        //Creating temp path to save the converted video
        guard let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let filePath = documentsDirectory2.appendingPathComponent("\(folderName)/\(videoURL.getName()).mp4")
        deleteFile(filePath: filePath)

        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: filePath.absoluteString) {
            do {
                try FileManager.default.removeItem(atPath: filePath.absoluteString)
            }
            catch let error {
                print(error)
            }
        }

        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession.timeRange = range

        exportSession.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession.status {
            case .failed: break
            case .cancelled:
                print("Export canceled")
            case .completed:
                //Video conversion finished
                if let url = exportSession.outputURL {
                    success(url)
                }
            default:
                break
            }

        })


    }

    public func deleteFile(filePath:NSURL) {
        guard FileManager.default.fileExists(atPath: filePath.path!) else {
            return
        }

        do {
            try FileManager.default.removeItem(atPath: filePath.path!)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
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
                    if let index = contents.firstIndex(where: { $0 == url }) {
                        try? fileManager.removeItem(at: contents[index])
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
    
    public func removeFolder(name: String) {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let fileManager = FileManager.default
        let appURL = URL(fileURLWithPath: documentDirectoryPath)
        let pdfPath: URL = appURL.appendingPathComponent(name)
        
        do {
            try fileManager.removeItem(at: pdfPath)
        } catch let err {
            print("\(err.localizedDescription)")
        }
    }
    
    //MARK: COPY ITEM
    public func moveToItem(at srcURLs: [URL], folderName: String, complention: @escaping (() -> Void), failure: @escaping ((String) -> Void)) {
        var e: Error?
        srcURLs.forEach { srcURL in
            let dstURL = self.createURL(folder: folderName, name: "\(srcURL.getName()).\(srcURL.getDate())", type: .m4a)
            do {
                try FileManager.default.copyItem(at: srcURL, to: dstURL)
                try FileManager.default.removeItem(at: srcURL)
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
    
    public func secureCopyItem(at srcURL: URL, folderName: String, complention: @escaping (() -> Void), failure: @escaping ((String) -> Void)) {
        let dstURL = self.createURL(folder: folderName, name: "\(srcURL.getName()).\(Date().convertDateToLocalTime().timeIntervalSince1970)", type: .m4a)
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
    
    
    //MARK: Merge AUDIO
    public func cropVideo(sourceURL: URL,
                   rangeTimeSlider: RangeTimeSlider,
                   savePhotos: Bool = false,
                   folderName: String,
                   success: @escaping ((URL) -> Void), failure: @escaping ((Error) -> Void)) {
        let asset = AVAsset(url: sourceURL)
        let outputURL = self.createURL(folder: folderName, name: "CropVideo-\(self.parseDatetoString())", type: .mp4)
        removeFileAtURLIfExists(url: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        let timeRange = CMTimeRange(start: CMTime(seconds: rangeTimeSlider.start, preferredTimescale: 1),
                                    end: CMTime(seconds: rangeTimeSlider.end, preferredTimescale: 1))
        
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                success(outputURL)
            default:
                if let e = exportSession.error {
                    failure(e)
                }
            }
        }
    }
    
    public func trimAudio(sourceURL: URL,
                   rangeTimdeSlider: RangeTimeSlider,
                   folderName: String,
                   success: @escaping ((URL) -> Void), failure: @escaping ((Error?) -> Void)) {
                
        let asset = AVURLAsset(url: sourceURL)
        
        let composition = AVMutableComposition()
        
        //    let videoCompTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        //    let assetVideoTrack = asset.tracksWithMediaType(AVMediaType.video)[0]
        if let assetAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            var accumulatedTime = CMTime.zero
            let startTime = CMTime(seconds: rangeTimdeSlider.start, preferredTimescale: 1)
            let endTime = CMTime(seconds: (rangeTimdeSlider.end > 0 ? rangeTimdeSlider.end : sourceURL.getDuration()) , preferredTimescale: 1)
            let durationOfCurrentSlice = CMTimeSubtract(endTime, startTime)
            let timeRangeForCurrentSlice = CMTimeRangeMake(start: startTime, duration: durationOfCurrentSlice)
            
            do {
                //      try videoCompTrack.insertTimeRange(timeRangeForCurrentSlice, ofTrack: assetVideoTrack, atTime: accumulatedTime)
                try audioCompTrack?.insertTimeRange(timeRangeForCurrentSlice, of: assetAudioTrack, at: accumulatedTime)
            }
            catch let error {
                print("Error insert time range \(error)")
            }
            
            accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
            
            let outputURL = self.createURL(folder: folderName, name: "TrimAudio-\(self.parseDatetoString())", type: .mp4)
            removeFileAtURLIfExists(url: outputURL)
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    success(outputURL)
                default:
                    failure(exportSession.error)
                }
            }
        }
        
    }
    
    public func splitAudio(url: URL) {
        // Get the file as an AVAsset
        let asset: AVAsset = AVAsset(url: url)
        
        // Get the length of the audio file asset
        let duration = CMTimeGetSeconds(asset.duration)
        // Determine how many segments we want
        let numOfSegments = Int(ceil(duration / 300) - 1)
        // For each segment, we need to split it up
        for index in 0...numOfSegments {
            splitAudio(asset: asset, segment: index)
        }
    }
    
    public func splitAudio(asset: AVAsset, segment: Int) {
        // Create a new AVAssetExportSession
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
        // Set the output file type to m4a
        exporter.outputFileType = AVFileType.m4a
        // Create our time range for exporting
        let startTime = CMTimeMake(value: Int64(5 * 60 * segment), timescale: 1)
        let endTime = CMTimeMake(value: Int64(5 * 60 * (segment+1)), timescale: 1)
        // Set the time range for our export session
        exporter.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        // Set the output file path
        exporter.outputURL = URL(string: "file:///Users/campionfellin/Desktop/audio-\(segment).m4a")
        
        guard exporter.outputURL != nil else {
            return
        }
        // Do the actual exporting
        exporter.exportAsynchronously(completionHandler: {
            switch exporter.status {
            case AVAssetExportSession.Status.failed:
                print("Export failed.")
            default:
                print("Export complete.")
            //                    self.playAudio(url: outputURL)
            }
        })
        return
    }
    /// Merges video and sound while keeping sound of the video too
    ///
    /// - Parameters:
    ///   - videoUrl: URL to video file
    ///   - audioUrl: URL to audio file
    ///   - shouldFlipHorizontally: pass True if video was recorded using frontal camera otherwise pass False
    ///   - completion: completion of saving: error or url with final video
    public func mergeAudioIntoVideo(videoUrl: URL,
                             audioUrl: URL,
                             folderName: String,
                             success: @escaping ((URL) -> Void), failure: @escaping ((Error?) -> Void))
    {
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        
        //start merge
        
        let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset : AVAsset = AVAsset(url: audioUrl)
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        if aVideoAsset.tracks(withMediaType: AVMediaType.video).isEmpty {
            return
        }
        
        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        
        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aVideoAssetTrack, at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aAudioAssetTrack, at: CMTime.zero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            
        }catch{
            
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero,duration: aVideoAssetTrack.timeRange.duration )
        
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        //        mutableVideoComposition.renderSize = CGSize(width: 1280, height: 700)
        //find your video on this URl
        let numberOfTime = self.parseDatetoString()
        let savePathUrl = self.createURL(folder: folderName, name: "NewVideo - \(numberOfTime)", type: .mp4)
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            
            case AVAssetExportSession.Status.completed:
                
                //Uncomment this if u want to store your video in asset
                
                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
                UISaveVideoAtPathToSavedPhotosAlbum(savePathUrl.path,nil, nil, nil)
                success(savePathUrl)
            default:
                failure(assetExport.error)
            }
        }
    }
    
    public func removeFileAtURLIfExists(url: URL) {
        let filePath = url.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            do{
                try fileManager.removeItem(atPath: filePath)
            } catch let error as NSError {
                print("Couldn't remove existing destination file: \(error)")
            }
        }
    }
    
    public func trimmSound(inUrl:URL, index: Int, start: CGFloat, end: CGFloat, folderSplit: String, success:@escaping (URL) -> Void, failure:@escaping (String) -> Void) {
        let timeRange = CMTimeRange(start: CMTime(value: CMTimeValue(start), timescale: 1), end: CMTime(value: CMTimeValue(end), timescale: 1))
        let startTime = timeRange.start
        let duration = timeRange.duration
        let audioAsset = AVAsset(url: inUrl)
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        let sourceAudioTrack = audioAsset.tracks(withMediaType: AVMediaType.audio).first!
        do {
            try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration), of: sourceAudioTrack, at: .zero)
            
        } catch {
            failure(error.localizedDescription)
            return
        }
        if let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) {
            exporter.outputURL = self.createURL(folder: folderSplit,
                                                name: "\(inUrl.getName())-\(index).\(Date().convertDateToLocalTime().timeIntervalSince1970)",
                                                type: .m4a)
            exporter.outputFileType = AVFileType.m4a
            exporter.shouldOptimizeForNetworkUse = true
            exporter.exportAsynchronously {
                switch exporter.status {
                case AVAssetExportSession.Status.failed:
                    if let _error = exporter.error {
                        failure(_error.localizedDescription)
                    }
                default:
                    if let url = exporter.outputURL {
                        success(url)
                    }
                }
                
            }
        }
    }
    
    //MARK: SPLIT AUDIO
    public func splitAudio(url: URL, folderSplit: String) {
        // Get the file as an AVAsset
        let asset: AVAsset = AVAsset(url: url)
        
        // Get the length of the audio file asset
        let duration = CMTimeGetSeconds(asset.duration)
        // Determine how many segments we want
        let numOfSegments = Int(ceil(duration / 300) + 2)
        // For each segment, we need to split it up
        for index in 0...numOfSegments {
            splitAudio(asset: asset, segment: index, folderSplit: folderSplit)
        }
    }
    
    public func splitAudio(asset: AVAsset, segment: Int, folderSplit: String) {
        // Create a new AVAssetExportSession
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
        // Set the output file type to m4a
        exporter.outputFileType = AVFileType.m4a
        // Create our time range for exporting
        let startTime = CMTimeMake(value: Int64(5 * 60 * segment), timescale: 1)
        let endTime = CMTimeMake(value: Int64(5 * 60 * (segment+1)), timescale: 1)
        // Set the time range for our export session
        exporter.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        // Set the output file path
        exporter.outputURL = self.createURL(folder: folderSplit, name: "\(segment)", type: .m4a)
        
        guard let outputURL = exporter.outputURL else {
            return
        }
        // Do the actual exporting
        exporter.exportAsynchronously(completionHandler: {
            switch exporter.status {
                case AVAssetExportSession.Status.failed:
                    print("Export failed.")
                default:
                    print("Export complete.")
                    print("==== output \(outputURL)")
            }
        })
        return
    }
    
    public func converVideofromPhotoLibraryToMP4(videoURL: URL,
                                                 folderName: String,
                                                 completion: @escaping ((URL) -> Void))  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)
        guard let  exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            return
        }
//    let filePath = documentsDirectory2.URLByAppendingPathComponent("rendered-Video.mp4")
        let filePath = AudioManage.shared.createURL(folder: folderName, name: "\(videoURL.getName()) \(self.parseDatetoString())", type: .mp4)
        deleteFile(filePath: filePath)
        
        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession.timeRange = range

        exportSession.exportAsynchronously(completionHandler: {() -> Void in
        switch exportSession.status {
        case .failed:
            print()
        case .cancelled:
            print("Export canceled")
        case .completed:
            completion(exportSession.outputURL!)
        default:
            break
        }

    })


    }

    public func deleteFile(filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    //MARK: COVERT TO AUDIO
    public func covertToCAF(folderConvert: String, url: URL, type: AudioType, completion: @escaping((URL) -> Void), failure: @escaping ((String) -> Void)) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let name = url.deletingPathExtension().lastPathComponent
        let outputURL = URL(fileURLWithPath: documentsPath)
            .appendingPathComponent("\(folderConvert)/\(name)")
            .appendingPathExtension("\(self.parseDatetoString())")
            .appendingPathExtension("\(type.nameExport)")
        let ex = SongExporter.init(exportPath: outputURL.path)
        ex.exportSongWithURL(url) { url in
            completion(url)
        } failure: { text in
            failure(text)
        }
    }
    public func covertToAudio(url: URL,
                       folder: String,
                       type: AudioType,
                       success: @escaping((URL) -> Void), failure: @escaping((String) -> Void)) {
        let composition = AVMutableComposition()
        do {
            let asset = AVURLAsset(url: url)
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { fatalError("Không co URL") }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                          preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("Không co URL") }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
            //Fix folder to audio have full Sound
            var outputURL = self.createURL(folder: folder, name: "\(url.getName() ).\(url.getDate())", type: type)
            
            if url.getDate().isEmpty {
                outputURL = self.createURL(folder: folder, name: "\(url.getName())", type: type)
            }
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(atPath: outputURL.path)
            }
            
            // Create an export session
            if let exportSession = AVAssetExportSession(asset: composition, presetName: type.presentName) {
                exportSession.outputFileType = type.typeExport
                exportSession.outputURL = outputURL
                
                // Export file
                exportSession.exportAsynchronously {
                    guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
                    guard let outPut = exportSession.outputURL else { return }
                    switch exportSession.status {
                    case .failed:
                        if let _error = exportSession.error {
                            failure(_error.localizedDescription)
                        }
                        
                    case .cancelled:
                        if let _error = exportSession.error {
                            failure(_error.localizedDescription)
                        }
                        
                    default:
                        success(outPut)
                    }
                }
            } else {
                failure("Error")
            }
        } catch {
            print(error)
            failure(error.localizedDescription)
        }
    }
    
//    @available(iOS 15.0.0, *)
//    func covertToAudioAsync(url: URL,
//                       folder: String,
//                       type: ExportFileAV,
//                       eventExport: PublishSubject<AVAssetExportSession>? = nil) async -> URL? {
//        var outputURL1: URL?
//        let composition = AVMutableComposition()
//        do {
//            let asset = AVURLAsset(url: url)
//            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { fatalError("Không co URL") }
//            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio,
//                                                                          preferredTrackID: kCMPersistentTrackID_Invalid) else { fatalError("Không co URL") }
//            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
//        } catch {
//            print(error)
//        }
//
//        //Fix folder to audio have full Sound
//        let outputURL = self.createURL(folder: folder, name: "\(url.getName() ).\(url.getDate())", type: type)
//        if FileManager.default.fileExists(atPath: outputURL.path) {
//            try? FileManager.default.removeItem(atPath: outputURL.path)
//        }
//
//        // Create an export session
//        if let exportSession = AVAssetExportSession(asset: composition, presetName: type.presentName) {
//            exportSession.outputFileType = type.typeExport
//            exportSession.outputURL = outputURL
//
////            if eventExport != nil {
////                eventExport?.onNext(exportSession)
////            }
//
//            // Export file
//            guard case exportSession.status = AVAssetExportSession.Status.completed else { return nil }
//            guard let outPut = exportSession.outputURL else { return nil }
//            switch exportSession.status {
//            case .failed: break
////                    if let _error = exportSession.error {
////                        failure(_error.localizedDescription)
////                    }
//
//            case .cancelled: break
////                    if let _error = exportSession.error {
////                        failure(_error.localizedDescription)
////                    }
//
//            default:
//                outputURL1 = outPut
//            }
//        } else {
////            failure("Error")
//        }
//        return outputURL1
//    }
    
    
    //MARK: SETUP CORELOCATION
    
    public func getAddressFromGeocodeCoordinate(coordinate: CLLocationCoordinate2D, complention: @escaping ((String) -> Void) ) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo = CLGeocoder()
        center.latitude = coordinate.latitude
        center.longitude = coordinate.longitude
        
        let loc: CLLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        var addressString : String = ""
        ceo.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) in
            if (error != nil)
            {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            if let pm = placemarks {
                if pm.count > 0 {
                    let pm = placemarks![0]
                    print(pm.country ?? "")
                    print(pm.locality ?? "")
                    print(pm.subLocality ?? "")
                    print(pm.thoroughfare ?? "")
                    print(pm.postalCode ?? "")
                    print(pm.subThoroughfare ?? "")
                    
                    if pm.subThoroughfare != nil {
                        addressString = addressString + pm.subThoroughfare! + " "
                    }
                    
                    if pm.thoroughfare != nil {
                        addressString = addressString + pm.thoroughfare!
                    }
                    
                }
            }
            complention(addressString)
        })
         
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

public struct RangeTimeSlider {
    public let start: Float64
    public let end: Float64
    public init(start: Float64, end: Float64) {
        self.start = start
        self.end = end
    }
    
    public static let empty: RangeTimeSlider = RangeTimeSlider(start: 0, end: 0)
}
