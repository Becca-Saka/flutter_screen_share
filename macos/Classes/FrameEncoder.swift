import Foundation
import CoreImage
import SDWebImage
import SDWebImageWebPCoder

class FrameEncoder {
    private let webpEncoder = SDImageWebPCoder.shared
    private let quality: Float
    private let ciContext: CIContext
    private let encodingType: String
    
    init(quality: Float = 0.8, ciContext: CIContext, encodingType: String = "webp") {
        self.quality = quality
        self.ciContext = ciContext
        self.encodingType = encodingType
    }
    
    func encode(_ buffer: CVImageBuffer) -> Data? {
        switch encodingType {
        case "jpeg":
            return encodeToJPEG(buffer)
        case "webp":
            return encodeToWebP(buffer)
        default:
            return nil
        }
    }
    
    private func encodeToJPEG(_ buffer: CVImageBuffer) -> Data? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
    
    private func encodeToWebP(_ buffer: CVImageBuffer) -> Data? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        let options: [SDImageCoderOption: Any] = [
            .encodeCompressionQuality: quality,
            .encodeWebPMethod: 0,
            .encodeWebPLossless: false,
            .encodeWebPPreprocessing: 0
        ]
        
        return webpEncoder.encodedData(with: nsImage, format: .webP, options: options)
    }
}