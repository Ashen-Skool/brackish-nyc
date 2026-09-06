import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import Brackish

final class RecognitionEvaluationTests:XCTestCase {
    struct Fixture:Decodable {let file:String;let expected:String;let taxon:String}
    struct Row:Codable {let file:String;let expected:String;let taxon:String;let suitable:Bool;let candidates:[String];let similarities:[Float];let seconds:Double}
    func testRealImageCorpus() async throws {
        let bundle=Bundle(for:Self.self)
        let url=try XCTUnwrap(bundle.url(forResource:"manifest",withExtension:"json",subdirectory:"model-evaluation"))
        let fixtures=try JSONDecoder().decode([Fixture].self,from:Data(contentsOf:url))
        XCTAssertEqual(fixtures.count,36)
        let recognizer=FishRecognizer()
        var rows:[Row]=[]
        for fixture in fixtures {
            let imageURL=url.deletingLastPathComponent().appendingPathComponent(fixture.file)
            let result=try await recognizer.analyze(data:Data(contentsOf:imageURL))
            rows.append(Row(file:fixture.file,expected:fixture.expected,taxon:fixture.taxon,suitable:result.suitable,candidates:result.candidates.map(\.id),similarities:result.candidates.map(\.similarity),seconds:result.elapsed))
        }
        let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        let data=try encoder.encode(rows)
        let attachment=XCTAttachment(data:data,uniformTypeIdentifier:UTType.json.identifier);attachment.name="recognition-evaluation.json";attachment.lifetime = .keepAlways;add(attachment)
        let path=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("recognition-evaluation.json")
        try data.write(to:path)
        let known=rows.filter{$0.expected != "other-fish" && $0.expected != "no-fish"}
        print("BRACKISH_MODEL_EVAL known=\(known.count) top1=\(known.filter{$0.candidates.first == $0.expected}.count) top3=\(known.filter{$0.candidates.contains($0.expected)}.count) rejected=\(known.filter{!$0.suitable}.count)")
        print("BRACKISH_MODEL_EVAL negatives=\(rows.count-known.count) rejected=\(rows.filter{($0.expected == "other-fish" || $0.expected == "no-fish") && !$0.suitable}.count)")
    }
    func testSanitizationRemovesGPSAndOrientationMetadata() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let renderer=UIGraphicsImageRenderer(size:CGSize(width:128,height:96),format:format)
        let image=renderer.image {ctx in UIColor.green.setFill();ctx.fill(CGRect(x:0,y:0,width:128,height:96))}
        let source=NSMutableData()
        let destination=try XCTUnwrap(CGImageDestinationCreateWithData(source,UTType.jpeg.identifier as CFString,1,nil))
        CGImageDestinationAddImage(destination,image.cgImage!,[kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:40.7128,kCGImagePropertyGPSLatitudeRef:"N",kCGImagePropertyGPSLongitude:74.006,kCGImagePropertyGPSLongitudeRef:"W"],kCGImagePropertyOrientation:6] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let clean=try FishRecognizer.sanitizedPhoto(source as Data)
        let decoded=try XCTUnwrap(CGImageSourceCreateWithData(clean as CFData,nil))
        let props=CGImageSourceCopyPropertiesAtIndex(decoded,0,nil)! as NSDictionary
        XCTAssertNil(props[kCGImagePropertyGPSDictionary]);XCTAssertEqual((props[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,96)
        XCTAssertEqual((props[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,128)
    }
}
