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
                ActionRow(buttons: [
                    ("Let's start, tell me where I am", { Task { await viewModel.sendPrompt(messageType: .initial) } }, Color.green)
                ])
                ActionRow(buttons: [
                    ("History of this place", { Task { await viewModel.sendPrompt(messageType: .history) } }, Color.green),
                    ("Restaurants nearby", { Task { await viewModel.sendPrompt(messageType: .restaurants) } }, Color.green)
                ])
                ActionRow(buttons: [
                    ("What attractions are worth-to-visit nearby", { Task { await viewModel.sendPrompt(messageType: .touristSpots) } }, Color.green)
                ])
                ActionRow(buttons: [
                    ("What risks should I be aware of here?", { Task { await viewModel.sendPrompt(messageType: .safety) } }, Color.red)
                ])
                ActionRow(buttons: [
                    ("Take a picture - I will tell you what it is!", { Task { await viewModel.sendPrompt(messageType: .photo) } }, Color.blue)
                ])
                PromptInput(mainViewModel: viewModel)
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
    var maxWidth: CGFloat = .infinity

    var body: some View {
        Button(action: {
            onClick()
        }) {
            Text(text)
                .font(.system(size: 16))
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: maxWidth, minHeight: 54)
                .padding(.horizontal, 20)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(buttonColor)
        .cornerRadius(50) // extract
    }
}

struct ActionRow: View {
    var buttons: [(text: String, action: () -> Void, buttonColor: Color)]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(buttons, id: \.text) { button in
                ActionButton(
                    text: button.text,
                    onClick: button.action,
                    buttonColor: button.buttonColor
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
}

struct PromptInput: View {
    @State private var prompt: String = ""
    var mainViewModel: MainViewModel
    
    var body: some View {
        HStack {
            TextField("Enter your prompt...", text: $prompt)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.leading, 16)
                .frame(maxHeight: 100)

            ActionButton(
                text: "Go",
                onClick: {
                    Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt) }
                },
                isEnabled: !prompt.isEmpty,
                maxWidth: 40.0
            )
            .padding(.trailing, 16)
        }
        .padding(.top, 10)
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
