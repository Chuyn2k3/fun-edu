import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    excludeDatabaseFromBackup()
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.ibme.funedu/security",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "excludeDbFromBackup" {
          self?.excludeDatabaseFromBackup()
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Excludes local app data directories and SQLite files from iCloud/iTunes backup
  /// (NSURLIsExcludedFromBackupKey).
  private func excludeDatabaseFromBackup() {
    let fm = FileManager.default
    let dirs: [FileManager.SearchPathDirectory] = [.applicationSupportDirectory, .documentDirectory]
    for dir in dirs {
      guard let base = fm.urls(for: dir, in: .userDomainMask).first else { continue }
      try? fm.createDirectory(at: base, withIntermediateDirectories: true)
      if dir == .applicationSupportDirectory {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = base
        try? url.setResourceValues(values)
      } else if let items = try? fm.contentsOfDirectory(at: base, includingPropertiesForKeys: nil) {
        for item in items where item.lastPathComponent.hasPrefix("funedu.sqlite") {
          var values = URLResourceValues()
          values.isExcludedFromBackup = true
          var url = item
          try? url.setResourceValues(values)
        }
      }
    }
  }
}
