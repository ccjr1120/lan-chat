import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowChannel: FlutterMethodChannel?
  private var appearanceObservation: NSKeyValueObservation?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    self.title = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "LAN Chat"
    let channel = FlutterMethodChannel(
      name: "lanchat/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setStyle" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self,
        let arguments = call.arguments as? [String: String],
        let title = arguments["title"],
        let theme = arguments["theme"]
      else {
        result(FlutterError(code: "invalid_arguments", message: "Expected title and theme", details: nil))
        return
      }
      self.title = title
      switch theme {
      case "light": self.appearance = NSAppearance(named: .aqua)
      case "dark": self.appearance = NSAppearance(named: .darkAqua)
      default: self.appearance = nil
      }
      self.updateBackground(for: self.effectiveAppearance)
      result(nil)
    }
    // Keep the native title and window controls, blending the title bar into
    // the Flutter background. A nil appearance inherits the system setting.
    self.appearance = nil
    self.titlebarAppearsTransparent = true
    appearanceObservation = observe(\.effectiveAppearance, options: [.initial, .new]) {
      [weak self] window, _ in
      self?.updateBackground(for: window.effectiveAppearance)
    }
  }

  private func updateBackground(for appearance: NSAppearance) {
    // Match AppColors.background in lib/ui/theme.dart.
    let dark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    self.backgroundColor = dark
      ? NSColor(srgbRed: 17 / 255.0, green: 21 / 255.0, blue: 28 / 255.0, alpha: 1)
      : NSColor(srgbRed: 247 / 255.0, green: 248 / 255.0, blue: 250 / 255.0, alpha: 1)
  }
}
