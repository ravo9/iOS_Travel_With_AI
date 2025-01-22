//
//  ContentView.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 12/01/2025.
//

import SwiftUI
import AVFoundation

let blue500 = Color(red: 0x21/255.0, green: 0x96/255.0, blue: 0xF3/255.0)
let firebrickRed = Color(red: 0xDB/255.0, green: 0x57/255.0, blue: 0x57/255.0)

struct MainScreenView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var outputText: String = "(My answers will appear here)"
    @State private var showCamera = false
    @State private var capturedImageData: Data?
    @State private var permissionErrorMessage: String?

    private let permissionManager = PermissionManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ScreenTitle()
                ImageCarousel(viewModel: viewModel)
                ActionRow(buttons: [
                    ("Let's start, tell me where I am", {
                        requestPermission(for: .location, completion: {
                            Task { await viewModel.sendPrompt(messageType: .initial) }
                        })
                    }, Color.green)
                ])
                ActionRow(buttons: [
                    ("History of this place", {
                        requestPermission(for: .location, completion: {
                            Task { await viewModel.sendPrompt(messageType: .history) }
                        })
                    }, Color.green),
                    ("Restaurants nearby", {
                        requestPermission(for: .location, completion: {
                            Task { await viewModel.sendPrompt(messageType: .restaurants) }
                        })
                    }, Color.green)
                ])
                ActionRow(buttons: [
                    ("What attractions are worth-to-visit nearby", {
                        requestPermission(for: .location, completion: {
                            Task { await viewModel.sendPrompt(messageType: .touristSpots) }
                        })
                    }, Color.green)
                ])
                ActionRow(buttons: [
                    ("What risks should I be aware of here?", {
                        requestPermission(for: .location, completion: {
                            Task { await viewModel.sendPrompt(messageType: .safety) }
                        })
                    }, firebrickRed)
                ])
                if let imageData = capturedImageData {
                    ImagePreview(imageData: imageData)
                        .transition(.opacity)
                }
                ActionRow(buttons: [
                    ("Take a picture - I will tell you what it is!", {
                        requestPermission(for: .location, completion: {
                            requestPermission(for: .camera, completion: {
                                showCamera = true
                            })
                        })
                    }, blue500)
                ])
                PromptInput(
                    mainViewModel: viewModel,
                    onClick: { action in
                        requestPermission(for: .location, completion: {
                            action()
                        })
                    }
                )
                OutputSection(viewModel: viewModel)
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.top)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(imageData: $capturedImageData)
        }
        .onChange(of: capturedImageData) { newValue in
            handleImageChange(newValue)
        }
        .alert(isPresented: Binding<Bool>(
            get: { permissionErrorMessage != nil },
            set: { if !$0 { permissionErrorMessage = nil } }
        )) {
            Alert(
                title: Text("Permission Required"),
                message: Text(permissionErrorMessage ?? ""),
                primaryButton: .default(Text("Go to Settings")) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                },
                secondaryButton: .cancel {
                    permissionErrorMessage = nil
                }
            )
        }
    }
    
    private func requestPermission(for type: PermissionType, completion: @escaping () -> Void) {
        permissionManager.requestPermission(for: type) { granted in
            if granted {
                completion()
            } else {
                permissionErrorMessage = "Permission denied for \(type). Please enable it in Settings."
            }
        }
    }

    private func handleImageChange(_ newValue: Data?) {
        if let imageData = newValue {
            Task { await viewModel.sendPrompt(messageType: .photo, photo: imageData) }
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
        .cornerRadius(50)
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

struct ImagePreview: View {
    var imageData: Data?
    var body: some View {
        VStack {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
            } else {
                Text("No Image Selected")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
            }
        }
        .padding()
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        #if targetEnvironment(simulator)
            picker.sourceType = .photoLibrary
        #else
            picker.sourceType = .camera
        #endif
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                let imageCompressed = image.jpegData(compressionQuality: 0.8)
                DispatchQueue.main.async {
                    if let imageCompressed = imageCompressed {
                        self.parent.imageData = nil
                        self.parent.imageData = imageCompressed
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PromptInput: View {
    @State private var prompt: String = ""
    var mainViewModel: MainViewModel
    var onClick: ((@escaping () -> Void) -> Void)?
    var body: some View {
        HStack {
            TextField("Feel free to ask me more!", text: $prompt)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .font(.system(size: 18))
                .padding(.leading, 18)
                .frame(minHeight: 60)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .onSubmit {
                    onClick?({
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt) }
                    })
                }

            ActionButton(
                text: "Go",
                onClick: {
                    onClick?({
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt) }
                    })
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
    @ObservedObject var viewModel: MainViewModel
    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.outputText)
                .font(.system(size: 18))
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
