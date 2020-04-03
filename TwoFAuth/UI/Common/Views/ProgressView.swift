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

final class ProgressView: UIView {
    var mainColor: UIColor = Styles.Colors.tint {
        didSet {
            updateStrokeColor()
        }
    }

    var lastQuaterColor: UIColor = Styles.Colors.red

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var model: ProgressModel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let lineWidth = Styles.Sizes.progressLineWidth

        backgroundLayer.fillColor = nil
        backgroundLayer.lineWidth = lineWidth
        layer.addSublayer(backgroundLayer)

        progressLayer.fillColor = nil
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        layer.addSublayer(progressLayer)

        updateStrokeColor()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if layer == self.layer {
            backgroundLayer.frame = layer.bounds
            progressLayer.frame = layer.bounds

            let circlePath = clockWiseCircleBezierPath(with: layer.bounds.size)
            backgroundLayer.path = circlePath.cgPath
            progressLayer.path = circlePath.cgPath
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard let model = model else { return }
        if window != nil {
            update(with: model)
        }
    }

    func update(with model: ProgressModel?) {
        self.model = model

        let animationKey = "progress-animation"

        guard let model = model else {
            progressLayer.removeAnimation(forKey: animationKey)
            return
        }

        let now = layer.convertTime(CACurrentMediaTime(), from: nil)
        let beginTime = now + model.startTime.timeIntervalSinceNow
        let duration = model.duration
        let durationQuater = duration / 4
        let colorAnimationDuration = Styles.Animations.progressColorAnimationDuration

        let strokeStartKeyPath = #keyPath(CAShapeLayer.strokeStart)
        let strokeAnimation = CABasicAnimation(keyPath: strokeStartKeyPath)
        strokeAnimation.beginTime = 0
        strokeAnimation.duration = duration
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1

        let strokeColorKeyPath = #keyPath(CAShapeLayer.strokeColor)
        let colorAnimation1 = CABasicAnimation(keyPath: strokeColorKeyPath)
        colorAnimation1.beginTime = durationQuater * 3
        colorAnimation1.duration = colorAnimationDuration
        colorAnimation1.fromValue = mainColor.cgColor
        colorAnimation1.toValue = lastQuaterColor.cgColor

        let colorAnimation2 = CABasicAnimation(keyPath: strokeColorKeyPath)
        colorAnimation2.beginTime = colorAnimation1.beginTime + colorAnimationDuration
        colorAnimation2.duration = durationQuater - colorAnimationDuration
        colorAnimation2.fromValue = lastQuaterColor.cgColor
        colorAnimation2.toValue = lastQuaterColor.cgColor

        let groupAnimation = CAAnimationGroup()
        groupAnimation.beginTime = beginTime
        groupAnimation.duration = duration
        groupAnimation.animations = [strokeAnimation, colorAnimation1, colorAnimation2]

        progressLayer.add(groupAnimation, forKey: animationKey)

        #if SCREENSHOT && !APP_EXTENSION
            if CommandLine.isDemoMode {
                progressLayer.strokeStart = 0.305
                progressLayer.strokeColor = mainColor.cgColor
            }
        #endif /* SCREENSHOT && !APP_EXTENSION */
    }

    // MARK: Private

    private func updateStrokeColor() {
        progressLayer.strokeColor = mainColor.cgColor
        backgroundLayer.strokeColor = mainColor.withAlphaComponent(0.25).cgColor
    }
}

private func clockWiseCircleBezierPath(with size: CGSize) -> UIBezierPath {
    // Angles in the default coordinate system
    //
    //         3π/2
    //         *  *
    //      *      \ *
    //  π  *        | *  0, 2π
    //     *        v *
    //      *        *
    //         *  *
    //          π/2
    //
    let startAngle = 3 * Double.pi / 2
    let endAngle = startAngle + 2 * Double.pi
    let arcCenter = CGPoint(x: size.width / 2, y: size.height / 2)
    let path = UIBezierPath(arcCenter: arcCenter,
                            radius: arcCenter.x,
                            startAngle: CGFloat(startAngle),
                            endAngle: CGFloat(endAngle),
                            clockwise: true)

    return path
}
