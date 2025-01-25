//
//  ContentView.swift
//  StudentGPT
//
//  Created by Kacper on 23/01/2025.
//

import SwiftUI
import OpenAI

struct ChatView: View {
    
    let openAI = OpenAI(apiToken: ProcessInfo.processInfo.environment["OPEN_AI_KEY"] ?? "")
    
    @State private var inputText: String = ""
    
    @State private var messages: [Message] = []
    
    @State private var currentThreadId: String = ""
    
    @State private var threadQuery = ThreadsQuery(messages: [])
    
    
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
            .onAppear(){
                openAI.threads(query: threadQuery){ result in
                    switch result {
                    case .success(let threadResult):
                        // Access the 'id' from the result
                        currentThreadId = threadResult.id
                        
                    case .failure(let error):
                        // Handle the error
                        print("Error: \(error)")
                    }
                }}
            
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
                    Task{
                        await SendMessage()
                    }
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
    
    private func SendMessage() async {
        if !inputText.isEmpty {
            do {
                // Append the local user message
                let userMessage = Message(text: inputText, isUser: true)
                messages.append(userMessage)
                
                // Add message to the chat thread
                let threadMessage = MessageQuery(role: .user, content: inputText)
                let addMessageResult = try await withCheckedThrowingContinuation { continuation in
                    openAI.threadsAddMessage(threadId: currentThreadId, query: threadMessage) { result in
                        switch result {
                        case .success(let response):
                            continuation.resume(returning: response)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Create a run
                let runQuery = RunsQuery(assistantId: "asst_dwkAFBuK3xPLS8CgbvpdUR4y")
                let runResult = try await withCheckedThrowingContinuation { continuation in
                    openAI.runs(threadId: currentThreadId, query: runQuery) { result in
                        switch result {
                        case .success(let response):
                            continuation.resume(returning: response)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Fetch updated messages
                let updatedMessagesResult = try await withCheckedThrowingContinuation { continuation in
                    openAI.threadsMessages(threadId: currentThreadId) { result in
                        switch result {
                        case .success(let response):
                            continuation.resume(returning: response)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Clear the input text
                inputText = ""
            } catch{
                print("Error: Failed sending message to chat thread.")
            }
            
        }
    }
    

    
}


#Preview {
    ChatView()
}
