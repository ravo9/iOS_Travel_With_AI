//
//  ContentView.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 12/01/2025.
//

import SwiftUI

struct MainScreenView: View {
    var body: some View {
        VStack {
            ScreenTitle()
            ImageCarousel(viewModel: MainViewModel())
            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.top)
    }
}

struct ScreenTitle: View {
    var body: some View {
        Text("Travel with AI")
            .font(.system(size: 18, weight: .regular, design: .default))
            .kerning(0.5)
            .lineSpacing(8)
            .padding(.top, 60)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .center)
            .textCase(.uppercase)
    }
}

struct ImageCarousel: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
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
        }
    }
}

#Preview {
    MainScreenView()
}
