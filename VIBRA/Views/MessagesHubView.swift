//
//  MessagesHubView.swift
//  VIBRA
//
//  Unified messaging view with two sections: Groups and Private
//

import SwiftUI

struct MessagesHubView: View {
    @State private var selectedSection: MessageSection = .private
    
    enum MessageSection: String, CaseIterable {
        case groups = "Groups"
        case `private` = "Private"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Section Picker
            Picker("Messages", selection: $selectedSection) {
                ForEach(MessageSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // MARK: - Content
            switch selectedSection {
            case .groups:
                ChatsListView()
            case .private:
                ConversationListView()
            }
        }
        .background(AppColors.BackgroundDark)
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MessagesHubView()
    }
    .preferredColorScheme(.dark)
}
