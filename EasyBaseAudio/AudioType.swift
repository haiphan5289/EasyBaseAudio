//
//  AudioType.swift
//  EasyBaseAudio
//
//  Created by haiphan on 10/04/2022.
//

import Foundation
import UIKit
import Photos
import AVKit
import MediaPlayer

public enum AudioType: Int, CaseIterable {
    case mp3, m4a, wav, m4r, caf, aiff, aifc, aac, flac, mp4
    
    var typeExport: AVFileType {
        switch self {
        case .m4a:
            return .m4a
        case .caf:
            return .caf
        default:
            return .mp4
        }
    }
    
    var nameExport: String {
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
    
    var presentName: String {
        switch self {
        case .m4a:
            return AVAssetExportPresetAppleM4A
        case .caf:
            return AVAssetExportPresetPassthrough
        default:
            return AVAssetExportPresetLowQuality
            
        }
    }
    
    //Export 9
    var defaultExport: String {
        return ".m4a"
    }
    
    var nameUrl: String {
        return "\(self)"
    }
}
