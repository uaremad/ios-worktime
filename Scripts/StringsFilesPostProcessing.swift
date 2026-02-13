#!/usr/bin/swift

//
//  Copyright © 2022 - Borussia Dortmund GmbH & Co. KGaA. All rights reserved.
//

import Foundation

let fileManager = FileManager.default
let localizationsPathURL = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("module.localization/Resources/Localizations", isDirectory: true)
let enumerator = fileManager.enumerator(at: localizationsPathURL, includingPropertiesForKeys: nil)!

for case let url as URL in enumerator where url.pathExtension == "strings" {
    let oldString = try String(contentsOf: url, encoding: .utf16)
    var newString = oldString

    newString.replaceKeysWithNativeOnes()
    newString.replacePlaceholdersWithNativeOnes()
    newString.escapePercentageCharacter()
    newString.addNSBluetoothPeripheralUsageDescription()
    newString.changeLineEndings()
    newString.removeWhitespaces()
    newString.removeLeadingLineBreaks()
    newString.removeTrailingLineBreaks()

    guard newString != oldString else { continue }

    try newString.write(to: url, atomically: false, encoding: .utf8)
}

extension String {
    mutating func replaceKeysWithNativeOnes() {
        [
            "\"request_permission_description_location_services\"": "\"NSLocationWhenInUseUsageDescription\"",
            "\"request_permission_description_camera\"": "\"NSCameraUsageDescription\"",
            "\"request_permission_description_face_id\"": "\"NSFaceIDUsageDescription\"",
            "\"request_permission_description_bluetooth\"": "\"NSBluetoothAlwaysUsageDescription\"",
            "\"request_permission_description_microphone\"": "\"NSMicrophoneUsageDescription\"",
            "\"request_permission_description_speech_recognition\"": "\"NSSpeechRecognitionUsageDescription\""
        ]
        .forEach { self = replacingOccurrences(of: $0.key, with: $0.value) }
    }

    /// Find character sequences of the i18n format `%{something}`
    /// and replace them with the native placeholder format `%@`.
    mutating func replacePlaceholdersWithNativeOnes() {
        self = replacingOccurrences(of: #"%\{\S*\}"#, with: "%@", options: .regularExpression)
    }

    /// Find `%` characters that are **not** followed by `{` or `@`
    /// and replace the matched cases with `%%`.
    mutating func escapePercentageCharacter() {
        self = replacingOccurrences(of: #"%(?!\{|@)"#, with: "%%", options: .regularExpression)
    }

    mutating func addNSBluetoothPeripheralUsageDescription() {
        if contains("NSBluetoothAlwaysUsageDescription") {
            var rows = components(separatedBy: "\n")
            if let index = rows.firstIndex(where: { $0.contains("NSBluetoothAlwaysUsageDescription") }) {
                rows.insert(rows[index].replacingOccurrences(of: "NSBluetoothAlwaysUsageDescription", with: "NSBluetoothPeripheralUsageDescription"), at: index + 1)
            }
            self = rows.joined(separator: "\n")
        }
    }

    mutating func changeLineEndings() {
        self = replacingOccurrences(of: "\r", with: "\n")
    }

    mutating func removeWhitespaces() {
        self = replacingOccurrences(of: #" \";"#, with: "\";", options: .regularExpression)
    }

    mutating func removeLeadingLineBreaks() {
        self = replacingOccurrences(of: #" = \"\n"#, with: " = \"", options: .regularExpression)
    }

    mutating func removeTrailingLineBreaks() {
        self = replacingOccurrences(of: #"\n\";"#, with: "\";", options: .regularExpression)
    }
}
