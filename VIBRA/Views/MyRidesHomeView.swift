import SwiftUI

struct MyRidesHomeView: View {
    @StateObject private var viewModel = MyRidesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Only show back button when pushed via NavigationLink (not when in TabBar)
    var showBackButton: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    searchBar
                    headerInfo

                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(AppColors.GreenAccent)
                                    .padding()
                                Text("Loading my rides...")
                                    .foregroundColor(AppColors.TextSecondary)
                                    .font(.caption)
                            } else if let error = viewModel.errorMessage {
                                errorStateView(error: error)
                            } else if viewModel.currentUserId == nil {
                                notLoggedInState
                            } else if viewModel.myItems.isEmpty {
                                emptyStateView
                            } else {
                                // Section des demandes de participation
                                if viewModel.totalPendingCount > 0 {
                                    pendingRequestsSection
                                }
                                
                                // Section de toutes mes sorties
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(AppColors.GreenAccent)
                                        Text("My Rides (\(viewModel.myItems.count))")
                                            .foregroundColor(AppColors.TextPrimary)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    
                                    ForEach(viewModel.myItems, id: \.ride.id) { item in
                                        NavigationLink(
                                            destination: SortieDetailView(ride: item.ride, creator: item.creator)
                                        ) {
                                            RideCardView(item: item)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                        .refreshable {
                            await viewModel.load()
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    // MARK: - Pending Requests Section
    
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(AppColors.GreenAccent)
                Text("Requests (\(viewModel.totalPendingCount))")
                    .foregroundColor(AppColors.TextPrimary)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // List of rides with pending requests
            ForEach(ridesWithPendingRequests, id: \.ride.id) { item in
                NavigationLink(destination: PendingParticipantsView(
                    ride: item.ride,
                    viewModel: viewModel
                )) {
                    pendingRideRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var ridesWithPendingRequests: [RideWithCreator] {
        viewModel.myItems.filter { item in
            guard let rideId = item.ride.id else { return false }
            return !viewModel.pendingParticipations(for: rideId).isEmpty
        }
    }
    
    private func pendingRideRow(item: RideWithCreator) -> some View {
        let pendingCount = viewModel.pendingParticipations(for: item.ride.id).count
        
        return HStack(spacing: 12) {
            // Ride image
            if let imageUrl = item.ride.photo, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.CardGlass)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.CardGlass)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.ride.type == "Vélo" ? "bicycle" : "figure.hiking")
                            .foregroundColor(AppColors.TextSecondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ride.titre)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.TextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.clock.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.GreenAccent)
                    Text("\(pendingCount) pending request\(pendingCount > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                }
            }
            
            Spacer()
            
            // Badge count + chevron
            HStack(spacing: 8) {
                Text("\(pendingCount)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.GreenAccent)
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppColors.TextSecondary)
            }
        }
        .padding(10)
        .background(AppColors.CardGlass)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.DividerColor, lineWidth: 0.6)
        )
    }
    
    // MARK: - Helpers
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.TextSecondary)

            TextField("Search in my rides...", text: $viewModel.searchText)
                .foregroundColor(AppColors.TextPrimary)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.TextSecondary.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.CardGlass)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.DividerColor, lineWidth: 0.8)
        )
        .shadow(color: AppColors.ShadowColor.opacity(0.8), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Header

    private var headerInfo: some View {
        HStack {
            // Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.GreenAccent)
                    .padding(10)
                    .background(AppColors.CardGlass)
                    .clipShape(Circle())
            }
            
            Text("My Rides")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.TextPrimary)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "bell")
                    .foregroundColor(AppColors.TextSecondary)
                Text("\(viewModel.totalPendingCount) pending")
                    .foregroundColor(AppColors.TextPrimary)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Error / Empty / Not logged

    @ViewBuilder
    private func errorStateView(error: String) -> some View { /* inchangé */
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Loading Error")
                .foregroundColor(.red)
                .font(.headline)
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(AppColors.GreenAccent)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .padding(.top, 40)
    }

    private var notLoggedInState: some View { /* inchangé */
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text("Not logged in")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text("Log in to see your own rides and participation requests.")
                .foregroundColor(AppColors.TextSecondary)
                .font(.caption)
        }
        .padding()
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .padding(.top, 40)
    }

    private var emptyStateView: some View { /* inchangé */
        VStack(spacing: 10) {
            Image(systemName: "tray.fill")
                .font(.largeTitle)
                .foregroundColor(AppColors.TextTertiary)
            Text("No rides created")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text("You haven't created any rides yet or none match your search.")
                .foregroundColor(AppColors.TextSecondary)
                .font(.caption)
        }
        .padding()
        .background(AppColors.CardDark.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .padding(.top, 40)
    }
}

#Preview {
    MyRidesHomeView()
        .preferredColorScheme(.dark)
}
