import CoreML
import UIKit
import ImageIO

// Scores are cosine similarities, NOT calibrated species probabilities.
enum CandidateRanker {
    static func rank(vector: [Float], prompts: [RecognitionPrompt], elapsed: TimeInterval) -> RecognitionResult {
        guard vector.count == 512, vector.allSatisfy({ $0.isFinite }) else {
            return RecognitionResult(candidates: [], suitable: false, message: "The photo could not be compared. Try another image.", elapsed: elapsed)
        }
        let norm = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        guard norm > 0 else { return RecognitionResult(candidates: [], suitable: false, message: "No usable image details. Try a clearer photograph.", elapsed: elapsed) }
        var scores: [String: [Float]] = [:]
        for prompt in prompts where prompt.vector.count == vector.count {
            let score = zip(vector, prompt.vector).reduce(Float(0)) { $0 + $1.0 * $1.1 } / norm
            scores[prompt.id, default: []].append(score)
        }
        var fishScores: [Candidate] = []
        for (id, values) in scores where id != "no-fish" && id != "other-fish" {
            let mean = values.reduce(Float(0), +) / Float(values.count)
            fishScores.append(Candidate(id: id, similarity: mean))
        }
        fishScores.sort { lhs, rhs in
            if lhs.similarity == rhs.similarity { return lhs.id < rhs.id }
            return lhs.similarity > rhs.similarity
        }
        let rejection = (scores["no-fish"] ?? []).max() ?? -1
        let other = (scores["other-fish"] ?? []).max() ?? -1
        guard let top = fishScores.first, top.similarity >= 0.20, top.similarity > rejection + 0.015, top.similarity > other - 0.005 else {
            return RecognitionResult(candidates: [], suitable: false, message: "Pip needs another look. This may be an unsuitable photo or a fish outside our twelve-species comparison set. Try a clear side view, or record it as unknown.", elapsed: elapsed)
        }
        let gap = fishScores.count > 1 ? top.similarity - fishScores[1].similarity : 0
        return RecognitionResult(candidates: Array(fishScores.prefix(3)), suitable: true, message: gap < 0.025 ? "Several fish look similar here. Compare the field marks before choosing; unknown is a good answer." : "A visual lead, ready for your eyes. Check the field marks before confirming a species.", elapsed: elapsed)
    }
}

actor FishRecognizer {
    private var model: MLModel?
    private var prompts: [RecognitionPrompt]?
    func analyze(data: Data) throws -> RecognitionResult {
        let start = Date()
        try Task.checkCancellation()
        if model == nil {
            guard let url = Bundle.main.url(forResource: "FishEncoder", withExtension: "mlmodelc") else { throw RecognitionError.modelMissing }
            let config = MLModelConfiguration(); config.computeUnits = .all
            model = try MLModel(contentsOf: url, configuration: config)
        }
        if prompts == nil { prompts = Catalog.read("recognition-prompts") }
        let tensor = try Self.tensor(data: data)
        try Task.checkCancellation()
        let input = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(multiArray: tensor)])
        guard let output = try model?.prediction(from: input).featureValue(for: "embedding")?.multiArrayValue else { throw RecognitionError.invalidImage }
        try Task.checkCancellation()
        return CandidateRanker.rank(vector: (0..<output.count).map { output[$0].floatValue }, prompts: prompts ?? [], elapsed: Date().timeIntervalSince(start))
    }
    static func tensor(data: Data) throws -> MLMultiArray {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 1600, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw RecognitionError.invalidImage }
        guard min(image.width, image.height) >= 64 else { throw RecognitionError.tooSmall }
        let side = min(image.width, image.height)
        let rect = CGRect(x: (image.width-side)/2, y: (image.height-side)/2, width: side, height: side)
        guard let crop = image.cropping(to: rect) else { throw RecognitionError.invalidImage }
        var pixels = [UInt8](repeating: 0, count: 224*224*4)
        guard let context = CGContext(data: &pixels, width: 224, height: 224, bitsPerComponent: 8, bytesPerRow: 224*4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw RecognitionError.invalidImage }
        context.interpolationQuality = .high
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 224, height: 224))
        let tensor = try MLMultiArray(shape: [1,3,224,224], dataType: .float32)
        let ptr = tensor.dataPointer.bindMemory(to: Float.self, capacity: tensor.count)
        // This Core ML export embeds CLIP mean/std normalization in its graph.
        // Its external input contract is RGB in [0, 1], not normalized pixels.
        for channel in 0..<3 { for i in 0..<(224*224) { ptr[channel*224*224+i] = Float(pixels[i*4+channel])/255 } }
        return tensor
    }
    static func sanitizedPhoto(_ data: Data) throws -> Data {
        // Decode/re-encode discards EXIF, GPS, original filename and other metadata.
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways:true, kCGImageSourceThumbnailMaxPixelSize:1600, kCGImageSourceCreateThumbnailWithTransform:true] as CFDictionary),
              let jpeg = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.86) else { throw RecognitionError.invalidImage }
        return jpeg
    }
    enum RecognitionError: LocalizedError {
        case modelMissing, invalidImage, tooSmall
        var errorDescription: String? {
            switch self {
            case .modelMissing: return "The comparison model is missing from this build. You can still record an unknown fish or choose a species manually."
            case .invalidImage: return "This image could not be read. Try another photo or record your catch without one."
            case .tooSmall: return "This photo is too small to compare. Try a clearer image at least 64 pixels on each side."
            }
        }
    }
}
