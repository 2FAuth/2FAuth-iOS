//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Andrew Podkovyrin. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

protocol NumericPinFieldDelegate: AnyObject {
    func numericPinFieldWillFinishInput(_ pinField: NumericPinField)
    func numericPinFieldDidFinishInput(_ pinField: NumericPinField)
}

final class NumericPinField: UIView {
    enum PinDotStyle {
        case small
        case normal
    }

    var text: String { value.joined() }

    var option = PinOption.sixDigits {
        didSet {
            clear()

            switch option {
            case .fourDigits:
                dotLayers.first?.opacity = 0
                dotLayers.last?.opacity = 0
            case .sixDigits:
                dotLayers.first?.opacity = 1
                dotLayers.last?.opacity = 1
            case .alphanumeric:
                fatalError("NumericPinField can only be used with digit-pin option")
            }
        }
    }

    var inputEnabled = true

    weak var delegate: NumericPinFieldDelegate?

    private let dotStyle: PinDotStyle
    private var value = [String]()
    private let supportedCharacters = CharacterSet(charactersIn: "0123456789")
    private var dotLayers = [CAShapeLayer]()

    init(dotStyle: PinDotStyle) {
        self.dotStyle = dotStyle

        super.init(frame: .zero)

        isUserInteractionEnabled = false

        // hide any assistant items on the iPad
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []

        var x: CGFloat = 0
        let dotSize = dotStyle.size
        for _ in 0 ..< 6 {
            let dot = NumericPinField.dotLayer(dotStyle: dotStyle)
            dot.frame = CGRect(x: x, y: 0, width: dotSize, height: dotSize)
            layer.addSublayer(dot)
            dotLayers.append(dot)
            x += dotSize + NumericPinField.paddingBetweenDots
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let count: CGFloat = 6
        let dotSize = dotStyle.size
        let width = dotSize * count + NumericPinField.paddingBetweenDots * (count - 1)
        return CGSize(width: width, height: dotSize)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        dotLayers.forEach { layer in
            let color = dotStyle.color
            layer.strokeColor = color
            if layer.fillColor != UIColor.clear.cgColor {
                layer.fillColor = color
            }
        }
    }

    func clear() {
        value.removeAll()

        for dot in dotLayers.reversed() {
            dot.fillColor = UIColor.clear.cgColor
        }
    }

    // MARK: UIResponder

    private var _inputView: UIView?
    override var inputView: UIView? {
        get { _inputView }
        set { _inputView = newValue }
    }

    override var canBecomeFirstResponder: Bool { true }

    // MARK: UITextInputTraits

    // declaring `keyboardType` as computed propery doesn't work
    var keyboardType = UIKeyboardType.numberPad

    // MARK: Private

    private func isInputStringValid(_ string: String?) -> Bool {
        guard let string = string else {
            return false
        }

        guard string.count == 1 else {
            return false
        }

        return string.first?.isWholeNumber ?? false
    }
}

extension NumericPinField: UIKeyInput {
    var hasText: Bool { !value.isEmpty }

    func insertText(_ text: String) {
        guard inputEnabled else {
            return
        }

        guard isInputStringValid(text) else {
            return
        }

        let optionCount: Int
        switch option {
        case .fourDigits:
            optionCount = 4
        default:
            optionCount = 6
        }
        if value.count >= optionCount {
            return
        }

        value.append(text)

        var index = value.count - 1
        if option == .fourDigits {
            index += 1
        }

        let dot = dotLayers[index]
        dot.fillColor = dotStyle.color

        if value.count == optionCount {
            delegate?.numericPinFieldWillFinishInput(self)
            // after dot's animation
            let when = DispatchTime.now() + CATransaction.animationDuration()
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.delegate?.numericPinFieldDidFinishInput(self)
            }
        }
    }

    func deleteBackward() {
        guard inputEnabled else {
            return
        }

        let count = value.count
        // swiftlint:disable:next empty_count
        guard count > 0 else {
            return
        }

        value.removeLast()

        var index = count - 1
        if option == .fourDigits {
            index += 1
        }

        let dot = dotLayers[index]
        dot.fillColor = UIColor.clear.cgColor
    }
}

extension NumericPinField: UITextInput {
    // Since we don't need to support cursor and selection implementation of UITextInput is a dummy

    // swiftlint:disable unused_setter_value

    func replace(_ range: UITextRange, withText text: String) {}

    var selectedTextRange: UITextRange? {
        get { nil }
        set(selectedTextRange) {}
    }

    var markedTextRange: UITextRange? { return nil }

    var markedTextStyle: [NSAttributedString.Key: Any]? {
        get { nil }
        set(markedTextStyle) {}
    }

    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {}

    func unmarkText() {}

    var beginningOfDocument: UITextPosition { UITextPosition() }

    var endOfDocument: UITextPosition { UITextPosition() }

    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        nil
    }

    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        nil
    }

    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        nil
    }

    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        .orderedSame
    }

    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        0
    }

    var inputDelegate: UITextInputDelegate? {
        get { nil }
        set(inputDelegate) {}
    }

    var tokenizer: UITextInputTokenizer { UITextInputStringTokenizer(textInput: self) }

    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        nil
    }

    func characterRange(byExtending position: UITextPosition,
                        in direction: UITextLayoutDirection) -> UITextRange? {
        nil
    }

    func baseWritingDirection(for position: UITextPosition,
                              in direction: UITextStorageDirection) -> UITextWritingDirection {
        .natural
    }

    func setBaseWritingDirection(_ writingDirection: UITextWritingDirection, for range: UITextRange) {}

    func firstRect(for range: UITextRange) -> CGRect {
        .zero
    }

    func caretRect(for position: UITextPosition) -> CGRect {
        .zero
    }

    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        []
    }

    func closestPosition(to point: CGPoint) -> UITextPosition? {
        nil
    }

    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        nil
    }

    func characterRange(at point: CGPoint) -> UITextRange? {
        nil
    }

    func text(in range: UITextRange) -> String? {
        nil
    }

    // swiftlint:enable unused_setter_value
}

private extension NumericPinField {
    static let paddingBetweenDots: CGFloat = 24

    class func dotLayer(dotStyle: PinDotStyle) -> CAShapeLayer {
        let dot = CAShapeLayer()
        dot.strokeColor = dotStyle.color
        dot.lineWidth = 1
        dot.fillColor = UIColor.clear.cgColor
        dot.fillRule = CAShapeLayerFillRule.evenOdd
        let dotSize = dotStyle.size
        let rect = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
        let path = UIBezierPath(ovalIn: rect)
        dot.path = path.cgPath

        return dot
    }
}

private extension NumericPinField.PinDotStyle {
    var size: CGFloat {
        switch self {
        case .small:
            return 13
        case .normal:
            return 18
        }
    }

    var color: CGColor {
        switch self {
        case .small:
            return Styles.Colors.lightText.cgColor
        case .normal:
            return Styles.Colors.label.cgColor
        }
    }
}
