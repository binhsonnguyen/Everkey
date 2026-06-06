import CoreGraphics
import EverkeyEngine

class CGTextInjector: TextInjecting {
    private let charInjector = CharacterInjector()
    private let detector = AppBehaviorDetector.shared
    var currentProxy: CGEventTapProxy!

    func inject(backspaceCount: Int, text: String) {
        charInjector.inject(
            backspaceCount: backspaceCount,
            text: text,
            proxy: currentProxy,
            mode: detector.detectMode()
        )
    }
}
