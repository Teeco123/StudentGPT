//
//  ContentView.swift
//  StudentGPT
//
//  Created by Kacper on 23/01/2025.
//

import SwiftUI

struct ChatView: View {
    @State private var inputText: String = ""
    
    @State private var messages: [Message] = [
        Message(text: "Hello! Nigga!", isUser: true),
        Message(text: "Hello! How can I help you?", isUser: false)
    ]
    
    var body: some View {
        VStack() {
            Spacer()
            
            VStack(){
                ScrollViewReader{ scrollViewProxy in
                    ScrollView{
                        VStack(){
                            ForEach(messages){ message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding()
                        .onChange(of: messages.count){
                            withAnimation{
                                scrollViewProxy.scrollTo(messages[messages.count - 1].id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            HStack(){
                Image(systemName: "plus.circle")
                    .foregroundColor(Color.white)
                    .padding()
                    .padding(.trailing, -5.0)
                    .font(.system(size: 20))
                TextField("Message...", text: $inputText)
                    .foregroundColor(.white)
                    .padding()
                    .padding(.horizontal, -20.0)
                Button(action: {
                    SendMessage()
                }){
                    Image(systemName: "paperplane")
                        .foregroundColor(Color.white)
                        .padding()
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: 370, maxHeight: 45, alignment: .leading)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(18)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private func SendMessage(){
        if !inputText.isEmpty{
            let userMessage = Message(text: inputText, isUser: true)
            messages.append(userMessage)
            inputText = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let botMessage = Message(text: "You said: \(userMessage.text)", isUser: false)
                messages.append(botMessage)
            }
        }
    }
    
}


#Preview {
    ChatView()
}
