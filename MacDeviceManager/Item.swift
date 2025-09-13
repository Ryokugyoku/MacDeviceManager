//
//  Item.swift
//  MacDeviceManager
//
//  Created by Maeda Mitsuhiro on 2025/09/13.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
