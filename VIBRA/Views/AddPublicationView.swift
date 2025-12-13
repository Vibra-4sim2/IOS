//
//  AddPublicationView.swift
//  VIBRA
//
//  Ajout : alerte de succès après publication, puis retour vers le Feed.
//  Created by mac book pro on 11/21/25.
//
import SwiftUI
import PhotosUI

private let BackgroundDark = Color(red: 0x0F/255, green: 0x0F/255, blue: 0x0F/255)
private let CardBackground = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255)
private let GreenAccent = Color(red: 0x4A/255, green: 0xDE/255, blue: 0x80/255)
private let TextPrimary = Color.white
private let TextSecondary = Color(red: 0x9C/255, green: 0xA3/255, blue: 0xAF/255)
private let RedAccent = Color(red: 0xEF/255, green: 0x44/255, blue: 0x44/255)

struct AddPublicationView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddPublicationViewModel()

    @State private var showTagSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSuccessAlert = false
    @State private var publishedId: String?

    var body: some View {
        ZStack {
            BackgroundDark.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerUser
                        contentField
                        imagePreview
                        selectedTagsView
                        actionsRow
                        publishButton
                        tipsCard
                    }
                    .padding(16)
                }
            }
        }
        .onReceive(viewModel.$uiState) { state in
            switch state {
            case .success(let id):
                publishedId = id
                showSuccessAlert = true
                // Si tu veux un retour automatique sans bouton OK, décommente ceci :
                /*
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    dismiss()
                }
                */
            default:
                break
            }
        }
        .sheet(isPresented: $showTagSheet) {
            TagSelectionSheet(
                initialTags: viewModel.selectedTags,
                onDone: { tags in
                    viewModel.setTags(tags)
                    showTagSheet = false
                },
                onCancel: { showTagSheet = false }
            )
            .presentationDetents([.medium, .large])
        }
        .overlay {
            if case .loading = viewModel.uiState {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("Publishing...")
                            .tint(GreenAccent)
                            .padding()
                            .background(CardBackground)
                            .cornerRadius(12)
                    )
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectImage(image)
                }
            }
        }
        .alert("Publication publiée", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss() // retour vers FeedView
            }
        } message: {
            Text("Votre publication a été ajoutée au feed.")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Helpers
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(TextPrimary)
            }
            Spacer()
            Text("New Post")
                .foregroundColor(TextPrimary)
                .font(.system(size: 18, weight: .bold))
            Spacer()
            Image(systemName: "xmark")
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(BackgroundDark)
    }

    private var headerUser: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(GreenAccent.opacity(0.3), lineWidth: 2)
                    .frame(width: 50, height: 50)

                Circle()
                    .fill(Color(red: 0x37/255, green: 0x41/255, blue: 0x51/255))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("YO") // TODO: initials utilisateur réelles
                            .foregroundColor(GreenAccent)
                            .font(.system(size: 16, weight: .bold))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Your Name") // TODO: nom réel
                    .foregroundColor(TextPrimary)
                    .font(.system(size: 16, weight: .bold))
                Text("Public post")
                    .foregroundColor(TextSecondary)
                    .font(.system(size: 13))
            }

            Spacer()
        }
        .padding(.bottom, 8)
    }

    private var contentField: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(CardBackground.opacity(0.6))
            VStack {
                TextEditor(text: $viewModel.content)
                    .foregroundColor(TextPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .padding(12)

                if viewModel.content.isEmpty {
                    Text("What's on your mind? Share your cycling journey...")
                        .foregroundColor(TextSecondary.opacity(0.6))
                        .font(.system(size: 15))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var imagePreview: some View {
        Group {
            if let img = viewModel.selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        viewModel.selectImage(nil)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(RedAccent)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(8)
                }
            }
        }
    }

    private var selectedTagsView: some View {
        Group {
            if !viewModel.selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags, id: \.self) { tag in
                            HStack(spacing: 6) {
                                Text("#\(tag)")
                                    .foregroundColor(GreenAccent)
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(GreenAccent)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(GreenAccent.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(GreenAccent.opacity(0.5), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .onTapGesture {
                                viewModel.removeTag(tag)
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionsRow: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                AddActionButton(systemImage: "photo", label: "Photo",
                                color: Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255))
            }
            Button { showTagSheet = true } label: {
                AddActionButton(systemImage: "tag", label: "Tag",
                                color: Color(red: 0xF5/255, green: 0x9E/255, blue: 0x0B/255))
            }
            AddActionButton(systemImage: "at", label: "Mention", color: GreenAccent)
            AddActionButton(systemImage: "location", label: "Location", color: RedAccent)
        }
    }

    private var publishButton: some View {
        let canPost = !viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Button {
            viewModel.publishPublication()
        } label: {
            HStack {
                Image(systemName: "paperplane.fill").foregroundColor(.white)
                Text("Publish on Feed")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .disabled(!canPost || isLoading)
        .background((!canPost || isLoading) ? GreenAccent.opacity(0.3) : GreenAccent)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        .padding(.top, 24)
    }

    private var isLoading: Bool {
        if case .loading = viewModel.uiState { return true }
        return false
    }

    private var tipsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb")
                .foregroundColor(Color(red: 0xFB/255, green: 0xBF/255, blue: 0x24/255))
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 4) {
                Text("Pro Tips")
                    .foregroundColor(TextPrimary)
                    .font(.system(size: 14, weight: .bold))
                Text("• Use hashtags to reach more cyclists\n• Add photos to make your post engaging")
                    .foregroundColor(TextSecondary)
                    .font(.system(size: 12))
                    .lineSpacing(4)
            }
        }
        .padding(14)
        .background(CardBackground.opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(16)
        .padding(.top, 16)
    }
}

// MARK: - Reusable components

struct AddActionButton: View {
    let systemImage: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(label)
                .foregroundColor(color)
                .font(.system(size: 11, weight: .medium))
        }
        .frame(width: 70, height: 70)
        .background(color.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct TagSelectionSheet: View {
    let initialTags: [String]
    let onDone: ([String]) -> Void
    let onCancel: () -> Void

    @State private var selectedTags: [String] = []
    private let availableTags = ["Cycling", "Training", "Mountains", "RoadBike", "Fitness", "Adventure"]

    var body: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    HStack {
                        Text("#\(tag)")
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark")
                                .foregroundColor(GreenAccent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedTags.contains(tag) {
                            selectedTags.removeAll { $0 == tag }
                        } else {
                            selectedTags.append(tag)
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone(selectedTags) }
                }
            }
            .onAppear { selectedTags = initialTags }
        }
    }
}

#Preview {
    AddPublicationView()
        .preferredColorScheme(.dark)
}
