//
//  MessageBubble.swift
//  StudentGPT
//
//  Created by Kacper on 24/01/2025.
//

import SwiftUI

struct MessageBubble: View{
    let message: Message
    
    var body: some View{
        HStack {
            if message.isUser {
                Spacer() // Push the message to the right if it's a user message
            }
            
            Text(message.text)
                .padding(10)
                .background(message.isUser ? .gray : .black)
                .foregroundColor(message.isUser ? .white : .white)
                .cornerRadius(12)
                .frame(maxWidth: message.isUser ? 250 : .infinity, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer() // Push the message to the left if it's not a user message
            }
        }
    }
}
