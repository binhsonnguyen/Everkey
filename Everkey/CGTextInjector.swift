import CoreGraphics
import EverkeyEngine

class CGTextInjector: TextInjecting {
    private let charInjector = CharacterInjector()
    var currentProxy: CGEventTapProxy!

    func inject(backspaceCount: Int, text: String) {
        charInjector.inject(backspaceCount: backspaceCount, text: text, proxy: currentProxy)
    }
}
