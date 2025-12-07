import SwiftUI

struct PollMessageView: View {
    let message: ChatMessage
    let currentUserId: String?
    let onVote: (_ optionIds: [String]) -> Void
    let onClose: () -> Void
    let onShowVoters: (_ optionId: String) -> Void

    @State private var selectedOptionIds: Set<String> = []

    var body: some View {
        guard let poll = message.poll else {
            return AnyView(EmptyView())
        }
        
        return AnyView(content(for: poll))
    }

    private func content(for poll: Poll) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(poll.question)
                    .font(.headline)
                    .foregroundColor(AppColors.TextPrimary)
                Spacer()
                if poll.isClosed {
                    Label("Terminé", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(AppColors.TextSecondary)
                }
            }

            ForEach(poll.options) { option in
                optionRow(option: option, poll: poll)
            }
            
            // Submit button for multiple choice polls
            let hasVoted = !(poll.userVotedOptionIds.isEmpty)
            if poll.allowMultiple && !poll.isClosed {
                // Show button if user has selections OR if they want to change their vote
                if !selectedOptionIds.isEmpty || hasVoted {
                    Button(action: {
                        if !selectedOptionIds.isEmpty {
                            onVote(Array(selectedOptionIds))
                            selectedOptionIds.removeAll()
                        }
                    }) {
                        Text(hasVoted && selectedOptionIds.isEmpty ? "Modifier mon vote" : hasVoted ? "Changer mon vote" : "Voter")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedOptionIds.isEmpty && hasVoted ? AppColors.CardDark : AppColors.GreenAccent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedOptionIds.isEmpty && hasVoted)
                }
            }

            HStack {
                Text("\(poll.totalVotes) vote(s)")
                    .font(.caption2)
                    .foregroundColor(AppColors.TextSecondary)
                Spacer()
                if let currentUserId = currentUserId, poll.creatorId == currentUserId, !poll.isClosed {
                    Button(action: onClose) {
                        Label("Fermer", systemImage: "lock")
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private func optionRow(option: PollOption, poll: Poll) -> some View {
        let hasVoted = !(poll.userVotedOptionIds.isEmpty)
        
        // If user is modifying (selectedOptionIds is not empty), show selectedOptionIds
        // Otherwise, show the actual voted options
        let isSelected: Bool
        if !selectedOptionIds.isEmpty {
            isSelected = selectedOptionIds.contains(option.optionId)
        } else {
            isSelected = poll.userVotedOptionIds.contains(option.optionId)
        }
        
        let percent = poll.percentage(for: option)

        return Button {
            guard !poll.isClosed else { return }

            if poll.allowMultiple {
                // For multiple choice: toggle selection (allow changing vote)
                // If user is modifying vote and selectedOptionIds is empty, initialize with current votes
                if selectedOptionIds.isEmpty && hasVoted {
                    selectedOptionIds = Set(poll.userVotedOptionIds)
                }
                
                if selectedOptionIds.contains(option.optionId) {
                    selectedOptionIds.remove(option.optionId)
                } else {
                    selectedOptionIds.insert(option.optionId)
                }
            } else {
                // For single choice: vote immediately (allow changing vote)
                selectedOptionIds = [option.optionId]
                onVote([option.optionId])
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(option.text)
                        .font(.subheadline)
                        .foregroundColor(AppColors.TextPrimary)
                    Spacer()
                    Text(String(format: "%.0f%%", percent))
                        .font(.caption2)
                        .foregroundColor(AppColors.TextSecondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.CardGlass)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? AppColors.GreenAccent : AppColors.CardDark)
                            .frame(width: geometry.size.width * CGFloat(percent / 100.0), height: 8)
                    }
                }
                .frame(height: 8)

                Button {
                    onShowVoters(option.optionId)
                } label: {
                    Text("Voir les votants")
                        .font(.caption2)
                        .foregroundColor(AppColors.TextTertiary)
                }
            }
            .padding(8)
            .background(isSelected ? AppColors.CardDark.opacity(0.7) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
