//
//  ContentView.swift
//  StudentGPT
//
//  Created by Kacper on 23/01/2025.
//

import SwiftUI

struct ChatView: View {
    @State private var inputText: String = ""
    
    var body: some View {
        VStack() {
            Spacer()
            
            HStack(){
                Image(systemName: "plus.circle")
                    .foregroundColor(Color.white)
                    .padding([.top, .leading, .bottom], 10)
                    .padding(.trailing, 5)
                    .font(.system(size: 20))
                TextField("Message...", text: $inputText)
                    .foregroundColor(.white)
                    .padding(.trailing, 50)
                Image(systemName: "paperplane")
                    .foregroundColor(Color.white)
                    .padding(.vertical, 10)
                    .padding(.trailing, 20.0)
                    .padding(.leading, -40.0)
                    .font(.system(size: 20))
            }
            .frame(maxWidth: 350, maxHeight: 45, alignment: .leading)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    ChatView()
}
