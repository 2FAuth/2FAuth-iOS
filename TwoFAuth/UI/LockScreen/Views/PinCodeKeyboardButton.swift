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

final class PinCodeKeyboardButton: UIControl {
    var value: Int = 0 {
        didSet {
            numberLabel.text = "\(value)"
        }
    }

    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = subtitle == nil
        }
    }

    private var numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 36, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private var animator: UIViewPropertyAnimator?

    private let normalColor = UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 0.35)
    private let highlightedColor = UIColor(red: 229 / 255, green: 229 / 255, blue: 234 / 255, alpha: 0.75)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.width / 2
    }

    // MARK: Private

    private func setup() {
        backgroundColor = normalColor

        addTarget(self, action: #selector(touchDownAction), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(touchUpAction), for: [.touchUpInside, .touchDragExit, .touchCancel])

        let stackView = UIStackView(arrangedSubviews: [numberLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = -5
        stackView.axis = .vertical
        stackView.isUserInteractionEnabled = false
        addSubview(stackView)

        stackView.pin(horizontally: self)
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    @objc
    private func touchDownAction() {
        animator?.stopAnimation(true)
        backgroundColor = highlightedColor
    }

    @objc
    private func touchUpAction() {
        animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut, animations: {
            self.backgroundColor = self.normalColor
        })
        animator?.startAnimation()
    }
}
