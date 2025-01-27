//
//  MessageBubble.swift
//  StudentGPT
//
//  Created by Kacper on 24/01/2025.
//

import SwiftUI
import LaTeXSwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer() // Push the message to the right if it's a user message
            }
            
            VStack() {
                if let text = message.text, !text.isEmpty {
                    LaTeX(text)
                        .padding()
                        .blockMode(.blockViews)
                        .background(message.isUser ? .gray : .black)
                        .foregroundColor(message.isUser ? .white : .white)
                        .cornerRadius(12)
                }
                
                //Grid for images in chat
                if let images = message.images, !images.isEmpty {
                    LazyHGrid(rows: [
                        GridItem(),
                        GridItem()
                    ]) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 65, height: 90)
                                .cornerRadius(12)
                                .clipped()
                        }
                    }
                }
            }
            .frame(maxWidth: message.isUser ? 250 : .infinity, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer() // Push the message to the left if it's not a user message
            }
        }
    }
}
