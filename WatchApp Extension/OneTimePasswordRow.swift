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

import WatchKit

final class OneTimePasswordRow: NSObject {
    @IBOutlet private var iconImage: WKInterfaceImage!
    @IBOutlet private var codeLabel: WKInterfaceLabel!
    @IBOutlet private var titleLabel: WKInterfaceLabel!
    @IBOutlet private var progressGroup: WKInterfaceGroup!

    var favIconFetcher: WatchFavIconFetcher?

    private var timer: Timer? {
        willSet {
            timer?.invalidate()
        }
    }

    func update(with oneTimePassword: OneTimePassword, progressModel: ProgressModel) {
        codeLabel.setText(oneTimePassword.code)
        let title = [oneTimePassword.account, oneTimePassword.issuer].joined(separator: ", ")
        titleLabel.setText(title)

        favIconFetcher?.fetchIcon(for: oneTimePassword.issuer, iconCompletion: { [weak self] image in
            guard let self = self else { return }
            self.iconImage.setImage(image)
        })

        updateProgress(progressModel: progressModel)

        let progressUpdateInterval: TimeInterval = 1
        let timer = Timer(timeInterval: progressUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateProgress(progressModel: progressModel)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func updateProgress(progressModel: ProgressModel) {
        let now = Date().timeIntervalSince(progressModel.startTime)
        let percent = 1.0 - CGFloat(now / progressModel.duration)
        progressGroup.setRelativeWidth(percent, withAdjustment: 0)
    }
}
