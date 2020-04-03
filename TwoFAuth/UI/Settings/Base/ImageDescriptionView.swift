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

final class ImageDescriptionView: UIView {
    var image: UIImage? {
        get {
            iconImageView.image
        }
        set {
            iconImageView.image = newValue
        }
    }

    var descriptionText: String? {
        get {
            descriptionLabel.text
        }
        set {
            descriptionLabel.text = newValue
        }
    }

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = Styles.Colors.secondaryLabel
        imageView.contentMode = .center
        return imageView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = Styles.Colors.secondaryBackground
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Styles.Colors.secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = Styles.Colors.secondaryBackground

        addSubview(iconImageView)
        addSubview(descriptionLabel)

        iconImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required - 10, for: .vertical)
        descriptionLabel.setContentHuggingPriority(.defaultLow - 10, for: .vertical)

        let guide = layoutMarginsGuide
        let padding: CGFloat = 44.0

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            iconImageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: iconImageView.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor,
                                                  constant: Styles.Sizes.largePadding),
            descriptionLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: padding),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
