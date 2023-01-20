//
//  AudioEfffect.swift
//  EqualizerEffect
//
//  Created by haiphan on 4/16/21.
//  Copyright © 2021 한승진. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

@available(iOS 11.0, *)
public final class AudioEffect {
    
    var songLengthSamples: AVAudioFramePosition!
    var sampleRateSong: Float = 0
    var lengthSongSeconds: Float = 0
    var startInSongSeconds: Float = 0
    var listAVAudioNode: [AVAudioNode] = []
    var currentTimeNode: TimeInterval = 0
    fileprivate var EQNode: AVAudioUnitEQ?
    
    let frequencies: [Int] = [32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    var preSets: [[Float]] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // My setting
        [4, 6, 5, 0, 1, 3, 5, 4.5, 3.5, 0], // Dance
        [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3], // Jazz
        [5, 4, 3.5, 3, 1, 0, 0, 0, 0, 0] // Base Main
    ]
    
    //: ## Engine Setup
    //:    player -> reverb -> mainMixer -> output
    //: ### Create and configure the engine and its nodes
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let reverb = AVAudioUnitReverb()
    let speedControl = AVAudioUnitVarispeed()
    let pitchControl = AVAudioUnitTimePitch()
    let distortion = AVAudioUnitDistortion()
    let deplay = AVAudioUnitDelay()
    let lowShelf = AVAudioUnitEQ(numberOfBands: 1)
    let highShelf = AVAudioUnitEQ(numberOfBands: 1)
    var folderName: String = ""
    
    public init() {
        
    }
    
    public func initation(musicUrl: URL,
                   timeStart: Float,
                   timeEnd: Float,
                   setting: SettingEditAudioModel,
                   effect: ManageEffectModel,
                   index: Int,
                   folderName: String,
                   complention: ((URL, Float64) -> Void),
                   failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
            //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
        } catch {
            failure(error, "could not open source audio file")
            fatalError("could not open source audio file, \(error)")
        }
        
        self.folderName = folderName
        songLengthSamples = sourceFile.length
        let songFormat = sourceFile.processingFormat
        sampleRateSong = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
        
        // initial Equalizer.
        EQNode = AVAudioUnitEQ(numberOfBands: frequencies.count)
        EQNode!.globalGain = 1
        for i in 0...(EQNode!.bands.count-1) {
            EQNode!.bands[i].frequency  = Float(frequencies[i])
            EQNode!.bands[i].gain       = Float(effect.preSets[i])
            EQNode!.bands[i].bypass     = false
            EQNode!.bands[i].filterType = .parametric
        }
        
        self.listAVAudioNode += [player, pitchControl, speedControl]
        
        engine.attach(player)
        engine.attach(reverb)
        // 3: connect the components to our playback engine
        // Attach nodes to an engine.
        engine.attach(pitchControl)
        engine.attach(speedControl)
        engine.attach(EQNode!)
        engine.attach(distortion)
        engine.attach(deplay)
        engine.attach(lowShelf)
        engine.attach(highShelf)
        
        speedControl.rate = setting.rate
        pitchControl.pitch = Float(effect.pitch)
        
        // set desired reverb parameters
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = Float(effect.reverb)
        
        distortion.loadFactoryPreset(.speechRadioTower)
        distortion.wetDryMix = Float(effect.distortion)
        
        deplay.wetDryMix = Float(effect.deplay)
        
        lowShelf.bands.first!.filterType = AVAudioUnitEQFilterType.lowShelf
        lowShelf.bands.first!.frequency = Float(effect.lowShelf)
        lowShelf.bypass = false
        
        highShelf.bands.first!.filterType = AVAudioUnitEQFilterType.highShelf
        highShelf.bands.first!.frequency = Float(effect.highShelf)
        highShelf.bypass = false
        
        // make connections
        //        engine.connect(player, to: reverb, format: format)
        //        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        
        //        Connect player to the EQNode.
        // 4: arrange the parts so that output from one is input to another
        //       let mixer = engine.mainMixerNode
        engine.connect(player, to: EQNode!, format: format)
        //            Connect the EQNode to the mixer.
        //       engine.connect(EQNode!, to: mixer, format: format)
        engine.connect(EQNode!, to: speedControl, format: format)
        engine.connect(speedControl, to: pitchControl, format: format)
        engine.connect(pitchControl, to: reverb, format: format)
        engine.connect(reverb, to: distortion, format: nil)
        engine.connect(distortion, to: deplay, format: nil)
        engine.connect(deplay, to: highShelf, format: nil)
        engine.connect(highShelf, to: lowShelf, format: nil)
        engine.connect(lowShelf, to: engine.mainMixerNode, format: nil)
        
        //         Connect player to the EQNode.
        //        let mixer = engine.mainMixerNode
        //        engine.connect(player, to: EQNode!, format: mixer.outputFormat(forBus: 0))
        //
        //             Connect the EQNode to the mixer.
        //        engine.connect(EQNode!, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        
        // schedule source file
        //        player.scheduleFile(sourceFile, at: nil)
        //setup start time
        let startSample = floor(Float(Int(timeStart)) * sampleRateSong)
        var lengthSamples: Float
        
        if timeEnd > 0 {
            lengthSamples = floor(Float(Int(timeEnd)) * sampleRateSong) - startSample
        } else {
            lengthSamples = Float(songLengthSamples) - startSample
            
        }
        
        
        player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
            //Because The line 167 and this line is solve async, therefore If The line 167 is start but this line is jusst completed
            // Audio can't convert
            //                                self.player.pause()
            
        })
        //: ### Enable offline manual rendering mode
        do {
            let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
        } catch {
            failure(error, "could not enable manual rendering mode")
        }
        //: ### Start the engine and player
        do {
            try engine.start()
            player.play()
            //            player2.play()
        } catch {
            failure(error, "could not start engine")
        }
        //: ## Offline Render
        //: ### Create an output buffer and an output file
        //: Output buffer format must be same as engine's manual rendering output format
        let outputFile: AVAudioFile
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .second], from: date)
            
            let year =  components.year
            let month = components.month
            let day = components.day
            let second = components.second
            let randomInt = Int.random(in: 0..<1000000)
            
            var s = sourceFile.fileFormat.settings
            s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
            //            s["AVSampleRateKey"] = 600
            //            s["AVNumberOfChannelsKey"] = 1
            //            s["AVLinearPCMBitDepthKey"] = 8
            //            setting[AVFormatIDKey] = @(kAudioFormatAppleIMA4);
            //            setting[AVSampleRateKey] = @(600.0);
            //            setting[AVNumberOfChannelsKey] = @(1);
            //            setting[AVLinearPCMBitDepthKey] = @(8);
            
            //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
            let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(self.folderName)/\(year ?? 0 )-AudioEffect-\(index)-\(month ?? 0)-\(day ?? 0)-\(second ?? 0)-\(randomInt).caf")
            outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
            
            // buffer to which the engine will render the processed data
            let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
            
            //: ### Render loop
            //: Pull the engine for desired number of frames, write the output to the destination file
            var duration1: TimeInterval{
                let songFormat = sourceFile.processingFormat
                let sampleRateSong = Float(songFormat.sampleRate)
                let lengthSongSeconds = Double(lengthSamples) / Double(sampleRateSong)
                return lengthSongSeconds
            }
            print("duration1 \(duration1)")
            
            //Calculator Duration Audio Again
            while engine.manualRenderingSampleTime < Int64(lengthSamples) {
                print("===== engine.manualRenderingSampleTime \(engine.manualRenderingSampleTime)")
                do {
                    let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(sourceFile.length - engine.manualRenderingSampleTime))
                    let status = try engine.renderOffline(framesToRender, to: buffer)
                    switch status {
                    case .success:
                        // data rendered successfully
                        try outputFile.write(from: buffer)
                        
                    case .insufficientDataFromInputNode:
                        // applicable only if using the input node as one of the sources
                        break
                        
                    case .cannotDoInCurrentContext:
                        // engine could not render in the current render call, retry in next iteration
                        break
                        
                    case .error:
                        // error occurred while renderin
                        print("render failed")
                    @unknown default:
                        break
                    }
                } catch {
                    failure(error, "render failed")
                }
            }
            
            player.stop()
            engine.stop()
            
            print("AVAudioEngine offline rendering completed")
            
            //calculator time audio with rate
            var duration: Double
            if timeEnd > 0 {
                duration = Double(timeEnd - timeStart)
            } else {
                duration = sourceFile.duration
            }
            let time = duration / Double(setting.rate)
            complention(outputFile.url, time)
            print("======= time\(time)")
        } catch {
            failure(error, "could not open output audio file \(index)")
        }
        
    }
    
    public func changeVolume(musicUrl: URL,
                      timeStart: Float,
                      timeEnd: Float,
                      valueVolume: Float,
                      folderName: String,
                      complention: ((URL, Float64) -> Void),
                      failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
//            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
        } catch {
            failure(error, "could not open source audio file")
            fatalError("could not open source audio file, \(error)")
        }
        
        songLengthSamples = sourceFile.length
        let songFormat = sourceFile.processingFormat
        sampleRateSong = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)

        // schedule source file
//        player.scheduleFile(sourceFile, at: nil)
        //setup start time
        let startSample = floor(Float(Int(timeStart)) * sampleRateSong)
        var lengthSamples: Float
        
        if timeEnd > 0 {
            lengthSamples = floor(Float(Int(timeEnd)) * sampleRateSong) - startSample
        } else {
            lengthSamples = Float(songLengthSamples) - startSample

        }
        
        player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
//                                self.player.pause()
            
        })
//        audioPlayer2.scheduleFile(sourceFile, at: nil, completionHandler: nil)
        //: ### Enable offline manual rendering mode
        do {
            let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
        } catch {
            failure(error, "could not enable manual rendering mode")
        }
        //: ### Start the engine and player
        do {
            try engine.start()
            player.play(at: self.delayTime(avAudioPLayerNode: self.player, delayTime: TimeInterval(0)))
            player.volume = valueVolume
        } catch {
            failure(error, "could not start engine")
        }
        //: ## Offline Render
        //: ### Create an output buffer and an output file
        //: Output buffer format must be same as engine's manual rendering output format
        let outputFile: AVAudioFile
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .second], from: date)
            
            let year =  components.year
            let month = components.month
            let day = components.day
            let second = components.second
            let randomInt = Int.random(in: 0..<1000000)
            
            var s = sourceFile.fileFormat.settings
            s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
            
            //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
            let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(self.folderName)/\(year ?? 0 )-AudioEffect-\(month ?? 0)-\(day ?? 0)-\(second ?? 0)-\(randomInt).caf")
            outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
            
            // buffer to which the engine will render the processed data
            let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
            
            //: ### Render loop
            //: Pull the engine for desired number of frames, write the output to the destination file
    //        var duration: TimeInterval{
    //            let sampleRateSong = Double(processingFormat.sampleRate)
    //            let lengthSongSeconds = Double(length) / sampleRateSong
    //            return lengthSongSeconds
            
    //        let lenght = sourceFile.length
    //        }
            
            //Calculator Duration Audio Again
            var countCheck: Int64 = 0
            while countCheck <= Int64(lengthSamples) {
                countCheck += 4096
                do {
                    let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(lengthSamples - Float(engine.manualRenderingSampleTime)))
                    let status = try engine.renderOffline(framesToRender, to: buffer)
                    switch status {
                    case .success:
                        // data rendered successfully
                        try outputFile.write(from: buffer)

                    case .insufficientDataFromInputNode:
                        // applicable only if using the input node as one of the sources
                        break

                    case .cannotDoInCurrentContext:
                        // engine could not render in the current render call, retry in next iteration
                        break

                    case .error:
                        // error occurred while rendering
                        print("render failed")
                    @unknown default:
                        break
                    }
                } catch {
                    failure(error, "render failed")
                }
            }
            
            player.stop()
            engine.stop()
            
            print("AVAudioEngine offline rendering completed")
            
            //calculator time audio with rate
            var duration: Double
            if timeEnd > 0 {
                duration = Double(timeEnd - timeStart)
            } else {
                duration = sourceFile.duration
            }
//            let time = duration / Double(setting.rate)
            let time = duration / Double(1)
            complention(outputFile.url, time)
        } catch {
            failure(error, "could not open output audio file \(index)")
        }
        
    }
    
    func generateRate(musicUrl: URL,
                      timeStart: Float,
                      timeEnd: Float,
                      setting: SettingEditAudioModel,
                      effect: ManageEffectModel,
                      index: Int,
                      folderName: String,
                      complention: ((URL, Float64) -> Void),
                      failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
            //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
        } catch {
            failure(error, "could not open source audio file")
            fatalError("could not open source audio file, \(error)")
        }
        
        self.folderName = folderName
        //Calculator Duration Audio bases Rate
        //If rate > 0, so we have to increase leng
        //On the other hands, we will keep it
        if setting.rate >= 1 {
            songLengthSamples = AVAudioFramePosition(Double(sourceFile.length))
        } else {
            songLengthSamples = AVAudioFramePosition(Double(sourceFile.length) / Double((setting.rate)))
        }
        
        let songFormat = sourceFile.processingFormat
        sampleRateSong = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
        
        // initial Equalizer.
        EQNode = AVAudioUnitEQ(numberOfBands: frequencies.count)
        EQNode!.globalGain = 1
        for i in 0...(EQNode!.bands.count-1) {
            EQNode!.bands[i].frequency  = Float(frequencies[i])
            EQNode!.bands[i].gain       = Float(effect.preSets[i])
            EQNode!.bands[i].bypass     = false
            EQNode!.bands[i].filterType = .parametric
        }
        
        self.listAVAudioNode += [player, pitchControl, speedControl]
        
        engine.attach(player)
        engine.attach(reverb)
        // 3: connect the components to our playback engine
        // Attach nodes to an engine.
        engine.attach(pitchControl)
        engine.attach(speedControl)
        engine.attach(EQNode!)
        engine.attach(distortion)
        engine.attach(deplay)
        engine.attach(lowShelf)
        engine.attach(highShelf)
        
        speedControl.rate = setting.rate
        pitchControl.pitch = Float(effect.pitch)
        
        // set desired reverb parameters
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = Float(effect.reverb)
        
        distortion.loadFactoryPreset(.speechRadioTower)
        distortion.wetDryMix = Float(effect.distortion)
        
        deplay.wetDryMix = Float(effect.deplay)
        
        lowShelf.bands.first!.filterType = AVAudioUnitEQFilterType.lowShelf
        lowShelf.bands.first!.frequency = Float(effect.lowShelf)
        lowShelf.bypass = false
        
        highShelf.bands.first!.filterType = AVAudioUnitEQFilterType.highShelf
        highShelf.bands.first!.frequency = Float(effect.highShelf)
        highShelf.bypass = false
        
        // make connections
        //        engine.connect(player, to: reverb, format: format)
        //        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        
        //        Connect player to the EQNode.
        // 4: arrange the parts so that output from one is input to another
        //       let mixer = engine.mainMixerNode
        engine.connect(player, to: EQNode!, format: format)
        //            Connect the EQNode to the mixer.
        //       engine.connect(EQNode!, to: mixer, format: format)
        engine.connect(EQNode!, to: speedControl, format: format)
        engine.connect(speedControl, to: pitchControl, format: format)
        engine.connect(pitchControl, to: reverb, format: format)
        engine.connect(reverb, to: distortion, format: nil)
        engine.connect(distortion, to: deplay, format: nil)
        engine.connect(deplay, to: highShelf, format: nil)
        engine.connect(highShelf, to: lowShelf, format: nil)
        engine.connect(lowShelf, to: engine.mainMixerNode, format: nil)
        
        //         Connect player to the EQNode.
        //        let mixer = engine.mainMixerNode
        //        engine.connect(player, to: EQNode!, format: mixer.outputFormat(forBus: 0))
        //
        //             Connect the EQNode to the mixer.
        //        engine.connect(EQNode!, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        
        // schedule source file
        //        player.scheduleFile(sourceFile, at: nil)
        //setup start time
        let startSample = floor(Float(Int(timeStart)) * sampleRateSong)
        var lengthSamples: Float
        
        if timeEnd > 0 {
            lengthSamples = floor(Float(Int(timeEnd)) * sampleRateSong) - startSample
        } else {
            lengthSamples = Float(songLengthSamples) - startSample
        }
        
        
        player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
            //                                self.player.pause()
            
        })
        //: ### Enable offline manual rendering mode
        do {
            let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
        } catch {
            failure(error, "could not enable manual rendering mode")
        }
        //: ### Start the engine and player
        do {
            try engine.start()
            player.play()
            //            player2.play()
        } catch {
            failure(error, "could not start engine")
        }
        //: ## Offline Render
        //: ### Create an output buffer and an output file
        //: Output buffer format must be same as engine's manual rendering output format
        let outputFile: AVAudioFile
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .second], from: date)
            
            let year =  components.year
            let month = components.month
            let day = components.day
            let second = components.second
            let randomInt = Int.random(in: 0..<1000000)
            
            var s = sourceFile.fileFormat.settings
            s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
            
            //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
            let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(self.folderName)/\(year ?? 0 )-AudioEffect-\(index)-\(month ?? 0)-\(day ?? 0)-\(second ?? 0)-\(randomInt).caf")
            outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
            
            // buffer to which the engine will render the processed data
            let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                                            frameCapacity: engine.manualRenderingMaximumFrameCount)!
            
            //: ### Render loop
            //: Pull the engine for desired number of frames, write the output to the destination file
            
            //Calculator Duration bases on Rate
            lengthSamples = lengthSamples / Float(setting.rate)
            
            //Calculator Duration Audio Again
            var countCheck: Int64 = 0
            while countCheck <= Int64(lengthSamples) {
                countCheck += 4096
                do {
                    let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(songLengthSamples - engine.manualRenderingSampleTime))
                    let status = try engine.renderOffline(framesToRender, to: buffer)
                    switch status {
                    case .success:
                        // data rendered successfully
                        try outputFile.write(from: buffer)
                        
                    case .insufficientDataFromInputNode:
                        // applicable only if using the input node as one of the sources
                        break
                        
                    case .cannotDoInCurrentContext:
                        // engine could not render in the current render call, retry in next iteration
                        break
                        
                    case .error:
                        // error occurred while rendering
                        print("render failed")
                    @unknown default:
                        break
                    }
                } catch {
                    failure(error, "render failed")
                }
            }
            
            player.stop()
            engine.stop()
            
            print("AVAudioEngine offline rendering completed")
            
            //calculator time audio with rate
            var duration: Double
            if timeEnd > 0 {
                duration = Double(timeEnd - timeStart)
            } else {
                duration = sourceFile.duration
            }
            let time = duration / Double(setting.rate)
            complention(outputFile.url, time)
            print("======= time\(time)")
        } catch {
            failure(error, "could not open output audio file \(index)")
        }
        
    }
    
    func mergeAudios(musicUrl: URL,
                     folderName: String,
                     fileName: String,
                     listAudioProtocol: [MutePoint],
                     complention: ((URL, Float64) -> Void),
                     failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
            //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
            
            songLengthSamples = sourceFile.length
            let songFormat = sourceFile.processingFormat
            sampleRateSong = Float(songFormat.sampleRate)
            lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
            
            var listPlayer: [AVAudioPlayerNode] = []
            listAudioProtocol.enumerated().forEach { (item) in
                let source: AVAudioFile
                do {
                    source = try AVAudioFile(forReading: item.element.url)
                    let songLengthSamples = source.length
                    let songFormat = source.processingFormat
                    let sampleRateSong = Float(songFormat.sampleRate)
                    
                    let p = AVAudioPlayerNode()
                    engine.attach(p)
                    engine.connect(p, to: engine.mainMixerNode, format: nil)
                    
                    let startSample = sampleRateSong
                    let lengthSamples = songLengthSamples
                    
                    p.scheduleSegment(source, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
                        //                                    p.pause()
                    })
                    listPlayer.append(p)
                } catch {
                    failure(error, "could not open source audio file")
                }
            }
            
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            
            // schedule source file
            //        player.scheduleFile(sourceFile, at: nil)
            //setup start time
            let startSample = floor(Float(Int(0)) * sampleRateSong)
            let lengthSamples: Float = Float(songLengthSamples) - startSample
            
            player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
                //                                self.player.pause()
                
            })
            //        audioPlayer2.scheduleFile(sourceFile, at: nil, completionHandler: nil)
            //: ### Enable offline manual rendering mode
            do {
                let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
                try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
            } catch {
                failure(error, "could not enable manual rendering mode")
            }
            //: ### Start the engine and player
            do {
                try engine.start()
                listPlayer.enumerated().forEach { (item) in
                    let s = listAudioProtocol[item.offset].start
                    item.element.play(at: self.delayTime(avAudioPLayerNode: item.element, delayTime: TimeInterval(s)))
                }
                player.play(at: self.delayTime(avAudioPLayerNode: self.player, delayTime: TimeInterval(0)))
            } catch {
                failure(error, "could not start engine")
            }
            //: ## Offline Render
            //: ### Create an output buffer and an output file
            //: Output buffer format must be same as engine's manual rendering output format
            let outputFile: AVAudioFile
            do {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                var s = sourceFile.fileFormat.settings
                s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
                
                //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
                let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(folderName)/\(fileName)").appendingPathExtension("caf")
                outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
                
                // buffer to which the engine will render the processed data
                let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
                
                //: ### Render loop
                //: Pull the engine for desired number of frames, write the output to the destination file
                //        var duration: TimeInterval{
                //            let sampleRateSong = Double(processingFormat.sampleRate)
                //            let lengthSongSeconds = Double(length) / sampleRateSong
                //            return lengthSongSeconds
                
                //        let lenght = sourceFile.length
                //        }
                
                //Calculator Duration Audio Again
                while engine.manualRenderingSampleTime < Int64(lengthSamples) {
                    do {
                        
                        let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(lengthSamples - Float(engine.manualRenderingSampleTime)))
                        let status = try engine.renderOffline(framesToRender, to: buffer)
                        switch status {
                        case .success:
                            // data rendered successfully
                            try outputFile.write(from: buffer)
                            
                        case .insufficientDataFromInputNode:
                            // applicable only if using the input node as one of the sources
                            break
                            
                        case .cannotDoInCurrentContext:
                            // engine could not render in the current render call, retry in next iteration
                            break
                            
                        case .error:
                            // error occurred while rendering
                            print("render failed")
                        @unknown default:
                            break
                        }
                    } catch {
                        failure(error, "render failed")
                    }
                }
                
                listPlayer.forEach { (item) in
                    item.stop()
                }
                
                player.stop()
                engine.stop()
                
                print("AVAudioEngine offline rendering completed")
                
                //calculator time audio with rate
                let duration: Double = sourceFile.duration
                //            let time = duration / Double(setting.rate)
                let time = duration / Double(1)
                complention(outputFile.url, time)
            } catch {
                failure(error, "could not open output audio file)")
            }
        } catch {
            failure(error, "could not open source audio file")
        }
        
    }
    
    
    
    public func mergeAudiosSplits(musicUrl: URL,
                   timeStart: CGFloat,
                   timeEnd: CGFloat,
                   index: Int,
                   listAudioProtocol: [SplitAudioModel],
                   deplayTime: CGFloat,
                   nameMusic: String,
                   folderName: String,
                   nameId: String,
                   complention: ((URL, Float64) -> Void),
                   failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
//            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
            songLengthSamples = sourceFile.length
            let songFormat = sourceFile.processingFormat
            sampleRateSong = Float(songFormat.sampleRate)
            lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
            self.folderName = folderName
            var listPlayer: [AVAudioPlayerNode] = []
            listAudioProtocol.enumerated().forEach { (item) in
                guard let urlAudio = item.element.url else { return }
                let source: AVAudioFile
                let f: AVAudioFormat
                do {
        //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
                    source = try AVAudioFile(forReading: urlAudio)
                    f = sourceFile.processingFormat
                } catch {
                    failure(error, "could not open source audio file")
                    fatalError("render failed, \(error)")
                }
                
                 let songLengthSamples = source.length
                let songFormat = source.processingFormat
                let sampleRateSong = Float(songFormat.sampleRate)
                let lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
                
                let p = AVAudioPlayerNode()
                engine.attach(p)
                engine.connect(p, to: engine.mainMixerNode, format: nil)
                
                let startSample = floor(Float(Int(timeStart)) * sampleRateSong)
                var lengthSamples: Float
                
                if timeEnd > 0 {
                    lengthSamples = floor(Float(Int(timeEnd)) * sampleRateSong) - startSample
                } else {
                    lengthSamples = Float(songLengthSamples) - startSample
                }
                
                p.scheduleSegment(source, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
    //                                    p.pause()
                })
                listPlayer.append(p)
            }
            
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)

            // schedule source file
    //        player.scheduleFile(sourceFile, at: nil)
            //setup start time
            let startSample = floor(Float(Int(timeStart)) * sampleRateSong)
            var lengthSamples: Float
            
            if timeEnd > 0 {
                lengthSamples = floor(Float(Int(timeEnd)) * sampleRateSong) - startSample
            } else {
                lengthSamples = Float(songLengthSamples) - startSample

            }
            
            player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
    //                                self.player.pause()
                
            })
    //        audioPlayer2.scheduleFile(sourceFile, at: nil, completionHandler: nil)
            //: ### Enable offline manual rendering mode
            do {
                let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
                try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
                //: ### Start the engine and player
                do {
                    try engine.start()
                    listPlayer.enumerated().forEach { (item) in
                        let s = listAudioProtocol[item.offset].startSecond
                        item.element.play(at: self.delayTime(avAudioPLayerNode: item.element, delayTime: TimeInterval(s)))
                    }
                    player.play(at: self.delayTime(avAudioPLayerNode: self.player, delayTime: TimeInterval(deplayTime)))
                } catch {
                    failure(error, "could not start engine")
                }
                //: ## Offline Render
                //: ### Create an output buffer and an output file
                //: Output buffer format must be same as engine's manual rendering output format
                let outputFile: AVAudioFile
                do {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    var s = sourceFile.fileFormat.settings
                    s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
                    
                    //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
                    let outputURL = URL(fileURLWithPath: documentsPath)
                        .appendingPathComponent("\(self.folderName)/\(nameMusic)\(nameId)")
                        .appendingPathExtension("caf")
                    outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
                    
                    // buffer to which the engine will render the processed data
                    let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
                    
                    //: ### Render loop
                    //: Pull the engine for desired number of frames, write the output to the destination file
            //        var duration: TimeInterval{
            //            let sampleRateSong = Double(processingFormat.sampleRate)
            //            let lengthSongSeconds = Double(length) / sampleRateSong
            //            return lengthSongSeconds
                    
            //        let lenght = sourceFile.length
            //        }
                    
                    //Calculator Duration Audio Again
                    var countCheck: Int64 = 0
                    while countCheck <= Int64(lengthSamples) {
                        countCheck += 4096
                        do {
                            let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(lengthSamples - Float(engine.manualRenderingSampleTime)))
                            let status = try engine.renderOffline(framesToRender, to: buffer)
                            switch status {
                            case .success:
                                // data rendered successfully
                                try outputFile.write(from: buffer)

                            case .insufficientDataFromInputNode:
                                // applicable only if using the input node as one of the sources
                                break

                            case .cannotDoInCurrentContext:
                                // engine could not render in the current render call, retry in next iteration
                                break

                            case .error:
                                // error occurred while rendering
                                print("render failed")
                            @unknown default:
                                break
                            }
                        } catch {
                            failure(error, "render failed")
                        }
                    }

                    listPlayer.forEach { (item) in
                        item.stop()
                    }
                    player.stop()
                    engine.stop()
                    
                    print("AVAudioEngine offline rendering completed")
                    
                    //calculator time audio with rate
                    var duration: Double
                    if timeEnd > 0 {
                        duration = Double(timeEnd - timeStart)
                    } else {
                        duration = sourceFile.duration
                    }
        //            let time = duration / Double(setting.rate)
                    let time = duration / Double(1)
                    complention(outputFile.url, time)
                } catch {
                    failure(error, "could not open output audio file \(index)")
                }
            } catch {
                failure(error, "could not enable manual rendering mode")
            }
            
        } catch {
            failure(error, "could not open source audio file")
            fatalError("could not open source audio file, \(error)")
        }
        
    }
    
    func muteTimeAudio(musicUrl: URL,
                       //                   listAudioProtocol: [EditAudioProtocol],
                       folderName: String,
                       fileName: String,
                       listMutePoint: [MutePoint],
                       complention: ((URL, Float64) -> Void),
                       failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
            //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
            
            songLengthSamples = sourceFile.length
            let songFormat = sourceFile.processingFormat
            sampleRateSong = Float(songFormat.sampleRate)
            lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
            
            //        var listPlayer: [AVAudioPlayerNode] = []
            //        listAudioProtocol.enumerated().forEach { (item) in
            //            guard let urlAudio = item.element.urlAudio else { return }
            //            let source: AVAudioFile
            //            do {
            //    //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            //                source = try AVAudioFile(forReading: urlAudio)
            //            } catch {
            //                failure(error, "could not open source audio file")
            //                fatalError("render failed, \(error)")
            //            }
            //
            //            let songLengthSamples = source.length
            //            let songFormat = source.processingFormat
            //            let sampleRateSong = Float(songFormat.sampleRate)
            //
            //            let p = AVAudioPlayerNode()
            //            engine.attach(p)
            //            engine.connect(p, to: engine.mainMixerNode, format: nil)
            //
            //            let startSample = sampleRateSong
            //            let lengthSamples = songLengthSamples
            //
            //            p.scheduleSegment(source, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
            ////                                    p.pause()
            //            })
            //            listPlayer.append(p)
            //        }
            
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            
            // schedule source file
            //        player.scheduleFile(sourceFile, at: nil)
            //setup start time
            let startSample = floor(Float(Int(0)) * sampleRateSong)
            let lengthSamples: Float = Float(songLengthSamples) - startSample
            
            player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
                //                                self.player.pause()
                
            })
            //        audioPlayer2.scheduleFile(sourceFile, at: nil, completionHandler: nil)
            //: ### Enable offline manual rendering mode
            do {
                let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
                try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
            } catch {
                failure(error, "could not enable manual rendering mode")
            }
            //: ### Start the engine and player
            do {
                try engine.start()
                player.play(at: self.delayTime(avAudioPLayerNode: self.player, delayTime: TimeInterval(0)))
            } catch {
                failure(error, "could not start engine")
            }
            //: ## Offline Render
            //: ### Create an output buffer and an output file
            //: Output buffer format must be same as engine's manual rendering output format
            let outputFile: AVAudioFile
            do {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                var s = sourceFile.fileFormat.settings
                s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
                
                //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
                let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(folderName)/\(fileName)").appendingPathExtension("caf")
                outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
                
                // buffer to which the engine will render the processed data
                let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
                
                //: ### Render loop
                //: Pull the engine for desired number of frames, write the output to the destination file
                //        var duration: TimeInterval{
                //            let sampleRateSong = Double(processingFormat.sampleRate)
                //            let lengthSongSeconds = Double(length) / sampleRateSong
                //            return lengthSongSeconds
                
                //        let lenght = sourceFile.length
                //        }
                
                //Calculator Duration Audio Again
                while engine.manualRenderingSampleTime < Int64(lengthSamples) {
                    do {
                        var isMute: Bool = false
                        for point in listMutePoint {
                            let start = sampleRateSong * point.start
                            let end = sampleRateSong * point.getEndTime()
                            if engine.manualRenderingSampleTime > Int64(start) && engine.manualRenderingSampleTime < Int64(end) {
                                isMute = true
                            }
                        }
                        if isMute {
                            player.volume = 0
                        } else {
                            player.volume = 1
                        }
                        
                        let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(lengthSamples - Float(engine.manualRenderingSampleTime)))
                        let status = try engine.renderOffline(framesToRender, to: buffer)
                        switch status {
                        case .success:
                            // data rendered successfully
                            try outputFile.write(from: buffer)
                            
                        case .insufficientDataFromInputNode:
                            // applicable only if using the input node as one of the sources
                            break
                            
                        case .cannotDoInCurrentContext:
                            // engine could not render in the current render call, retry in next iteration
                            break
                            
                        case .error:
                            // error occurred while rendering
                            print("render failed")
                        @unknown default:
                            break
                        }
                    } catch {
                        failure(error, "render failed")
                    }
                }
                
                player.stop()
                engine.stop()
                
                print("AVAudioEngine offline rendering completed")
                
                //calculator time audio with rate
                let duration: Double = sourceFile.duration
                //            let time = duration / Double(setting.rate)
                let time = duration / Double(1)
                complention(outputFile.url, time)
            } catch {
                failure(error, "could not open output audio file)")
            }
        } catch {
            failure(error, "could not open source audio file")
            fatalError("could not open source audio file, \(error)")
        }
        
    }
    
    func trimAudios(musicUrl: URL,
                    timeStart: Float,
                    timeEnd: Float,
                    index: Int,
                    folderName: String,
                    complention: ((URL, Float64) -> Void),
                    failure: ((Error, String) -> Void)) {
        //: ## Source File
        //: Open the audio file to process
        
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
            //            let sourceFileURL = Bundle.main.url(forResource: "nhaccuatui", withExtension: "caf")!
            sourceFile = try AVAudioFile(forReading: musicUrl)
            format = sourceFile.processingFormat
        } catch {
            failure(error, "could not open source audio file")
            fatalError("could not open source audio file, \(error)")
        }
        
        songLengthSamples = sourceFile.length
        let songFormat = sourceFile.processingFormat
        sampleRateSong = Float(songFormat.sampleRate)
        lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        
        // schedule source file
        //        player.scheduleFile(sourceFile, at: nil)
        //setup start time
        let startSample = floor(Float(Int(timeStart)) * sampleRateSong)
        var lengthSamples: Float
        
        if timeEnd > 0 {
            lengthSamples = floor(Float(Int(timeEnd)) * sampleRateSong) - startSample
        } else {
            lengthSamples = Float(songLengthSamples) - startSample
            
        }
        
        player.scheduleSegment(sourceFile, startingFrame: AVAudioFramePosition(startSample), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {
            //                                self.player.pause()
            
        })
        //        audioPlayer2.scheduleFile(sourceFile, at: nil, completionHandler: nil)
        //: ### Enable offline manual rendering mode
        do {
            let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxNumberOfFrames)
        } catch {
            failure(error, "could not enable manual rendering mode")
        }
        //: ### Start the engine and player
        do {
            try engine.start()
            player.play()
        } catch {
            failure(error, "could not start engine")
        }
        //: ## Offline Render
        //: ### Create an output buffer and an output file
        //: Output buffer format must be same as engine's manual rendering output format
        let outputFile: AVAudioFile
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .second], from: date)
            
            let year =  components.year
            let month = components.month
            let day = components.day
            let second = components.second
            let randomInt = Int.random(in: 0..<1000000)
            
            var s = sourceFile.fileFormat.settings
            s["AVFormatIDKey"] = kAudioFormatMPEG4AAC
            
            //If convert to m4a is Error, try to use like .caf or .aifc or aiff.
            let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(self.folderName)/\(year ?? 0 )-AudioEffect-\(index)-\(month ?? 0)-\(day ?? 0)-\(second ?? 0)-\(randomInt).caf")
            outputFile = try AVAudioFile(forWriting: outputURL, settings: s)
            
            // buffer to which the engine will render the processed data
            let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
            
            //: ### Render loop
            //: Pull the engine for desired number of frames, write the output to the destination file
            //        var duration: TimeInterval{
            //            let sampleRateSong = Double(processingFormat.sampleRate)
            //            let lengthSongSeconds = Double(length) / sampleRateSong
            //            return lengthSongSeconds
            
            //        let lenght = sourceFile.length
            //        }
            
            //Calculator Duration Audio Again
            var countCheck: Int64 = 0
            while engine.manualRenderingSampleTime < Int64(lengthSamples) {
                countCheck += 4096
                do {
                    let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(lengthSamples - Float(engine.manualRenderingSampleTime)))
                    let status = try engine.renderOffline(framesToRender, to: buffer)
                    switch status {
                    case .success:
                        // data rendered successfully
                        try outputFile.write(from: buffer)
                        
                    case .insufficientDataFromInputNode:
                        // applicable only if using the input node as one of the sources
                        break
                        
                    case .cannotDoInCurrentContext:
                        // engine could not render in the current render call, retry in next iteration
                        break
                        
                    case .error:
                        // error occurred while rendering
                        print("render failed")
                    @unknown default:
                        break
                    }
                } catch {
                    failure(error, "render failed")
                    
                }
            }
            
            player.stop()
            engine.stop()
            
            print("AVAudioEngine offline rendering completed")
            
            //calculator time audio with rate
            var duration: Double
            if timeEnd > 0 {
                duration = Double(timeEnd - timeStart)
            } else {
                duration = sourceFile.duration
            }
            //            let time = duration / Double(setting.rate)
            let time = duration / Double(1)
            complention(outputFile.url, time)
        } catch {
            failure(error, "could not open output audio file \(index)")
        }
        
    }
    
    func delayTime(avAudioPLayerNode: AVAudioPlayerNode , delayTime : TimeInterval) -> AVAudioTime{
        let  outputFormat = avAudioPLayerNode.outputFormat(forBus: 0)
        let  startSampleTime = (avAudioPLayerNode.lastRenderTime ?? AVAudioTime()).sampleTime +  Int64(Double(delayTime) * outputFormat.sampleRate);
        return  AVAudioTime(sampleTime: startSampleTime, atRate: outputFormat.sampleRate)
    }
    
    func generateBuffer(forBpm bpm: Int, audioFile: AVAudioFile) -> AVAudioPCMBuffer {
        audioFile.framePosition = 0
        let periodLength = AVAudioFrameCount(audioFile.processingFormat.sampleRate * 60 / Double(bpm))
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: periodLength)
        try! audioFile.read(into: buffer!)
        buffer?.frameLength = periodLength
        return buffer!
    }
    
}

extension AVAudioFile{
    
    var duration: TimeInterval{
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong
        return lengthSongSeconds
    }
    
}
extension AVAudioPlayerNode {
    var currentTime: TimeInterval {
        get {
            if let nodeTime: AVAudioTime = self.lastRenderTime, let playerTime: AVAudioTime = self.playerTime(forNodeTime: nodeTime) {
                return Double(playerTime.sampleTime) / playerTime.sampleRate
            }
            return 0
        }
    }
}


// MARK: GET, SET
//extension AudioManagerEffect {
//    public func setBypass(_ isOn: Bool) {
//        for i in 0...(EQNode!.bands.count-1) {
//            EQNode!.bands[i].bypass = isOn
//        }
//    }
//
//    public func setEquailizerOptions(gains: [Float]) {
//        guard let EQNode = EQNode else {
//            return
//        }
//        for i in 0...(EQNode.bands.count-1) {
//            EQNode.bands[i].gain = gains[i]
//        }
//    }
//
//    public func getEquailizerOptions() -> [Float] {
//        guard let EQNode = EQNode else {
//            return []
//        }
//        return EQNode.bands.map { $0.gain }
//    }
//}

struct AudioRecordModel {
    let url: URL
    let deplay: Int
}

protocol EditAudioProtocol {
    var urlAudio: URL? { get }
    var timeWaitAudio: Int? { get }
    var startTimeAudio: Float64? { get }
    var endTimeAudio: Float64? { get }
    var totalTimeAudio: Int? { get }
    var indexAudio: Int? { get }
}

struct EditAudioModel: EditAudioProtocol {
    var indexAudio: Int? {
        return self.index
    }
    
    var totalTimeAudio: Int? {
        return self.totalTime
    }
    
    var startTimeAudio: Float64? {
        return self.startTime
    }
    
    var endTimeAudio: Float64? {
        return self.endTime
    }
    
    var timeWaitAudio: Int? {
        return self.timeWait
    }
    
    var urlAudio: URL? {
        return self.url
    }
    
    var index: Int?
    var url: URL?
    var timeAudio: Float64?
    var startTime: Float64?
    var endTime: Float64?
    var timeWait: Int?
    var totalTime: Int?
}
public struct SettingEditAudioModel  {
    public var rate: Float = 1
    public init () {}
}
public struct ManageEffectModel {
    public var scenes: Int = 0
    public var reverb: CGFloat = 0
    public var setStart: CGFloat = 0
    public var setEnd: CGFloat = 0
    public var pitch: CGFloat = 0
    public var deplay: CGFloat = 0
    public var distortion: CGFloat = 0
    public var highShelf: CGFloat = 0
    public var lowShelf: CGFloat = 0
    public var equalizer: Int = 0
    public var preSets: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    public init () {}
}
public struct RecordAudioModel: Codable {
    let id: Double?
    let url: URL?
    let date: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, date
    }
    
    func getName() -> String? {
        guard let url = self.url else {
            return nil
        }
        
        return url.deletingPathExtension().deletingPathExtension().lastPathComponent
    }
    
    func getType() -> String? {
        guard let url = self.url else {
            return nil
        }
        
        return url.pathExtension
    }
    
    func getSize() -> Double? {
        guard let filePath = url?.path else {
            return nil
        }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / 1000000.0
            }
        } catch {
            print("Error: \(error)")
        }
        return nil
    }
    
    func getDuration() -> Double? {
        guard let url = self.url else {
            return nil
        }
        return url.getDuration()
    }
    
}

public struct MutePoint {
    public var url: URL
    public let start: Float
    let end: Float
    public init(start: Float, end: Float, url: URL) {
        self.start = start
        self.end = end
        self.url = url
    }
    
    public func getEndTime() -> Float {
        return self.start + self.end
    }
}

public struct SplitAudioModel {
    public enum AddMusicStatus {
        case addMusic, addBgMusic
    }
    
    public let view: UIView
    public var listPointWave: [UIView] = []
    public var positionX: CGFloat = 0
    public var startSecond: CGFloat
    public var endSecond: CGFloat
    public var url: URL?
    public let distanceToLeft: CGFloat = 0
    public var rangeSlider: ABVideoRangeSlider?
    public var addMusicStatus: AddMusicStatus = .addMusic
    
    public init(view: UIView, startSecond: CGFloat, endSecond: CGFloat, url: URL) {
        self.view = view
        self.startSecond = startSecond
        self.endSecond = endSecond
        self.url = url
    }
    
    public func startAudio() -> CGFloat {
        switch self.addMusicStatus {
        case .addMusic:
            return (self.view.frame.origin.x - self.distanceToLeft) / 80
        case .addBgMusic:
            return (self.view.frame.origin.x) / 80
        }
        
    }
}
