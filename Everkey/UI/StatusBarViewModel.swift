import SwiftUI
import EverkeyEngine

class StatusBarViewModel: ObservableObject {
    @Published var isVietnamese: Bool = true
    @Published var inputMethod: InputMethod = .telex
    @Published var spellCheckEnabled: Bool = true

    var onToggleVietnamese: (() -> Void)?
    var onInputMethodChanged: ((InputMethod) -> Void)?
    var onSpellCheckChanged: ((Bool) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    func toggleVietnamese() { onToggleVietnamese?() }
    func selectInputMethod(_ method: InputMethod) { onInputMethodChanged?(method) }
    func toggleSpellCheck() { onSpellCheckChanged?(!spellCheckEnabled) }
    func openSettings() { onOpenSettings?() }
    func quit() { onQuit?() }
}
