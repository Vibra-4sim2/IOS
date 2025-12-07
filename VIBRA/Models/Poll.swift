import Foundation

struct PollOption: Codable, Identifiable, Hashable {
    let optionId: String
    let text: String
    let votes: Int

    var id: String { optionId }
}

struct Poll: Codable, Identifiable, Hashable {
    let id: String
    let chatId: String
    let creatorId: String
    let question: String
    let options: [PollOption]
    let allowMultiple: Bool
    let closesAt: String?          // was Date?
    let closed: Bool
    let userVotedOptionIds: [String]
    let totalVotes: Int
    let createdAt: String?         // was Date
    let updatedAt: String?         // was Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId
        case creatorId
        case question
        case options
        case allowMultiple
        case closesAt
        case closed
        case userVotedOptionIds
        case totalVotes
        case createdAt
        case updatedAt
    }

    var isClosed: Bool {
        if closed { return true }
        if let closesDate, Date() > closesDate { return true }
        return false
    }

    func hasUserVoted(userId: String) -> Bool {
        return !userVotedOptionIds.isEmpty
    }

    func percentage(for option: PollOption) -> Double {
        guard totalVotes > 0 else { return 0 }
        return (Double(option.votes) / Double(totalVotes)) * 100.0
    }

    // Computed date helpers from ISO8601 strings
    var createdDate: Date? {
        guard let createdAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: createdAt)
    }

    var updatedDate: Date? {
        guard let updatedAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: updatedAt)
    }

    var closesDate: Date? {
        guard let closesAt else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: closesAt)
    }
}

struct PaginatedPollsResponse: Codable {
    let polls: [Poll]
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
}
