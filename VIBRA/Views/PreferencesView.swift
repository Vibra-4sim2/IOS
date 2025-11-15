//
//  AdventurePreferencesParentView.swift
//  VIBRA
//
import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else {
                    TabView(selection: $currentPage) {
                        CyclingView(preferences: $viewModel.preferences)
                            .tag(0)
                        HikingView(preferences: $viewModel.preferences)
                            .tag(1)
                        CampingView(preferences: $viewModel.preferences)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(maxHeight: 420)

                    Button(action: {
                        Task {
                            if currentPage < 2 {
                                withAnimation { currentPage += 1 }
                            } else {
                                await viewModel.savePreferences()
                            }
                        }
                    }) {
                        Text(currentPage < 2 ? "Next" : "Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }

                // Navigation automatique vers TabBarView après save
                NavigationLink(destination: TabBarView(), isActive: $viewModel.navigateToHome) {
                    EmptyView()
                }
                .opacity(0)
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadPreferences()
            }
            /*
            .alert(item: Binding(
                get: { viewModel.errorMessage.map { AlertWrapper(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { wrapper in
                Alert(title: Text("Error"), message: Text(wrapper.message), dismissButton: .default(Text("OK")))
            }
            */
        }
    }
}

// small helper to present optional message as Identifiable for .alert(item:)
private struct AlertWrapper: Identifiable {
    let id = UUID()
    let message: String
}
// MARK: - Preview
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .preferredColorScheme(.dark)
    }
}
