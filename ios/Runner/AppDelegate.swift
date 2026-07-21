import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let secureStorage = IotKeychainStorage()
  private var secureStorageChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      secureStorageChannel = FlutterMethodChannel(
        name: "org.vbspdng.msp/secure_storage",
        binaryMessenger: controller.binaryMessenger
      )
      secureStorageChannel?.setMethodCallHandler { [weak self] call, result in
        self?.handleSecureStorageCall(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleSecureStorageCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    do {
      guard let arguments = call.arguments as? [String: Any] else {
        throw IotKeychainStorageError.invalidArguments
      }

      switch call.method {
      case "writeAll":
        guard let rawValues = arguments["values"] as? [String: Any] else {
          throw IotKeychainStorageError.invalidArguments
        }
        var values = [String: String]()
        for (key, value) in rawValues {
          guard let stringValue = value as? String else {
            throw IotKeychainStorageError.invalidArguments
          }
          values[key] = stringValue
        }
        try secureStorage.writeAll(values)
        result(nil)
      case "readAll":
        guard let keys = arguments["keys"] as? [String] else {
          throw IotKeychainStorageError.invalidArguments
        }
        do {
          result(try secureStorage.readAll(keys))
        } catch {
          // Fail closed if a Keychain entry is corrupt or inaccessible.
          try? secureStorage.deleteAll(keys)
          result([String: String]())
        }
      case "deleteAll":
        guard let keys = arguments["keys"] as? [String] else {
          throw IotKeychainStorageError.invalidArguments
        }
        try secureStorage.deleteAll(keys)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(
        FlutterError(
          code: "SECURE_STORAGE_ERROR",
          message: "Secure storage operation failed",
          details: String(describing: error)
        )
      )
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("IOT APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

private enum IotKeychainStorageError: Error {
  case invalidArguments
  case keychain(OSStatus)
  case invalidEncoding
}

private final class IotKeychainStorage {
  private let service = "org.vbspdng.msp.secure-storage"
  private let legacyPrefix = "flutter."

  func writeAll(_ values: [String: String]) throws {
    do {
      for (key, value) in values {
        try write(value, forKey: key)
      }
    } catch {
      // Never leave a partially updated credential set.
      for key in values.keys {
        try? delete(key)
      }
      throw error
    }
  }

  func readAll(_ keys: [String]) throws -> [String: String] {
    try migrateLegacyValues(keys)
    var result = [String: String]()
    for key in keys {
      if let value = try read(key) {
        result[key] = value
      }
    }
    return result
  }

  func deleteAll(_ keys: [String]) throws {
    for key in keys {
      try delete(key)
      UserDefaults.standard.removeObject(forKey: legacyPrefix + key)
    }
  }

  private func migrateLegacyValues(_ keys: [String]) throws {
    var legacyValues = [String: String]()
    for key in keys {
      if try read(key) == nil,
        let value = UserDefaults.standard.string(forKey: legacyPrefix + key)
      {
        legacyValues[key] = value
      }
    }

    if !legacyValues.isEmpty {
      try writeAll(legacyValues)
    }

    for key in keys {
      if try read(key) != nil {
        UserDefaults.standard.removeObject(forKey: legacyPrefix + key)
      }
    }
  }

  private func write(_ value: String, forKey key: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw IotKeychainStorageError.invalidEncoding
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
    let update: [String: Any] = [kSecValueData as String: data]
    let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)

    if updateStatus == errSecSuccess {
      return
    }
    guard updateStatus == errSecItemNotFound else {
      throw IotKeychainStorageError.keychain(updateStatus)
    }

    var insert = query
    insert[kSecValueData as String] = data
    insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    let addStatus = SecItemAdd(insert as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw IotKeychainStorageError.keychain(addStatus)
    }
  }

  private func read(_ key: String) throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess, let data = item as? Data else {
      throw IotKeychainStorageError.keychain(status)
    }
    guard let value = String(data: data, encoding: .utf8) else {
      throw IotKeychainStorageError.invalidEncoding
    }
    return value
  }

  private func delete(_ key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw IotKeychainStorageError.keychain(status)
    }
  }
}
