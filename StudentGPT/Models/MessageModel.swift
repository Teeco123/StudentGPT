//
//  MessageModel.swift
//  StudentGPT
//
//  Created by Kacper on 24/01/2025.
//

import Foundation
import PhotosUI

enum InputType {
    case text
    case image
}

struct Message: Identifiable {
    var id = UUID()
    var type: InputType
    var text: String?
    var image: UIImage?
    var isUser: Bool
}
