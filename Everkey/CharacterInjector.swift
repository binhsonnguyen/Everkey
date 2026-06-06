import CoreGraphics
import Foundation

class CharacterInjector {
    func inject(backspaceCount: Int, text: String, proxy: CGEventTapProxy, mode: InjectionMode = .fast) {
        guard let source = CGEventSource(stateID: .privateState) else { return }
        let delays = mode.delays

        if mode == .addressBar && backspaceCount > 0 {
            sendInvisibleChar(source: source, proxy: proxy)
            sendBackspaces(count: backspaceCount + 1, source: source, proxy: proxy, delay: 0)
        } else {
            sendBackspaces(count: backspaceCount, source: source, proxy: proxy, delay: delays.backspace)
            if backspaceCount > 0 && delays.wait > 0 { usleep(delays.wait) }
        }

        sendUnicodeText(text, source: source, proxy: proxy, delay: delays.text, oneByOne: mode.usesOneByOne)
    }

    // MARK: - Autocomplete Workaround

    private func sendInvisibleChar(source: CGEventSource, proxy: CGEventTapProxy) {
        var char: UniChar = 0x202F // Narrow No-Break Space — breaks browser autocomplete
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return }

        down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        down.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
        up.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
        down.tapPostEvent(proxy)
        up.tapPostEvent(proxy)
    }

    // MARK: - Backspace

    private func sendBackspaces(count: Int, source: CGEventSource, proxy: CGEventTapProxy, delay: UInt32) {
        let backspaceKeyCode: CGKeyCode = 0x33

        for _ in 0..<count {
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: backspaceKeyCode, keyDown: false)
            else { continue }

            down.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
            up.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
            down.tapPostEvent(proxy)
            up.tapPostEvent(proxy)
            if delay > 0 { usleep(delay) }
        }
    }

    // MARK: - Unicode Text

    private func sendUnicodeText(_ text: String, source: CGEventSource, proxy: CGEventTapProxy, delay: UInt32, oneByOne: Bool) {
        guard !text.isEmpty else { return }
        let utf16 = Array(text.utf16)

        if oneByOne {
            for var char in utf16 {
                guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                      let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
                else { continue }

                down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
                up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
                down.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
                up.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
                down.tapPostEvent(proxy)
                up.tapPostEvent(proxy)
                if delay > 0 { usleep(delay) }
            }
        } else {
            let chunkSize = 20
            var offset = 0

            while offset < utf16.count {
                let end = min(offset + chunkSize, utf16.count)
                var chunk = Array(utf16[offset..<end])

                guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                      let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
                else { break }

                down.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
                up.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
                down.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
                up.setIntegerValueField(.eventSourceUserData, value: kEverkeyEventMarker)
                down.tapPostEvent(proxy)
                up.tapPostEvent(proxy)

                offset = end
            }
        }
    }
}
