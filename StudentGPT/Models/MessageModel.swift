//
//  MessageModel.swift
//  StudentGPT
//
//  Created by Kacper on 24/01/2025.
//

import Foundation

struct Message: Identifiable {
    var id = UUID()
    var text: String
    var isUser: Bool
}
