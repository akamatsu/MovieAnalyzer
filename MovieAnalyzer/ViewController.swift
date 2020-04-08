//
//  ViewController.swift
//  MovieAnalyzer
//
//  Created by aka on 2020/03/13.
//  Copyright © 2020 aka. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    private var requests = [VNRequest]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
        processMovie()
    }

    func setupVision() {
        // 機械学習モデルを読み込む
        if let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodelc") {
            let mlModel = try! VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let mlRequest = VNCoreMLRequest(model: mlModel, completionHandler: { (request, error) in
                // 画像解析結果を処理する
                let results = request.results!
                print("Found \(results.count) objects")
                for item in results {
                    let object = item as! VNRecognizedObjectObservation
                    print("\(object.labels[0].identifier) \(object.confidence) \(object.boundingBox)")
                }
            })
            self.requests = [mlRequest]
        }
    }

    func processMovie() {
        // ムービーを読み込む
        let url = Bundle.main.url(forResource: "test", withExtension:"mov")
        let asset = AVURLAsset(url: url!, options: nil)
        let reader = try! AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: .video).first!
        let outputSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
        let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                        outputSettings: outputSettings)
        reader.add(trackReaderOutput)
        reader.startReading()

        // フレームごとに画像を読み込む
        while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() { // CMSampleBuffer
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) { // CVImageBuffer (CVPixelBuffer)
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
                // 画像の処理を実行する
                try! imageRequestHandler.perform(self.requests)
            }
        }
    }
}
