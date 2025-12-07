import SwiftUI

struct PollCreationView: View {
    @Binding var question: String
    @Binding var options: [String]
    @Binding var allowMultiple: Bool
    @Binding var closesAt: Date?

    let onAddOption: () -> Void
    let onRemoveOption: (_ index: Int) -> Void
    let onCancel: () -> Void
    let onCreate: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextField("Pose ta question…", text: $question)
                }

                Section(header: Text("Options")) {
                    ForEach(options.indices, id: \.self) { index in
                        HStack {
                            TextField("Option \(index + 1)", text: Binding(
                                get: { options[index] },
                                set: { options[index] = $0 }
                            ))
                            if options.count > 2 {
                                Button(role: .destructive) {
                                    onRemoveOption(index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                            }
                        }
                    }

                    Button {
                        onAddOption()
                    } label: {
                        Label("Ajouter une option", systemImage: "plus.circle")
                    }
                }

                Section {
                    Toggle("Plusieurs réponses possibles", isOn: $allowMultiple)
                }

                Section(header: Text("Expiration")) {
                    Picker("Expiration", selection: Binding(get: {
                        closesAt == nil ? 0 : 1
                    }, set: { newVal in
                        if newVal == 0 {
                            closesAt = nil
                        } else {
                            closesAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        }
                    })) {
                        Text("Aucune").tag(0)
                        Text("24h").tag(1)
                    }
                }
            }
            .navigationTitle("Nouveau sondage")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Envoyer") {
                        onCreate()
                        dismiss()
                    }
                }
            }
        }
    }
}

