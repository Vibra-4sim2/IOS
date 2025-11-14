//
//  ProfileView.swift
//  VIBRA
//
//  Created by mac book pro on 11/9/25.
//

import SwiftUI

struct ProfileView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // MARK: - Profile Header
                        VStack(spacing: 12) {
                            if let avatar = user.avatar, !avatar.isEmpty {
                                AsyncImage(url: URL(string: avatar)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image("profile")
                                        .resizable()
                                }
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2)
                                )
                            } else {
                                Image("profile")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2)
                                    )
                            }
                            
                            Text("\(user.firstName) \(user.lastName)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(user.email)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            
                            NavigationLink(destination: ProfileUpdateView()) {
                                    HStack {
                                        Image(systemName: "square.and.pencil")
                                        Text("Edit Profile")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                                }
                            .padding(.top, 8)
                        }
                        .padding(.top, 40)
                        
                        // MARK: - Statistics Card (Statique pour l'instant)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Statistics")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.leading)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(icon: "figure.walk", title: "Distance", value: "2,547 km", change: "+125 km this month")
                                StatCard(icon: "clock.fill", title: "Time", value: "187 hours", change: "+8 hrs this month")
                                StatCard(icon: "mountain.2.fill", title: "Elevation", value: "28,650 m", change: "+1,000 m this month")
                                StatCard(icon: "flame.fill", title: "Calories", value: "78,345 kcal", change: "+3,400 kcal this month")
                            }
                            .padding()
                        }
                        .background(Color(red: 20/255, green: 20/255, blue: 20/255))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .task {
            await viewModel.fetchUser()
        }
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    var icon: String
    var title: String
    var value: String
    var change: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Text(title)
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            Text(value)
                .foregroundColor(.white)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(change)
                .font(.footnote)
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 28/255, green: 28/255, blue: 28/255))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
