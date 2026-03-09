//
//  Item.swift
//  SurVibe
//
//  Created by maheshwar kanitkar on 09/03/26.
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
