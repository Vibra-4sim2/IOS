//
//  SortieRatingPromptView.swift
//  VIBRA
//

import SwiftUI

struct SortieRatingPromptView: View {
    @ObservedObject var viewModel: RatingPromptViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            if let sortie = viewModel.currentSortie {
                VStack(spacing: 16) {
                    Text("Note ta sortie")
                        .font(.title3.bold())
                        .foregroundColor(AppColors.TextPrimary)
                    Text("Comment était \"\(sortie.title)\" ?")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.TextSecondary)
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= viewModel.selectedStars ? "star.fill" : "star")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(AppColors.GreenAccent)
                                .onTapGesture {
                                    viewModel.selectStars(index)
                                }
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Commentaire (optionnel)")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                        TextEditor(text: $viewModel.comment)
                            .frame(height: 80)
                            .padding(6)
                            .background(AppColors.CardBackground)
                            .cornerRadius(8)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.skipCurrent()
                        }) {
                            Text("Plus tard")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.clear)
                                .foregroundColor(AppColors.TextSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.TextSecondary.opacity(0.4), lineWidth: 1)
                                )
                        }
                        Button(action: {
                            Task { await viewModel.submitCurrent() }
                        }) {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            } else {
                                Text("Envoyer")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                        }
                        .background(viewModel.selectedStars == 0 ? AppColors.GreenAccent.opacity(0.5) : AppColors.GreenAccent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(viewModel.selectedStars == 0 || viewModel.isSubmitting)
                    }
                }
                .padding(20)
                .background(AppColors.BackgroundDark)
                .cornerRadius(18)
                .padding(.horizontal, 32)
                .shadow(radius: 20)
            }
        }
        .animation(.easeInOut, value: viewModel.isPresenting)
    }
}
