//
//  ContentView.swift
//  StudentGPT
//
//  Created by Kacper on 23/01/2025.
//

import Foundation
import SwiftUI
import OpenAI
import PhotosUI

struct ChatView: View {
    
    let openAI = OpenAI(apiToken: ProcessInfo.processInfo.environment["OPEN_AI_KEY"] ?? "")
    
    @State private var inputText: String = ""
    
    @State private var messages: [Message] = []
    
    @State private var currentThreadId: String = ""
    
    @State private var threadQuery = ThreadsQuery(messages: [])
    
    @State private var selectedImages: [UIImage] = []
    
    @State private var isShowingImagePicker = false
    
    
    
    
    var body: some View {
        VStack() {
            Spacer()
            
            // Chat stack
            VStack(){
                ScrollViewReader{ scrollViewProxy in
                    ScrollView{
                        VStack(){
                            // Display messages
                            ForEach(messages){ message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding()
                        // Scroll to newest message
                        .onChange(of: messages.count){
                            withAnimation{
                                scrollViewProxy.scrollTo(messages[messages.count - 1].id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Create new thread on appear
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
            
            // Stack for images
            HStack {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 65, height: 90)
                        .cornerRadius(12)
                        .clipped()
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Text box stack
            HStack(){
                // Image button
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .foregroundColor(Color.white)
                        .padding()
                        .font(.system(size: 20))
                }
                
                // Image picker
                .sheet(isPresented: $isShowingImagePicker) {
                    PHPickerViewControllerWrapper(selectedImages: $selectedImages)
                }
                
                // Text field
                TextField("Message...", text: $inputText)
                    .foregroundColor(.white)
                    .padding()
                    .padding(.horizontal, -20.0)
                
                // Send button
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
        do {
            // Add message to the chat thread
            if !inputText.isEmpty{
                let threadMessage = MessageQuery(role: .user, content: inputText)
                _ = try await withCheckedThrowingContinuation { continuation in
                    openAI.threadsAddMessage(threadId: currentThreadId, query: threadMessage) { result in
                        switch result {
                        case .success(let response):
                            continuation.resume(returning: response)
                            
                            // Add message to local messages
                            let userMessage = Message(type: .text ,text: inputText, isUser: true)
                            messages.append(userMessage)
                            inputText = ""
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            
            // Uploading images
            if !selectedImages.isEmpty{
                var tempImageArray: [UIImage] = []
                for imageArray in selectedImages {
                    if let image = imageArray.jpegData(compressionQuality: 1.0){
                        let fileQuery = FilesQuery(purpose: "vision", file: image, fileName: UUID().uuidString + ".png", contentType: "image/jpeg")
                        _ = try await withCheckedThrowingContinuation{ continuation in
                            openAI.files(query: fileQuery){ result in
                                switch result {
                                case .success(let response):
                                    continuation.resume(returning: response)
                                    
                                    // Add images to temp array
                                    tempImageArray.append(imageArray)
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                }
                            }
                        }
                    }
                }
                
                // Add images to local messages
                if !tempImageArray.isEmpty {
                    let userImages = Message(type: .image, images: selectedImages, isUser: true)
                    messages.append(userImages)
                    selectedImages = []
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
            
            // Wait for run to complete
            _ = try await withCheckedThrowingContinuation{ continuation in
                waitForRunCompletion(threadId: currentThreadId, runId: runResult.id) { result in
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
            
            // Add GPT response to local messages
            let gptResponseText = updatedMessagesResult.data.first?.content[0].text?.value ?? "Error"
            let gptRepsponseMessage = Message(type: .text ,text: gptResponseText, isUser: false)
            messages.append(gptRepsponseMessage)
            
        } catch (let error){
            print(error)
        }
    }
    
    func waitForRunCompletion(threadId: String, runId: String, completion: @escaping (Result<RunResult, Error>) -> Void) {
        let maxRetries = 60
        let retryInterval: TimeInterval = 1.0 // seconds
        var retries = 0
        
        func checkRunStatus() {
            openAI.runRetrieve(threadId: threadId, runId: runId) { result in
                switch result {
                case .success(let runDetails):
                    // Check success
                    if runDetails.status == .completed {
                        completion(.success(runDetails))
                    }
                    // Retry check
                    else if runDetails.status == .inProgress || runDetails.status == .queued{
                        if retries < maxRetries {
                            retries += 1
                            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                                checkRunStatus()
                            }
                        } else {
                            // To many tries
                            completion(.failure(NSError(domain: "RunTimeout", code: 408, userInfo: [NSLocalizedDescriptionKey: "Run did not complete within the maximum retry limit."])))
                        }
                    } else {
                        // Error catch
                        completion(.failure(NSError(domain: "RunError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected run status: \(runDetails.status)"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        checkRunStatus()
    }
}

struct PHPickerViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 5
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerViewControllerWrapper
        
        init(_ parent: PHPickerViewControllerWrapper) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            let group = DispatchGroup()
            var images: [UIImage] = []
            
            for result in results {
                group.enter()
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage {
                            images.append(image)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            // Replace images when adding again
            group.notify(queue: .main) {
                self.parent.selectedImages = images
            }
        }
    }
}

#Preview {
    ChatView()
}

