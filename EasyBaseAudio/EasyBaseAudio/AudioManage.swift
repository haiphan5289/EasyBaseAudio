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


public class AudioManage {
    
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
    
    public func changeNameFile(folderName: String, oldURL: URL, newName: String, complention: ((URL) -> Void)?, failure: ((String) -> Void)?) {
        do {
            let createURL = self.createURL(folder: folderName, name: "\(newName).\(oldURL.getDate() )", type: .m4a)
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
    
    
    //MARK: TRIM AUDIO
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
            let outputURL = self.createURL(folder: folder, name: "\(url.getName() ).\(url.getDate())", type: type)
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
