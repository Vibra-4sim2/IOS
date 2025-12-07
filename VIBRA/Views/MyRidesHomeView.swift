import SwiftUI

struct MyRidesHomeView: View {
    @StateObject private var viewModel = MyRidesViewModel()

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
                                Text("Chargement de mes sorties...")
                                    .foregroundColor(AppColors.TextSecondary)
                                    .font(.caption)
                            } else if let error = viewModel.errorMessage {
                                errorStateView(error: error)
                            } else if viewModel.currentUserId == nil {
                                notLoggedInState
                            } else if viewModel.myItems.isEmpty {
                                emptyStateView
                            } else {
                                if viewModel.totalPendingCount > 0 {
                                    HStack {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundColor(AppColors.GreenAccent)
                                        Text("\(viewModel.totalPendingCount) demande(s) de participation en attente")
                                            .foregroundColor(AppColors.TextPrimary)
                                            .font(.caption)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(AppColors.CardDark.opacity(0.9))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.BorderColor, lineWidth: 0.6)
                                    )
                                }

                                ForEach(viewModel.myItems, id: \.ride.id) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        ZStack(alignment: .topTrailing) {
                                            NavigationLink(
                                                destination: SortieDetailView(ride: item.ride, creator: item.creator)
                                            ) {
                                                RideCardView(item: item)
                                                    .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)

                                            if let rideId = item.ride.id {
                                                let pending = viewModel.pendingParticipations(for: rideId)
                                                if !pending.isEmpty {
                                                    Text("\(pending.count)")
                                                        .font(.caption2.weight(.bold))
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(AppColors.GreenAccent)
                                                        .cornerRadius(10)
                                                        .padding(8)
                                                }
                                            }
                                        }

                                        if let rideId = item.ride.id {
                                            let pending = viewModel.pendingParticipations(for: rideId)
                                            if !pending.isEmpty {
                                                pendingSection(pending, rideId: rideId, for: item.ride)
                                            }
                                        }
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
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.TextSecondary)

            TextField("Rechercher dans mes sorties...", text: $viewModel.searchText)
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
            Text("Mes sorties")
                .font(.headline.weight(.semibold))
                .foregroundColor(AppColors.TextPrimary)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "bell")
                    .foregroundColor(AppColors.TextSecondary)
                Text("\(viewModel.totalPendingCount) en attente")
                    .foregroundColor(AppColors.TextPrimary)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Section participations

    @ViewBuilder
    private func pendingSection(_ participations: [Participation], rideId: String, for ride: Ride) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(AppColors.GreenAccent)
                Text("\(participations.count) participation(s) en attente")
                    .foregroundColor(AppColors.TextPrimary)
                    .font(.caption)
                Spacer()
            }

            ForEach(participations) { p in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Demande de participation")
                            .foregroundColor(AppColors.TextPrimary)
                            .font(.caption.weight(.semibold))

                        if let email = p.user?.email {
                            Text(email)
                                .foregroundColor(AppColors.TextSecondary)
                                .font(.caption2)
                        } else if let userId = p.user?.id {
                            Text("userId: \(userId)")
                                .foregroundColor(AppColors.TextSecondary)
                                .font(.caption2)
                        }
                    }
                    Spacer()

                    // BOUTONS REFUSER + ACCEPTER
                    HStack(spacing: 8) {
                        // BOUTON REFUSER
                        Button {
                            Task {
                                await viewModel.refuseParticipation(p, forRideId: rideId)
                                // ou si tu n'as qu'une fonction générique :
                                // await viewModel.updateParticipation(p, to: "REFUSEE", forRideId: rideId)
                            }
                        } label: {
                            Text("Refuser")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        // BOUTON ACCEPTER
                        Button {
                            Task {
                                await viewModel.acceptParticipation(p, forRideId: rideId)
                                // ou :
                                // await viewModel.updateParticipation(p, to: "ACCEPTEE", forRideId: rideId)
                            }
                        } label: {
                            Text("Accepter")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.GreenAccent)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(8)
                .background(AppColors.CardDark.opacity(0.9))
                .cornerRadius(10)
            }
        }
        .padding(8)
        .background(AppColors.CardGlass.opacity(0.9))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
    }

    // MARK: - Error / Empty / Not logged

    @ViewBuilder
    private func errorStateView(error: String) -> some View { /* inchangé */
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Erreur de chargement")
                .foregroundColor(.red)
                .font(.headline)
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Réessayer")
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
            Text("Non connecté")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text("Connecte-toi pour voir tes propres sorties et les demandes de participation.")
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
            Text("Aucune sortie créée")
                .foregroundColor(AppColors.TextPrimary)
                .font(.headline)
            Text("Tu n'as pas encore créé de sortie ou aucune ne correspond à ta recherche.")
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
