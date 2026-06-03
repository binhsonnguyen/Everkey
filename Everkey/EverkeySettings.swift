import Foundation
import Combine

private let kSettingsKey = "EverkeySettings"

class EverkeySettings: ObservableObject {
    static let shared = EverkeySettings()

    @Published var toggleHotkey: Hotkey = Hotkey(keyCode: 49, modifiers: [.control])  // Ctrl+Space
    @Published var undoEnabled: Bool = false
    @Published var undoHotkey: Hotkey? = nil        // nil = Escape

    private var cancellables = Set<AnyCancellable>()

    private init() {
        load()
        Publishers.MergeMany(
            $toggleHotkey.map { _ in () }.eraseToAnyPublisher(),
            $undoEnabled.map { _ in () }.eraseToAnyPublisher(),
            $undoHotkey.map { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] in self?.save() }
        .store(in: &cancellables)
    }

    func save() {
        let data = Snapshot(
            toggleHotkey: toggleHotkey,
            undoEnabled: undoEnabled,
            undoHotkey: undoHotkey
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: kSettingsKey)
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: kSettingsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        toggleHotkey = snapshot.toggleHotkey
        undoEnabled = snapshot.undoEnabled
        undoHotkey = snapshot.undoHotkey
    }

    private struct Snapshot: Codable {
        var toggleHotkey: Hotkey
        var undoEnabled: Bool
        var undoHotkey: Hotkey?
    }
}
