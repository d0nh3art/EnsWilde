//
//  PairingFileParser.swift
//  EnsWilde
//
//  Created by YangJiii on 2/1/26.
//

import Foundation

enum PairingParseError: LocalizedError {
    case invalidPlist
    case missingUDID

    var errorDescription: String? {
        switch self {
        case .invalidPlist:
            return "Invalid pairing file (plist parse failed)."
        case .missingUDID:
            return "Pairing file does not contain UDID."
        }
    }
}

enum PairingFileParser {
    static func parseUDID(fromPlistText text: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw PairingParseError.invalidPlist
        }

        let obj = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dict = obj as? [String: Any] else {
            throw PairingParseError.invalidPlist
        }

        if let udid = dict["UDID"] as? String, !udid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return udid.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // fallback common keys (just in case)
        if let udid = dict["UniqueDeviceID"] as? String, !udid.isEmpty { return udid }
        if let udid = dict["DeviceID"] as? String, !udid.isEmpty { return udid }

        throw PairingParseError.missingUDID
    }
}
