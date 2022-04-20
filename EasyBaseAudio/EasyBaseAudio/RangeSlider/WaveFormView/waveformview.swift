//
//  waveformview.swift
//  Audio
//
//  Created by paxcreation on 3/30/21.
//

import UIKit
import Foundation
import AVFoundation
import Accelerate

public struct PointWave {
    let positionX: CGFloat
    let height: CGFloat
    let url: URL
}

public enum ViewSoundWave {
    case audio
    case showAudio
}

public enum WaveformStyle {
    case soundcloud
}

public class WaveformZoomable : UIView {
    
    //call back
    var listPoint: [CGFloat] = []
    var listPointOrigin: [CGPoint] = []
    var isLoading: Bool = false
    
    var listPointAudio: [CGFloat] = []
    var listPoinAudiotOrigin: [CGPoint] = []
    var isSelect: Bool = true
    var colorShow: UIColor = .red
    var colorDisappaer: UIColor = .gray
    
    private var listPointDraw: [CGFloat] = []
    private var url: URL?

    public var zoomFactor: Float = 1.0 {
        didSet {
            if zoomFactor > 1.0 {
                zoomFactor = 1.0
            }
            else if zoomFactor < 0.01 {
                zoomFactor = 0.01
            }
        }
    }
    
    public var style: WaveformStyle = .soundcloud {
        didSet {
            self.reload(zoomFactor: zoomFactor)
        }
    }
    
    struct readFile {
        static var floatValuesLeft = [Float]()
        static var floatValuesRight = [Float]()
        static var leftPoints = [CGPoint]()
        static var rightPoints = [CGPoint]()
        static var populated = false
    }
    
    let pixelWidth: CGFloat = 2.0
    let pixelSpacing: CGFloat = 2.0
    
    public convenience init(withFile: URL, style: WaveformStyle = .soundcloud, colorShow: UIColor, colorDisappaer: UIColor) {
        self.init()
        openFile(withFile)
        self.colorShow = colorShow
        self.colorDisappaer = colorDisappaer
        self.style = style
    }
    
    public func openFile(_ file: URL) {
        self.url = file
        var audioFile = AVAudioFile()
        do {
            audioFile = try AVAudioFile(forReading: file)
        }catch{
            return
        }
        
        // specify the format we WANT for the buffer
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount, interleaved: false)
        
        // initialize and fill the buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(audioFile.length))
        try! audioFile.read(into: buffer!)
        
        // copy buffer to readFile struct
        readFile.floatValuesLeft = Array(UnsafeBufferPointer(start: buffer?.floatChannelData?[0], count:Int(buffer!.frameLength)))
        
        readFile.populated = true
        
        reload(zoomFactor: zoomFactor)
    }
    
    public func reload(zoomFactor: Float = 1.0) {
        self.zoomFactor = zoomFactor
        setNeedsDisplay()
    }
    
    public func makePoints() {
        //        if !readFile.populated { return }
        
        let viewWidth = bounds.width
        
        let sampleCount = Int(Float(readFile.floatValuesLeft.count) * zoomFactor)
        //        print(sampleCount)
        
        // grab every nth sample (samplesPerPixel)
        let samplesPerPixel = Int(floor(Float(sampleCount) / Float(viewWidth)))
        //        print(samplesPerPixel)
        
        // the expected sample count
        let reducedSampleCount = sampleCount / samplesPerPixel
        //        print(reducedSampleCount)
        
        // left channel
        var processingBuffer = [Float](repeating: 0.0,
                                       count: sampleCount)
        
        // get absolute values
        vDSP_vabs(readFile.floatValuesLeft, 1, &processingBuffer, 1, vDSP_Length(sampleCount))
        
        // This is supposed to do what I'm doing below - using a sliding window to find maximums, but it was producing strange results
        // vDSP_vswmax(processingBuffer, samplePrecision, &maxSamplesBuffer, 1, newSampleCount, vDSP_Length(samplePrecision))
        
        // Instead, we use a for loop with a stride of length samplePrecision to specify a range of samples
        // This range is passed to our own maximumIn() method
        
        var maxSamplesBuffer = [Float](repeating: 0.0,
                                       count: reducedSampleCount)
        
        var offset = 0
        
        for i in stride(from: 0, to: sampleCount-samplesPerPixel, by: samplesPerPixel) {
            maxSamplesBuffer[offset] = maximumIn(processingBuffer, from: i, to: i+samplesPerPixel)
            offset = offset + 1
        }
        
        // Convert the maxSamplesBuffer values to CGPoints for drawing
        // We also normalize them for display here
        readFile.leftPoints = maxSamplesBuffer.enumerated().map({ (index, value) -> CGPoint in
            let normalized = normalizeForDisplay(value)
            let point = CGPoint(x: CGFloat(index), y: CGFloat(normalized))
            return point
        })
        
        // Interpolate points for smoother drawing
        for (index, point) in readFile.leftPoints.enumerated() {
            if index > 0 {
                let interpolatedPoint = CGPoint.lerp(start: readFile.leftPoints[index - 1], end: point, t: 0.5)
                readFile.leftPoints[index] = interpolatedPoint
            }
        }
        
    }
    
    public func listPointtoDraw(file: URL, colorShow: UIColor, colorDisappear: UIColor, viewSoundWave: ViewSoundWave, comlention: ((([PointWave]) -> Void)?) ) {
        self.isLoading = true
        self.colorShow = colorShow
        self.colorDisappaer = colorDisappear
        self.url = file
        var audioFile = AVAudioFile()
        do {
            audioFile = try AVAudioFile(forReading: file)
            
        }catch {
            self.isLoading = false
            return
        }
        
        // specify the format we WANT for the buffer
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioFile.fileFormat.sampleRate, channels: audioFile.fileFormat.channelCount, interleaved: false)
        
        // initialize and fill the buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(audioFile.length))
        try! audioFile.read(into: buffer!)
        
        // copy buffer to readFile struct
        readFile.floatValuesLeft = Array(UnsafeBufferPointer(start: buffer?.floatChannelData?[0], count:Int(buffer!.frameLength)))
        
        readFile.populated = true
        
        reload(zoomFactor: zoomFactor)
        
        //        if !readFile.populated { return }
        
        let viewWidth = bounds.width
        
        let sampleCount = Int(Float(readFile.floatValuesLeft.count) * zoomFactor)
        //        print(sampleCount)
        
        // grab every nth sample (samplesPerPixel)
        var  samplesPerPixel = Int(floor(Float(sampleCount) / Float(viewWidth)))
        //        print(samplesPerPixel)
        
        // the expected sample count
        if samplesPerPixel == 0 {
            samplesPerPixel = 1
        }
        let reducedSampleCount = sampleCount / samplesPerPixel
        //        print(reducedSampleCount)
        
        // left channel
        var processingBuffer = [Float](repeating: 0.0,
                                       count: sampleCount)
        
        // get absolute values
        vDSP_vabs(readFile.floatValuesLeft, 1, &processingBuffer, 1, vDSP_Length(sampleCount))
        
        // This is supposed to do what I'm doing below - using a sliding window to find maximums, but it was producing strange results
        // vDSP_vswmax(processingBuffer, samplePrecision, &maxSamplesBuffer, 1, newSampleCount, vDSP_Length(samplePrecision))
        
        // Instead, we use a for loop with a stride of length samplePrecision to specify a range of samples
        // This range is passed to our own maximumIn() method
        
        var maxSamplesBuffer = [Float](repeating: 0.0,
                                       count: reducedSampleCount)
        
        var offset = 0
        
        for i in stride(from: 0, to: sampleCount-samplesPerPixel, by: samplesPerPixel) {
            maxSamplesBuffer[offset] = maximumIn(processingBuffer, from: i, to: i+samplesPerPixel)
            offset = offset + 1
        }
        
        // Convert the maxSamplesBuffer values to CGPoints for drawing
        // We also normalize them for display here
        var listPont = maxSamplesBuffer.enumerated().map({ (index, value) -> CGPoint in
            let normalized = normalizeForDisplay(value)
            let point = CGPoint(x: CGFloat(index), y: CGFloat(normalized))
            return point
        })
        
        // Interpolate points for smoother drawing
        for (index, point) in listPont.enumerated() {
            if index > 0 {
                let interpolatedPoint = CGPoint.lerp(start: listPont[index - 1], end: point, t: 0.5)
                listPont[index] = interpolatedPoint
            }
        }
        
        backgroundColor = .clear
        
        switch style {
        case .soundcloud:
            self.drawSoundWaveCheck(self.frame, listPoint: listPont)
            
            //create listPoint for each elemt
//            self.fetchPoint(rect: self.frame, listPoint: listPont, viewSoundWave: viewSoundWave, comlention: (([PointWave]) -> Void)?)
            self.fetchPoint(rect: self.frame, listPoint: listPont, viewSoundWave: viewSoundWave) { list in
                comlention?(list)
            }
            break
        }
        
    }
    
    public func drawDetailedWaveform(_ rect: CGRect) {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0.0, y: rect.height/2))
        
        // left channel
        
        for point in readFile.leftPoints {
            let drawFrom = CGPoint(x: point.x, y: path.currentPoint.y)
            
            path.move(to: drawFrom)
            
            // bottom half
            let drawPointBottom = CGPoint(x: point.x, y: path.currentPoint.y + (point.y))
            path.addLine(to: drawPointBottom)
            
            path.close()
            
            // top half
            let drawPointTop = CGPoint(x: point.x, y: path.currentPoint.y - (point.y))
            path.addLine(to: drawPointTop)
            
            path.close()
        }
        
        UIColor.red.set()
        path.stroke()
        path.fill()
    
    }
    
    private func fetchPoint(rect: CGRect, listPoint: [CGPoint], viewSoundWave: ViewSoundWave,  comlention: ((([PointWave]) -> Void)?)) {
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0.0, y: rect.height/2))
        
        // left channel
        
        var index = 0
        
        //init point draw draft to one moment to self.listPoinDraw
        var listPointDrawDraft: [CGFloat] = []
        var listPointWave: [PointWave] = []
        while index < listPoint.count {
            let point = listPoint[index]
            
            let drawFrom = CGPoint(x: point.x, y: path.currentPoint.y)
            
            // bottom half
            path.move(to: drawFrom)
            
            let drawPointBottom = CGPoint(x: point.x, y: path.currentPoint.y + (point.y))
            path.addLine(to: drawPointBottom)
            path.addLine(to: CGPoint(x: drawPointBottom.x + pixelWidth, y: drawPointBottom.y))
            path.addLine(to: CGPoint(x: drawFrom.x + pixelWidth, y: drawFrom.y))
            
            path.close()
            
            // top half
            path.move(to: drawFrom)
            
            let drawPointTop = CGPoint(x: point.x, y: path.currentPoint.y - (point.y))
            path.addLine(to: drawPointTop)
            path.addLine(to: CGPoint(x: drawPointTop.x + pixelWidth, y: drawPointTop.y))
            path.addLine(to: CGPoint(x: drawFrom.x + pixelWidth, y: drawFrom.y))
            
            path.close()
            
            listPointDrawDraft.append(listPoint[index].x)
            let h = drawPointBottom.y - drawPointTop.y
            
            if let url = self.url {
                listPointWave.append(PointWave(positionX: point.x, height: h, url: url))
            }
            
            // increment index
            index = index + Int(pixelWidth) + Int(pixelSpacing)
        }
        
        switch viewSoundWave {
        case .audio:
            self.listPoint = listPointDrawDraft
            self.listPointOrigin = listPoint
        case .showAudio:
            self.listPointAudio = listPointDrawDraft
            self.listPoinAudiotOrigin = listPoint
        }
        self.isLoading = false
        comlention?(listPointWave)
    }
    
    private func drawSound(rect: CGRect, colorPath: UIColor?, listPoint: [CGPoint]) {
        
        let fillLayer = CAShapeLayer()
        
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0.0, y: rect.height/2))
        
        // left channel
        
        var index = 0
        
        //init point draw draft to one moment to self.listPoinDraw
        var listPointDrawDraft: [CGFloat] = []
        
        while index < listPoint.count {
            let point = listPoint[index]
            
            let drawFrom = CGPoint(x: point.x, y: path.currentPoint.y)
            
            // bottom half
            path.move(to: drawFrom)
            
            let drawPointBottom = CGPoint(x: point.x, y: path.currentPoint.y + (point.y))
            path.addLine(to: drawPointBottom)
            path.addLine(to: CGPoint(x: drawPointBottom.x + pixelWidth, y: drawPointBottom.y))
            path.addLine(to: CGPoint(x: drawFrom.x + pixelWidth, y: drawFrom.y))
            
            path.close()
            
            // top half
            path.move(to: drawFrom)
            
            let drawPointTop = CGPoint(x: point.x, y: path.currentPoint.y - (point.y))
            path.addLine(to: drawPointTop)
            path.addLine(to: CGPoint(x: drawPointTop.x + pixelWidth, y: drawPointTop.y))
            path.addLine(to: CGPoint(x: drawFrom.x + pixelWidth, y: drawFrom.y))
            
            path.close()
            
            listPointDrawDraft.append(listPoint[index].x)
            
            // increment index
            index = index + Int(pixelWidth) + Int(pixelSpacing)
        }
        
        //add point in list point to compare min x & max x
        //check list empty
        if self.listPointDraw == [] {
            self.listPointDraw = listPointDrawDraft
        }
        
        //color sound
        //        self.colorSound.set()
        //        path.stroke()
        //        path.fill()
        
        fillLayer.path = path.cgPath
        fillLayer.fillColor = colorPath?.cgColor
        
        path.fill()
        path.stroke()
        self.layer.addSublayer(fillLayer)
    }
    
    public func hideOrShowPath(isHidden: Bool) {
        guard let subplayers = self.layer.sublayers else {
            return
        }
        
        for sublayer in subplayers where sublayer is CAShapeLayer {
            sublayer.isHidden = isHidden
        }
    }
    
//    func changeColor(state: ShowAllAudio.StateSelectAudio) {
//        guard let subplayers = self.layer.sublayers else {
//            return
//        }
//
//        for sublayer in subplayers where sublayer is CAShapeLayer {
//            guard let fillLayer = sublayer as? CAShapeLayer else { return }
//
//            switch state {
//            case .select:
//                fillLayer.fillColor = UIColor(named: "dodgerBlue1")?.cgColor
//            default:
//                fillLayer.fillColor = UIColor(named: "lightGreyBlue")?.cgColor
//            }
//        }
//
//    }
    
    public func removePath() {
        guard let subplayers = self.layer.sublayers else {
            return
        }
        
        for sublayer in subplayers where sublayer is CAShapeLayer {
            sublayer.removeFromSuperlayer()
        }
    }
    
    public func drawSoundWave(_ rect: CGRect) {
        self.drawSound(rect: rect, colorPath: self.colorShow, listPoint: readFile.leftPoints)
        
        //remove dot black on device
        self.drawSound(rect: rect, colorPath: self.colorDisappaer, listPoint: readFile.leftPoints)
        self.drawSound(rect: rect, colorPath: self.colorShow, listPoint: readFile.leftPoints)
    }
    
    public func drawSoundWaveCheck(_ rect: CGRect, listPoint: [CGPoint]) {
        if self.isSelect {
            self.drawSound(rect: rect, colorPath: self.colorShow, listPoint: listPoint)
            
            //remove dot black on device
//            self.drawSound(rect: rect, colorPath: UIColor(named: "lightGreyBlue"), listPoint: listPoint)
//            self.drawSound(rect: rect, colorPath: UIColor(named: "dodgerBlue1"), listPoint: listPoint)
        } else {
            self.drawSound(rect: rect, colorPath: self.colorShow, listPoint: listPoint)
            
            //remove dot black on device
//            self.drawSound(rect: rect, colorPath: UIColor(named: "lightGreyBlue"), listPoint: listPoint)
//            self.drawSound(rect: rect, colorPath: UIColor(named: "lightGreyBlue"), listPoint: listPoint)
        }
    }
    
    public func updateSound(rect: CGRect, from: CGFloat, to: CGFloat) {
        self.drawRead(rect: rect, from: from, to: to)
    }
    
    public func drawReadUpdate(rect: CGRect, from: CGFloat, to: CGFloat, listPoint: [CGPoint], listPosition: [CGFloat]) {
        //find start & end point in list point draw
        var indexStartPointDraw: Int = 0
        var indexEndPointDraw: Int = 0

        for (index, item) in listPosition.enumerated() {
            if item - from >= 0 && item - from <= 5 {
                indexStartPointDraw = index
            }
            
            if item - to >= 0 && item - to <= 5 {
                indexEndPointDraw = index
            }
            
            if indexEndPointDraw == 0 && listPosition.last == item {
                indexEndPointDraw = index
            }
        }
    
        
        let list = listPoint.filter { (point) -> Bool in
//            print("======== \(point.x)")
            if point.x >= listPosition[indexStartPointDraw] && point.x <= listPosition[indexEndPointDraw] {
//                print("======== true")
                return true
            }
            return false
        }
        
        let listUnRedStart = listPoint.filter { (point) -> Bool in
            if point.x <= listPosition[indexStartPointDraw] {
                return true
            }
            return false
        }
        
        let listUnreadEnd = listPoint.filter { (point) -> Bool in
            if point.x >= listPosition[indexEndPointDraw] {
                return true
            }
            return false
        }
        
//        let setListPrevious = Set(WaveformZoomable.readFile.leftPoints)
//        let setCurrentList = Set(list)
//        let listOutput = Array(setListPrevious.subtracting(setCurrentList))
        
        self.drawSound(rect: rect, colorPath: self.colorShow, listPoint: list)
        self.drawSound(rect: rect, colorPath: self.colorDisappaer, listPoint: listUnRedStart)
        self.drawSound(rect: rect, colorPath: self.colorDisappaer, listPoint: listUnreadEnd)
    }
    
    private func drawRead(rect: CGRect, from: CGFloat, to: CGFloat) {
        //find start & end point in list point draw
        var indexStartPointDraw: Int = 0
        var indexEndPointDraw: Int = 0

        for (index, item) in self.listPointDraw.enumerated() {
            if item - from >= 0 && item - from <= 5 {
                indexStartPointDraw = index
            }
            
            if item - to >= 0 && item - to <= 5 {
                indexEndPointDraw = index
            }
        }
        
        let list = readFile.leftPoints.filter { (point) -> Bool in
            if point.x >= self.listPointDraw[indexStartPointDraw] && point.x <= self.listPointDraw[indexEndPointDraw] {
                return true
            }
            return false
        }
        
        let listUnRedStart = readFile.leftPoints.filter { (point) -> Bool in
            if point.x <= self.listPointDraw[indexStartPointDraw] {
                return true
            }
            return false
        }
        
        let listUnreadEnd = readFile.leftPoints.filter { (point) -> Bool in
            if point.x >= self.listPointDraw[indexEndPointDraw] {
                return true
            }
            return false
        }
        
//        let setListPrevious = Set(WaveformZoomable.readFile.leftPoints)
//        let setCurrentList = Set(list)
//        let listOutput = Array(setListPrevious.subtracting(setCurrentList))
        
        self.drawSound(rect: rect, colorPath: self.colorShow, listPoint: list)
        self.drawSound(rect: rect, colorPath: self.colorDisappaer, listPoint: listUnRedStart)
        self.drawSound(rect: rect, colorPath: self.colorDisappaer, listPoint: listUnreadEnd)
    }
    
    private func drawUnRead(rect: CGRect, from: CGFloat, to: CGFloat) {
        var indexStartPointDraw: Int = 0
        var indexEndPointDraw: Int = 0

        for (index, item) in self.listPointDraw.enumerated() {
            if item - from >= 0 && item - from <= 5 {
                indexStartPointDraw = index
            }
            
            if item - to >= 0 && item - to <= 5 {
                indexEndPointDraw = index
            }
        }
        
        let list = readFile.leftPoints.filter { (point) -> Bool in
            if point.x <= self.listPointDraw[indexStartPointDraw] || point.x >= self.listPointDraw[indexEndPointDraw] {
                return true
            }
            return false
        }
        
//        let setListPrevious = Set(self.listPreviousUnread)
//        let setCurrentList = Set(list)
//        let listOutput = Array(setCurrentList.subtracting(setListPrevious))
        
        self.drawSound(rect: rect, colorPath: self.colorDisappaer, listPoint: list)
    }
    
    override public func draw(_ rect: CGRect) {
//        makePoints()
//
        // this clears the rect
//        backgroundColor = .black
//
//        switch style {
//        case .soundcloud:
//            drawSoundWave(rect)
//            break
//        }
    }
}

extension CGPoint: Hashable {
//    static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
//        return lhs.x == rhs.x && lhs.y == rhs.y
//    }
    
    public func hash(into hasher: inout Hasher) {
        
    }
//    public var hashValue: Int {
//        return self.x.hashValue ^ self.y.hashValue
//    }
//
    static func < (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return true // FIX
    }

    static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return true // FIX
    }
}

public extension UIView {
    func normalizeForDisplay(_ value: Float) -> Float {
        let maxHeight = Float(bounds.height)
        let minHeight = Float(maxHeight / 2.0)
        let normalized = value * minHeight
        return normalized
    }
}
public extension UIView {
    
    func maximumIn(_ array: [Float], from: Int, to: Int) -> Float {
        var max: Float = -Float.infinity
        
        for index in from...to {
            if array[index] > max {
                max = array[index]
            }
        }
        
        return max
    }
}

public extension CGPoint {
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    static func lerp(start: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        return start + (end - start) * t
    }
}
