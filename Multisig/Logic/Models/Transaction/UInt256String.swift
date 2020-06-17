//
//  UInt256String.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct UInt256String: Hashable, Decodable {
    let value: UInt256

    init<T>(_ value: T) where T: BinaryInteger {
        self.value = UInt256(value)
    }

    init(_ value: UInt256) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if string.hasPrefix("0x") {
                let data = Data(hex: string)
                value = UInt256(data)
            } else if let uint256 = UInt256(string) {
                value = uint256
            } else {
                let context = DecodingError.Context.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not convert String \(string) to UInt256")
                throw DecodingError.valueNotFound(UInt256.self, context)
            }
        } else if let uint = try? container.decode(UInt.self) {
            value = UInt256(uint)
        } else {
            let context = DecodingError.Context.init(
                codingPath: decoder.codingPath,
                debugDescription: "Could not convert value to UInt256")
            throw DecodingError.valueNotFound(UInt256.self, context)
        }
    }
}

extension UInt256String: CustomStringConvertible {
    var description: String {
        String(value)
    }
}
