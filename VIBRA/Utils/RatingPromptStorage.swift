//
//  RatingPromptStorage.swift
//  VIBRA
//

import Foundation

final class RatingPromptStorage {
    static let shared = RatingPromptStorage()

    private let skippedKey = "ratingPrompt.skippedSortieIds"

    private init() {}

    private var defaults: UserDefaults { .standard }

    func loadSkippedIds() -> Set<String> {
        let array = defaults.stringArray(forKey: skippedKey) ?? []
        return Set(array)
    }

    func saveSkippedIds(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: skippedKey)
    }

    func addSkippedId(_ id: String) {
        var set = loadSkippedIds()
        set.insert(id)
        saveSkippedIds(set)
    }

    func resetOnLogout() {
        defaults.removeObject(forKey: skippedKey)
    }
}
