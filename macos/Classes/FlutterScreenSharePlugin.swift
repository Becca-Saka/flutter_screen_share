import FlutterMacOS
import ScreenCaptureKit
import CoreImage
import Metal
import SDWebImage
import SDWebImageWebPCoder

public class FlutterScreenSharePlugin: NSObject, FlutterPlugin, SCStreamDelegate {
    private var streamOutput: FlutterEventSink?
    private var stream: SCStream?
    private var textureRegistry: FlutterTextureRegistry?
    private var textureId: Int64?
    private var metalDevice: MTLDevice?
    private var metalTexture: MTLTexture?
    private var ciContext: CIContext?
    
     private var lastFrameTime: CFTimeInterval = 0
     private var encodingType: String = "webp"
    private var frameInterval: CFTimeInterval = 1.0 / 24.0
    private var quality: Float = 0.8
    private let processingQueue = DispatchQueue(label: "com.screen.share.processing", qos: .userInteractive, attributes: .concurrent)
       private var frameCount: Int = 0 
        private let webpEncoder = SDImageWebPCoder.shared
    

    public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_screen_share", binaryMessenger: registrar.messenger)
    let eventChannel = FlutterEventChannel(name: "flutter_screen_share/stream", binaryMessenger: registrar.messenger)
    let instance = FlutterScreenSharePlugin()
    instance.textureRegistry = registrar.textures
    instance.metalDevice = MTLCreateSystemDefaultDevice()
    instance.ciContext = CIContext(mtlDevice: instance.metalDevice!)
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
}
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startCapture":
            startCapture(result, source: call.arguments as? [String: Any])
        case "stopCapture":
            stopCapture(result)
        case "getDisplays":
            getDisplays(result)
        case "getSources":
            getSources(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getOwnerName(for windowID: UInt32) -> String? {
        let options: CGWindowListOption = [.optionIncludingWindow]
        
        if let infoList = CGWindowListCopyWindowInfo(options, CGWindowID(windowID)) as? [[String: Any]],
           let info = infoList.first,
           let ownerName = info[kCGWindowOwnerName as String] as? String {
            return ownerName
        }
        return nil
    }
    
 private func startCapture(_ result: @escaping FlutterResult, source: [String: Any]?) {
 
    let sourceConfig = source?["source"] as? [String: Any]
    let encodingOptions = source?["options"] as? [String: Any] ?? [:]
    
    encodingType = encodingOptions["type"] as? String ?? "webp"
    let fps = encodingOptions["fps"] as? Int ?? 24
    frameInterval = 1.0 / Double(fps)
    quality = Float(encodingOptions["quality"] as? Double ?? 0.8)
    

    
    Task {
        do {
            let content = try await SCShareableContent.current
            var chosenFilter: SCContentFilter?
            var configWidth: Int = 0
            var configHeight: Int = 0
            
            if let sourceConfig = sourceConfig, let type = sourceConfig["type"] as? String {
                if type == "display" {
                    let maybeDisplayID: UInt32? = {
                        if let idInt = sourceConfig["id"] as? Int { return UInt32(idInt) }
                        if let idUInt = sourceConfig["id"] as? UInt32 { return idUInt }
                        return nil
                    }()
                    guard let displayID = maybeDisplayID,
                          let selectedDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
                        result(FlutterError(code: "NO_DISPLAY", message: "Selected display not found", details: nil))
                        return
                    }
                    chosenFilter = SCContentFilter(display: selectedDisplay, excludingWindows: [])
                    configWidth = Int(selectedDisplay.width)
                    configHeight = Int(selectedDisplay.height)
                } 
            } else {
           
                guard let defaultDisplay = content.displays.first else {
                    result(FlutterError(code: "NO_DISPLAY", message: "No display found", details: nil))
                    return
                }
                chosenFilter = SCContentFilter(display: defaultDisplay, excludingWindows: [])
                configWidth = Int(defaultDisplay.width)
                configHeight = Int(defaultDisplay.height)
            }

            
            let config = SCStreamConfiguration()
            config.width = configWidth
            config.height = configHeight
            config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.queueDepth = 8
            config.scalesToFit = false
            config.showsCursor = true
            
            guard let validFilter = chosenFilter else {
                result(FlutterError(code: "FILTER_ERROR", message: "Unable to create content filter", details: nil))
                return
            }
             let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: configWidth,
                height: configHeight,
                mipmapped: false
            )
            textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            textureDescriptor.storageMode = .shared
            metalTexture = metalDevice?.makeTexture(descriptor: textureDescriptor)
             textureId = textureRegistry?.register(self)
            
            print("Registered texture with ID: \(String(describing: textureId))")
            
            let stream = SCStream(filter: validFilter, configuration: config, delegate: self)
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global())
            try await stream.startCapture()
            self.stream = stream
            
            result(["textureId": textureId ?? -1])
        } catch {
            print("Capture error: \(error)")
            result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
        }
    }
}
    
    private func stopCapture(_ result: @escaping FlutterResult) {
        Task {
            do {
                if let stream = stream {
                    try await stream.stopCapture()
                    self.stream = nil
                }
                if let textureId = textureId {
                    textureRegistry?.unregisterTexture(textureId)
                    self.textureId = nil
                }
                metalTexture = nil
                result(nil)
            } catch {
                result(FlutterError(code: "STOP_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func getDisplays(_ result: @escaping FlutterResult) {
        Task {
            do {
                let content = try await SCShareableContent.current
                let displays = content.displays.map { [
                    "type": "display",
                    "id": $0.displayID,
                    "width": $0.width,
                    "height": $0.height,
                    "name": "Display \($0.displayID)"
                ] }
                result(displays)
            } catch {
                result(FlutterError(code: "DISPLAYS_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func getSources(_ result: @escaping FlutterResult) {
        Task {
            do {
                let content = try await SCShareableContent.current
                var sources: [[String: Any]] = []
                
                for display in content.displays {
                    sources.append([
                        "type": "display",
                        "id": display.displayID,
                        "width": display.width,
                        "height": display.height,
                        "name": "Display \(display.displayID)"
                    ])
                }
                
                for window in content.windows {
                    let ownerName = getOwnerName(for: window.windowID) ?? "Unknown App"
                    sources.append([
                        "type": "window",
                        "id": window.windowID,
                        "name": window.title ?? "Window \(window.windowID)",
                        "owner": ownerName,
                    ])
                }
                result(sources)
            } catch {
                result(FlutterError(code: "SOURCE_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    public func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async {
            self.streamOutput?(FlutterError(code: "STREAM_ERROR", message: error.localizedDescription, details: nil))
        }
    }
}

extension FlutterScreenSharePlugin: FlutterTexture {
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let texture = metalTexture else { return nil }
        
        var pixelBuffer: CVPixelBuffer?
        let pixelFormat = kCVPixelFormatType_32BGRA
        let width = texture.width
        let height = texture.height
        
        let attrs = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       width,
                                       height,
                                       pixelFormat,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, width, height)
        
        texture.getBytes(baseAddress,
                        bytesPerRow: bytesPerRow,
                        from: region,
                        mipmapLevel: 0)
        
        return Unmanaged.passRetained(pixelBuffer)
    }
}

extension FlutterScreenSharePlugin: SCStreamOutput { public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        let currentTime = CACurrentMediaTime()
        guard (currentTime - lastFrameTime) >= frameInterval else { return }
        lastFrameTime = currentTime
        
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
      
        if let texture = metalTexture {
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            let region = MTLRegionMake2D(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))
            texture.replace(region: region,
                          mipmapLevel: 0,
                          withBytes: CVPixelBufferGetBaseAddress(imageBuffer)!,
                          bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer))
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let textureId = self.textureId else { return }
                self.textureRegistry?.textureFrameAvailable(textureId)
            }
        }
        
 
        frameCount += 1
        guard frameCount % 2 == 0 else { return }
        

       processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let encodedData: Data?
            
            switch self.encodingType {
            case "jpeg":
                encodedData = self.encodeToJPEG(imageBuffer, quality: self.quality)
            case "webp":
                encodedData = self.encodeToWebP(imageBuffer, quality: self.quality)
            default:
                encodedData = nil
            }
            
            if let data = encodedData, let streamOutput = self.streamOutput {
                DispatchQueue.main.async {
                    streamOutput(FlutterStandardTypedData(bytes: data))
                }
            }
        }
    }
  private func encodeToJPEG(_ buffer: CVImageBuffer, quality: Float) -> Data? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        guard let cgImage = ciContext?.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
    
    private func encodeToWebP(_ buffer: CVImageBuffer, quality: Float) -> Data? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        guard let cgImage = ciContext?.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        let options: [SDImageCoderOption : Any] = [
            .encodeCompressionQuality: quality,
            .encodeWebPMethod: 0,
            .encodeWebPLossless: false,
            .encodeWebPPreprocessing: 0
        ]
        
        return webpEncoder.encodedData(with: nsImage, format: .webP, options: options)
    }

 
 }

extension FlutterScreenSharePlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        streamOutput = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        streamOutput = nil
        return nil
    }
}