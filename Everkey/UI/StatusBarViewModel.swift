import SwiftUI

class StatusBarViewModel: ObservableObject {
    @Published var isVietnamese: Bool = true

    var onToggleVietnamese: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    func toggleVietnamese() { onToggleVietnamese?() }
    func openSettings() { onOpenSettings?() }
    func quit() { onQuit?() }
}
