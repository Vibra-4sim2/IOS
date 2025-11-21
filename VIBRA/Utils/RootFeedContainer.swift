//
//  RootFeedContainer.swift
//  VIBRA
//
//  Created by mac book pro on 11/21/25.
//
import SwiftUI

struct RootFeedContainer: View {

    @State private var showAddPost = false

    var body: some View {
        NavigationStack {
            FeedView(
                onCreatePost: {
                    // Appelé depuis :
                    // - FeedHeaderView ("What's on your mind?")
                    // - EmptyStateView ("Create Post")
                    showAddPost = true
                },
                onOpenPost: { _ in
                    // TODO: plus tard, si tu veux un écran de détail de publication
                }
            )
            // Si tu veux cacher la barre nav ici aussi :
            // .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddPost) {
            AddPublicationView()
        }
    }
}
