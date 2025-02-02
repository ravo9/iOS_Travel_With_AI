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
    @State private var showCamera = false
    @State private var capturedImageData: Data?
    @State private var permissionErrorMessage: String?
    @State private var locationInput: String = ""

    private let permissionManager = PermissionManager()
    
    @ObservedObject private var purchaseManager = PurchaseManager.shared

    var body: some View {
        if purchaseManager.isSubscribed {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ScreenTitle()
                        ImageCarousel(viewModel: viewModel)
                        LocationView(location: viewModel.locationText, locationInput: locationInput)
                            .onAppear{
                                requestPermission(for: .location, completion: {
                                    Task { do { try await viewModel.fetchCurrentLocation() } }
                                })
                            }
                        LocationInput(locationInputState: $locationInput)
                        ActionRow(buttons: [
                            ("Let's start, tell me where I am", {
                                if (!locationInput.isEmpty) {
                                    Task { await viewModel.sendPrompt(messageType: .initial, locationInput: locationInput) }
                                } else {
                                    requestPermission(for: .location, completion: {
                                        Task { await viewModel.sendPrompt(messageType: .initial) }
                                    })
                                }
                            }, Color.green)
                        ]).id("LetsStart")
                        ActionRow(buttons: [
                            ("History of this place", {
                                if (!locationInput.isEmpty) {
                                    Task { await viewModel.sendPrompt(messageType: .history, locationInput: locationInput) }
                                } else {
                                    requestPermission(for: .location, completion: {
                                        Task { await viewModel.sendPrompt(messageType: .history) }
                                    })
                                }
                            }, Color.green),
                            ("Restaurants nearby", {
                                if (!locationInput.isEmpty) {
                                    Task { await viewModel.sendPrompt(messageType: .restaurants, locationInput: locationInput) }
                                } else {
                                    requestPermission(for: .location, completion: {
                                        Task { await viewModel.sendPrompt(messageType: .restaurants) }
                                    })
                                }
                            }, Color.green)
                        ])
                        ActionRow(buttons: [
                            ("What attractions are worth-to-visit nearby", {
                                if (!locationInput.isEmpty) {
                                    Task { await viewModel.sendPrompt(messageType: .touristSpots, locationInput: locationInput) }
                                } else {
                                    requestPermission(for: .location, completion: {
                                        Task { await viewModel.sendPrompt(messageType: .touristSpots) }
                                    })
                                }
                            }, Color.green)
                        ])
                        ActionRow(buttons: [
                            ("What risks should I be aware of here?", {
                                if (!locationInput.isEmpty) {
                                    Task { await viewModel.sendPrompt(messageType: .safety, locationInput: locationInput) }
                                } else {
                                    requestPermission(for: .location, completion: {
                                        Task { await viewModel.sendPrompt(messageType: .safety) }
                                    })
                                }
                            }, firebrickRed)
                        ])
                        if let imageData = capturedImageData {
                            ImagePreview(imageData: imageData)
                                .transition(.opacity)
                        }
                        ActionRow(buttons: [
                            ("Take a picture - I will tell you what it is!", {
                                if (!locationInput.isEmpty) {
                                    requestPermission(for: .camera, completion: {
                                        showCamera = true
                                    })
                                } else {
                                    requestPermission(for: .location, completion: {
                                        requestPermission(for: .camera, completion: {
                                            showCamera = true
                                        })
                                    })
                                }
                            }, blue500)
                        ])
                        PromptInput(
                            locationInput: locationInput,
                            mainViewModel: viewModel,
                            onClick: { action in
                                // Todo
                                if (!locationInput.isEmpty) {
                                    action()
                                } else {
                                    requestPermission(for: .location, completion: {
                                        action()
                                    })
                                }
                            }
                        )
                        if viewModel.uiState == .loading {
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                                .id("BOTTOM")
                        } else {
                            OutputSection(viewModel: viewModel)
                        }
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
                .onChange(of: viewModel.uiState) { newState in
                    if newState == .loading {
                        withAnimation { proxy.scrollTo("BOTTOM", anchor: .bottom) }
                    }
                    if case .success(_) = newState {
                        withAnimation { proxy.scrollTo("LetsStart", anchor: .top) }
                    }
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
        } else {
            VStack(spacing: 8) {
                ScreenTitle()
                ImageCarousel(viewModel: viewModel)
                SubscriptionView()
            }
        }
    }
    
    private func requestPermission(for type: PermissionType, completion: @escaping () -> Void) {
        permissionManager.requestPermission(for: type) { granted in
            if granted {
                completion()
            } else {
                var errorMessage = "Permission denied for \(type). Please enable it in Settings."
                if (type == PermissionType.location) {
                    errorMessage = "Permission denied for \(type). Please enable it in Settings or provide the location manually."
                    viewModel.userDeniedLocation(errorMessage: errorMessage)
                }
                permissionErrorMessage = errorMessage
            }
        }
    }

    private func handleImageChange(_ newValue: Data?) {
        if let imageData = newValue {
            if (!locationInput.isEmpty) {
                Task { await viewModel.sendPrompt(messageType: .photo, photo: imageData, locationInput: locationInput) }
            } else {
                Task { await viewModel.sendPrompt(messageType: .photo, photo: imageData) }
            }
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

struct LocationView: View {
    var location: String
    var locationInput: String
    var body: some View {
        let textColor: Color = locationInput.isEmpty ? Color.primary : Color.gray
        VStack(alignment: .leading, spacing: 5) {
            Text("Your Location:")
                .font(.body)
                .foregroundColor(textColor)
            Text(location)
                .font(.subheadline)
                .foregroundColor(textColor)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .padding(.horizontal, 32)
    }
}

struct LocationInput: View {
    @Binding var locationInputState: String
    var body: some View {
        VStack(alignment: .leading) {
            Text("You can also provide another location:")
                .font(.body)
                .foregroundColor(Color.primary)
                .padding(.horizontal, 12)
            HStack {
                TextField("e.g. 'Rome, Italy' or 'London, Piccadilly'", text: $locationInputState)
                    .padding(20)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(locationInputState.isEmpty ? Color.gray : Color.green, lineWidth: 1)
                    )
                if !locationInputState.isEmpty {
                    Button(action: {
                        // Hide keyboard when clicked
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .padding(.trailing, 10)
                    }
                }
            }
        }
        .padding(20)
    }
}


struct ActionButton: View {
    var text: String
    var onClick: () -> Void
    var buttonColor: Color = Color.green
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

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {

                // For screenshots
//                let imageCompressed = UIImage(named: "london")?
//                let imageCompressed = UIImage(named: "bangkok")?
//                    .jpegData(compressionQuality: 0.8)

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
    var locationInput: String
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
                        if (!locationInput.isEmpty) {
                            Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt, locationInput: locationInput) }
                        } else {
                            Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt) }
                        }
                    })
                }

            ActionButton(
                text: "Go",
                onClick: {
                    onClick?({
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if (!locationInput.isEmpty) {
                            Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt, locationInput: locationInput) }
                        } else {
                            Task { await mainViewModel.sendPrompt(messageType: .custom, prompt: prompt) }
                        }
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
                .background(Color(UIColor.systemGray6))
                .background(Color(UIColor.white))
                .cornerRadius(12)
                .padding(.horizontal, 16)
        }
        .padding(.top, 16)
    }
}

struct SubscriptionView: View {
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @State private var isPurchasing = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Unlock full access with a subscription!")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding()

            if let product = purchaseManager.product {
                Button(action: {
                    isPurchasing = true
                    Task {
                        await purchaseManager.purchaseSubscription()
                        isPurchasing = false
                    }
                }) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Subscribe for \(product.displayPrice)/month")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isPurchasing)
                
                Text("Already subscribed? Tap the button to restore your subscription.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                ProgressView("Loading subscription...")
                    .padding()
            }

            if purchaseManager.isSubscribed {
                Text("You are subscribed!")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
        }
        .padding()
    }
}

#Preview {
    MainScreenView()
}
