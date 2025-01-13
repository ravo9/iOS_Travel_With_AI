//
//  ContentView.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 12/01/2025.
//

import SwiftUI

struct MainScreenView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var outputText: String = "(My answers will appear here)"

    var body: some View {
        ScrollView {
            VStack {
                ScreenTitle()
                ImageCarousel(viewModel: viewModel)
                ActionButton(
                    text: "Let's start, tell me where I am",
                    onClick: {
                        Task { await viewModel.sendPrompt(messageType: .initial) }
                    }
                )
                Spacer()
                OutputSection(outputText: viewModel.outputText)
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.top)
        }
    }
}

struct ScreenTitle: View {
    var body: some View {
        Text("Travel with AI")
            .font(.system(size: 20, weight: .regular, design: .default))
            .kerning(0.5)
            .lineSpacing(8)
            .padding(.top, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .center)
            .textCase(.uppercase)
    }
}

struct ImageCarousel: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.getAIGeneratedImages(), id: \.self) { imageName in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(radius: 5)
                            .frame(width: 130, height: 130)
                        
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .clipped()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct ActionButton: View {
    var text: String
    var onClick: () -> Void
    var buttonColor: Color = Color.green // adjust
    var isEnabled: Bool = true
    var body: some View {
        Button(action: {
            onClick()
        }) {
            Text(text)
                .font(.system(size: 16))
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(buttonColor)
                .cornerRadius(30) // extract
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        }
        .disabled(!isEnabled)
    }
}

struct OutputSection: View {
    var outputText: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(outputText)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(Color(UIColor.systemGray6))
                .background(Color(UIColor.white))
                .cornerRadius(12)
                .padding(.horizontal, 16)
        }
        .padding(.top, 16)
    }
}

#Preview {
    MainScreenView()
}
