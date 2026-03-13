//
//  Item.swift
//  CtrlS
//
//  Created by Дима on 13.03.2026.
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
