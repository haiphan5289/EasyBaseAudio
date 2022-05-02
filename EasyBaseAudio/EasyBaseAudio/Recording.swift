//
//  Recording.swift
//  Audio Recorder
//
//  Created by Venkat Kukunuru on 30/12/16.
//  Copyright © 2016 Venkat Kukunuru. All rights reserved.
//
//

import Foundation
import AVFoundation
import QuartzCore

@objc public protocol RecorderDelegate: AVAudioRecorderDelegate {
    @objc optional func audioMeterDidUpdate(_ dB: Float)
}

open class Recording : NSObject {
    
    @objc public enum State: Int {
        case none, record, play
    }
    
    static var directory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    open weak var delegate: RecorderDelegate?
    open fileprivate(set) var url: URL
    open fileprivate(set) var state: State = .none
    
    open var bitRate = 192000
    open var sampleRate = 44100.0
    open var channels = 1
    
    fileprivate let session = AVAudioSession.sharedInstance()
    public var recorder: AVAudioRecorder?
    fileprivate var player: AVAudioPlayer?
    fileprivate var link: CADisplayLink?
    open var folderName: String = ""
    
    var metering: Bool {
        return delegate?.responds(to: #selector(RecorderDelegate.audioMeterDidUpdate(_:))) == true
    }
    
    // MARK: - Initializers
    
    public override init() {
        url = URL(fileURLWithPath: Recording.directory).appendingPathComponent("")
        super.init()
        
        self.createFolder()
        url = self.saveURL()
    }
    
    
    public init(folderName: String) {
        url = URL(fileURLWithPath: Recording.directory).appendingPathComponent("")
        super.init()
        self.folderName = folderName
        self.createFolder()
        url = self.saveURL()
    }
    
    // MARK: - Record
    
    open func prepare() throws {
        let settings: [String: AnyObject] = [
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatAppleLossless) as Int32),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue as AnyObject,
            AVEncoderBitRateKey: bitRate as AnyObject,
            AVNumberOfChannelsKey: channels as AnyObject,
            AVSampleRateKey: sampleRate as AnyObject
        ]
        
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.prepareToRecord()
        recorder?.delegate = delegate
        recorder?.isMeteringEnabled = metering
    }
    
    open func record() throws {
        if recorder == nil {
            try prepare()
        }
        
        try session.setCategory(AVAudioSession.Category.playAndRecord)
        try session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        
        recorder?.record()
        state = .record
        
        if metering {
            startMetering()
        }
    }
    
    // MARK: - Playback
    
    private func createFolder() {
        // path to documents directory
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let documentDirectoryPath = documentDirectoryPath {
            // create the custom folder path
            let imagesDirectoryPath = documentDirectoryPath.appending("/\(self.folderName)")
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: imagesDirectoryPath) {
                do {
                    try fileManager.createDirectory(atPath: imagesDirectoryPath,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
                } catch {
                    print("Error creating images folder in documents dir: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveURL() -> URL {
        guard let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return URL(fileURLWithPath: "")
        }
        let url = URL(fileURLWithPath: documentDirectoryPath)
        
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .second], from: date)

        let year =  components.year
        let month = components.month
        let day = components.day
        let second = components.second
        
        return url.appendingPathComponent("\(self.folderName)/Recording-\(year ?? 0 )\(month ?? 0)\(day ?? 0)\(second ?? 0).m4a")
    }
    
    open func play() throws {
        try session.setCategory(AVAudioSession.Category.playback)
        
        player = try AVAudioPlayer(contentsOf: url)
        print("======== \(url)")
        player?.play()
        state = .play
    }
    
    func pause() {
        recorder?.pause()
    }
    
    func continueRecord() {
        recorder?.record()
    }
    
    open func stop() {
        switch state {
        case .play:
            player?.stop()
            player = nil
        case .record:
            recorder?.stop()
            recorder = nil
            stopMetering()
        default:
            break
        }
        
        state = .none
    }
    
    // MARK: - Metering
    
    @objc func updateMeter() {
        guard let recorder = recorder else { return }
        
        recorder.updateMeters()
        
        let dB = recorder.averagePower(forChannel: 0)
        
        delegate?.audioMeterDidUpdate?(dB)
    }
    
    fileprivate func startMetering() {
        link = CADisplayLink(target: self, selector: #selector(Recording.updateMeter))
        link?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    fileprivate func stopMetering() {
        link?.invalidate()
        link = nil
    }
}
