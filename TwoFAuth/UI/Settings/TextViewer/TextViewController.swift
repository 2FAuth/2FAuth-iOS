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

final class TextViewController: UIViewController {
    private let filename: String
    private let fileType: String

    init(filename: String, fileType: String) {
        self.filename = filename
        self.fileType = fileType
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = Styles.Colors.background
        textView.textContainerInset = UIEdgeInsets(top: Styles.Sizes.largePadding,
                                                   left: 0,
                                                   bottom: Styles.Sizes.largePadding,
                                                   right: Styles.Sizes.mediumPadding)
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = Styles.Colors.label
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = [.link]
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global(qos: .userInitiated).async {
            guard let filepath = Bundle.main.path(forResource: self.filename, ofType: self.fileType),
                let text = try? String(contentsOfFile: filepath) else {
                assert(false, "File \(self.filename).\(self.fileType) not found")
                return
            }

            DispatchQueue.main.async {
                self.textView.text = text
            }
        }

        view.backgroundColor = Styles.Colors.background

        view.addSubview(textView)
        textView.pin(edges: view.readableContentGuide)
    }
}
