//
//  SongExporter.swift
//  SongProcessor
//
//  Created by Aurelius Prochazka on 6/29/16.
//  Copyright © 2016 AudioKit. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
//import AudioKit

public class SongExporter {
    
    var exportPath: String = ""
    
    init(exportPath: String) {
        self.exportPath = exportPath
    }
    
    public func exportSong(_ song: MPMediaItem) {
    
        let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as! URL
        let songAsset = AVURLAsset(url: url, options: nil)
        
        var assetError: NSError?
        
        do {
            let assetReader = try AVAssetReader(asset: songAsset)
            
            // Create an asset reader ouput and add it to the reader.
            let assetReaderOutput = AVAssetReaderAudioMixOutput(audioTracks: songAsset.tracks,audioSettings: nil)
            
            if !assetReader.canAdd(assetReaderOutput) {
                print("Can't add reader output...die!")
            } else {
                assetReader.add(assetReaderOutput)
            }
            
            // If a file already exists at the export path, remove it.
            if FileManager.default.fileExists(atPath: exportPath) {
                print("Deleting said file.")
                do {
                    try FileManager.default.removeItem(atPath: exportPath)
                } catch _ {
                }
            }
            
            // Create an asset writer with the export path.
            let exportURL = URL(fileURLWithPath: exportPath)
            let assetWriter: AVAssetWriter!
            do {
                assetWriter = try AVAssetWriter(outputURL: exportURL, fileType: AVFileType.caf)
            } catch let error as NSError {
                assetError = error
                assetWriter = nil
            }
            
            if assetError != nil {
                print("Error \(String(describing: assetError))")
                return
            }
            
            // Define the format settings for the asset writer.  Defined in AVAudioSettings.h
            
            // memset(&channelLayout, 0, sizeof(AudioChannelLayout))
            let outputSettings = [ AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM as UInt32),
                                   AVSampleRateKey: NSNumber(value: 44100.0 as Float),
                                   AVNumberOfChannelsKey: NSNumber(value: 2 as UInt32),
                                   AVLinearPCMBitDepthKey: NSNumber(value: 16 as Int32),
                                   AVLinearPCMIsNonInterleaved: NSNumber(value: false as Bool),
                                   AVLinearPCMIsFloatKey: NSNumber(value: false as Bool),
                                   AVLinearPCMIsBigEndianKey: NSNumber(value: false as Bool)
            ]
            
            // Create a writer input to encode and write samples in this format.
            let assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio,
                                                      outputSettings: outputSettings)
            
            // Add the input to the writer.
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
            } else {
                print("cant add asset writer input...die!")
                return
            }
            
            // Change this property to YES if you want to start using the data immediately.
            assetWriterInput.expectsMediaDataInRealTime = false
            
            // Start reading from the reader and writing to the writer.
            assetWriter.startWriting()
            assetReader.startReading()
            
            // Set the session start time.
            let soundTrack = songAsset.tracks[0]
            let cmtStartTime: CMTime = CMTimeMake(value: 0, timescale: soundTrack.naturalTimeScale)
            assetWriter.startSession(atSourceTime: cmtStartTime)
            
            // Variable to store the converted bytes.
            var convertedByteCount: Int = 0
            var buffers: Float = 0
            
            // Create a queue to which the writing block with be submitted.
            let mediaInputQueue: DispatchQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])
            
            // Instruct the writer input to invoke a block repeatedly, at its convenience, in
            // order to gather media data for writing to the output.
            assetWriterInput.requestMediaDataWhenReady(on: mediaInputQueue, using: {
                
                // While the writer input can accept more samples, keep appending its buffers
                // with buffers read from the reader output.
                while (assetWriterInput.isReadyForMoreMediaData) {
                    
                    if let nextBuffer = assetReaderOutput.copyNextSampleBuffer() {
                        assetWriterInput.append(nextBuffer)
                        // Increment byte count.
                        convertedByteCount += CMSampleBufferGetTotalSampleSize(nextBuffer)
                        buffers += 0.0002
                        
                    } else {
                        // All done
                        assetWriterInput.markAsFinished()
                        assetWriter.finishWriting(){
                            
                        }
                        assetReader.cancelReading()
                        break
                    }
                    // Core Foundation objects automatically memory managed in Swift
                    // CFRelease(nextBuffer)
                }
            })
            
        } catch let error as NSError {
            assetError = error
            print("Initializing assetReader Failed  \(error)")
        }
        
    }

    
    public func exportSongWithURL(_ url:URL, completion: @escaping((URL) -> Void), failure: @escaping ((String) -> Void)) {
        let songAsset = AVURLAsset(url: url, options: nil)
        
        var assetError: NSError?
        
        do {
            let assetReader = try AVAssetReader(asset: songAsset)
            
            // Create an asset reader ouput and add it to the reader.
            let assetReaderOutput = AVAssetReaderAudioMixOutput(audioTracks: songAsset.tracks,audioSettings: nil)
            
            if !assetReader.canAdd(assetReaderOutput) {
                print("Can't add reader output...die!")
            } else {
                assetReader.add(assetReaderOutput)
            }
            
            // If a file already exists at the export path, remove it.
            if FileManager.default.fileExists(atPath: exportPath) {
                print("Override file.")
                do {
                    try FileManager.default.removeItem(atPath: exportPath)
                } catch _ {
                }
            }
            
            // Create an asset writer with the export path.
            let exportURL = URL(fileURLWithPath: exportPath)
            print("export url\n",exportURL.path)
            let assetWriter: AVAssetWriter!
            do {
                assetWriter = try AVAssetWriter(outputURL: exportURL, fileType: AVFileType.m4a)
            } catch let error as NSError {
                assetError = error
                assetWriter = nil
            }
            
            if assetError != nil {
                print("Error \(String(describing: assetError))")
                failure(assetError?.localizedDescription ?? "")
                return
            }
            
            // Define the format settings for the asset writer.  Defined in AVAudioSettings.h
            /*
            @constant       kAudioFormatMPEG4AAC
            MPEG-4 Low Complexity AAC audio object, has no flags.
             */
            
            // memset(&channelLayout, 0, sizeof(AudioChannelLayout))
            let outputSettings = [ AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                                   AVSampleRateKey: NSNumber(value: 44100.0 as Float),
                                   AVNumberOfChannelsKey: NSNumber(value: 1 as UInt32),
                                   
                                   
            ]
            
            // If one of AVLinearPCMIsFloatKey and AVLinearPCMBitDepthKey is specified, both must be specified'
            
            // Create a writer input to encode and write samples in this format.
            let assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio,
                                                      outputSettings: outputSettings)
            
            // Add the input to the writer.
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
            } else {
                print("cant add asset writer input...die!")
                return
            }
            
            // Change this property to YES if you want to start using the data immediately.
            assetWriterInput.expectsMediaDataInRealTime = false
            
            // Start reading from the reader and writing to the writer.
            assetWriter.startWriting()
            assetReader.startReading()
            
            // Set the session start time.
            let soundTrack = songAsset.tracks[0]
            let cmtStartTime: CMTime = CMTimeMake(value: 0, timescale: soundTrack.naturalTimeScale)
            assetWriter.startSession(atSourceTime: cmtStartTime)
            
            // Variable to store the converted bytes.
            var convertedByteCount: Int = 0
            var buffers: Float = 0
            
            // Create a queue to which the writing block with be submitted.
            let mediaInputQueue: DispatchQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])
            
            // Instruct the writer input to invoke a block repeatedly, at its convenience, in
            // order to gather media data for writing to the output.
            assetWriterInput.requestMediaDataWhenReady(on: mediaInputQueue, using: {
                
                // While the writer input can accept more samples, keep appending its buffers
                // with buffers read from the reader output.
                while (assetWriterInput.isReadyForMoreMediaData) {
                    
                    if let nextBuffer = assetReaderOutput.copyNextSampleBuffer() {
                        assetWriterInput.append(nextBuffer)
                        // Increment byte count.
                        convertedByteCount += CMSampleBufferGetTotalSampleSize(nextBuffer)
                        buffers += 0.0002
                        
                    } else {
                        // All done
                        assetWriterInput.markAsFinished()
                        assetWriter.finishWriting(){
                            completion(exportURL)
                        }
                        assetReader.cancelReading()
                        
                        break
                    }
                    // Core Foundation objects automatically memory managed in Swift
                    // CFRelease(nextBuffer)
                }
            })
            
        } catch let error as NSError {
            assetError = error
            print("Initializing assetReader Failed: \(error)")
            failure(error.localizedDescription)
        }
        
    }
    
    public  class func convertAudio(_ url: URL, outputURL: URL) {
        var error : OSStatus = noErr
        var destinationFile : ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil
        
        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        ExtAudioFileOpenURL(url as CFURL, &sourceFile)
        
        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))
        
        ExtAudioFileGetProperty(sourceFile!,
                                kExtAudioFileProperty_FileDataFormat,
                                &thePropertySize, &srcFormat)
        
        dstFormat.mSampleRate = 44100  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kAudioFormatFlagIsBigEndian |
        kAudioFormatFlagIsSignedInteger
        
        // Create destination file
        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            kAudioFileM4AType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        reportError(error: error)
        
        error = ExtAudioFileSetProperty(sourceFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        reportError(error: error)
        
        error = ExtAudioFileSetProperty(destinationFile!,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        reportError(error: error)
        
        let bufferByteSize : UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        var sourceFrameOffset : ULONG = 0
        
        while(true){
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 2,
                    mDataByteSize: UInt32(srcBuffer.count),
                    mData: &srcBuffer
                )
            )
            var numFrames : UInt32 = 0
            
            if(dstFormat.mBytesPerFrame > 0){
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }
            
            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            reportError(error: error)
            
            if(numFrames == 0){
                error = noErr;
                break;
            }
            
            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            reportError(error: error)
        }
        
        error = ExtAudioFileDispose(destinationFile!)
        reportError(error: error)
        error = ExtAudioFileDispose(sourceFile!)
        reportError(error: error)
    }
    
    class func reportError(error: OSStatus) {
        // Handle error
        print("error: \(error)")
    }

}
