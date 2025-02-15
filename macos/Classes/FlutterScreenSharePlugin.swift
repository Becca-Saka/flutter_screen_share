import FlutterMacOS
import ScreenCaptureKit
import CoreImage

public class FlutterScreenSharePlugin: NSObject, FlutterPlugin, SCStreamDelegate {
    private var streamOutput: FlutterEventSink?
    private var stream: SCStream?
    private var filter: SCContentFilter?
    private var display: SCDisplay?
    public static var instanceRef: FlutterScreenSharePlugin?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_screen_share", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "flutter_screen_share/stream", binaryMessenger: registrar.messenger)
        let instance = FlutterScreenSharePlugin()
        instanceRef = instance 
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
      
        Task {
            do {
                let content = try await SCShareableContent.current
                var chosenFilter: SCContentFilter?
                var configWidth: Int = 0
                var configHeight: Int = 0
                
                if let source = source, let type = source["type"] as? String {
                    if type == "display" {
                       
                        let maybeDisplayID: UInt32? = {
                            if let idInt = source["id"] as? Int { return UInt32(idInt) }
                            if let idUInt = source["id"] as? UInt32 { return idUInt }
                            return nil
                        }()
                        guard let displayID = maybeDisplayID,
                              let selectedDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
                            result(FlutterError(code: "NO_DISPLAY", message: "Selected display not found", details: nil))
                            return
                        }
                        self.display = selectedDisplay
                        
                        chosenFilter = SCContentFilter(display: selectedDisplay, excludingWindows: [])
                        configWidth = Int(selectedDisplay.width)
                        configHeight = Int(selectedDisplay.height)
                    }  else if type == "window" {

    let maybeWindowID: UInt32? = {
        if let idInt = source["id"] as? Int { return UInt32(idInt) }
        if let idUInt = source["id"] as? UInt32 { return idUInt }
        return nil
    }()
    guard let windowID = maybeWindowID,
          let selectedWindow = content.windows.first(where: { $0.windowID == windowID }) else {
        result(FlutterError(code: "NO_WINDOW", message: "Selected window not found", details: nil))
        return
    }
 
    chosenFilter = SCContentFilter(desktopIndependentWindow: selectedWindow)

    let windowFrame = selectedWindow.frame
    configWidth = Int(windowFrame.width)
    configHeight = Int(windowFrame.height)
} else {
                        result(FlutterError(code: "INVALID_SOURCE", message: "Invalid source type", details: nil))
                        return
                    }
                } else {
                 
                    guard let defaultDisplay = content.displays.first else {
                        result(FlutterError(code: "NO_DISPLAY", message: "No display found", details: nil))
                        return
                    }
                    self.display = defaultDisplay
                    chosenFilter = SCContentFilter(display: defaultDisplay, excludingWindows: [])
                    configWidth = Int(defaultDisplay.width)
                    configHeight = Int(defaultDisplay.height)
                }
                
                guard let validFilter = chosenFilter else {
                    result(FlutterError(code: "FILTER_ERROR", message: "Unable to create content filter", details: nil))
                    return
                }
                
                let config = SCStreamConfiguration()
                config.width = configWidth
                config.height = configHeight
                config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.queueDepth = 2
                config.scalesToFit = false

                
               
                let stream = SCStream(filter: validFilter, configuration: config, delegate: self)
                
               
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global())
                
               
                try await stream.startCapture()
                closeNotificationCenter()
                self.stream = stream
               
                result(nil)
            } catch {
               
                result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }
    func closeNotificationCenter() {
    let script = "tell application \"System Events\" to key code 53 using {command down, option down}"
    let appleScript = NSAppleScript(source: script)
    appleScript?.executeAndReturnError(nil)
}

    private func stopCapture(_ result: @escaping FlutterResult) {
        Task {
            do {
                if let stream = stream {
                    try await stream.stopCapture()
                    self.stream = nil
                    self.filter = nil
                    self.display = nil
                }
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

extension FlutterScreenSharePlugin: SCStreamOutput {
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
     
        guard type == .screen, let streamOutput = streamOutput else { return }
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let srcBytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        guard let srcData = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
        
        let destBytesPerRow = (width * 4 + 63) & ~63
        let dataSize = destBytesPerRow * height
        var rawData = Data(count: dataSize)
        
        rawData.withUnsafeMutableBytes { destPtr in
            for row in 0..<height {
                let srcRow = srcData.advanced(by: row * srcBytesPerRow)
                let destRow = destPtr.baseAddress!.advanced(by: row * destBytesPerRow)
                memcpy(destRow, srcRow, min(srcBytesPerRow, destBytesPerRow))
            }
        }
        
        DispatchQueue.main.async {
            streamOutput(FlutterStandardTypedData(bytes: rawData))
        }
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
