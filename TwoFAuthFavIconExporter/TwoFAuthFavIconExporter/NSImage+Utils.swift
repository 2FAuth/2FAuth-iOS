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

import AppKit

extension NSImage {
    func roundCorners(radius: CGFloat) -> NSImage {
        // off screen rendering
        let bitmapRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(size.width),
                                         pixelsHigh: Int(size.height),
                                         bitsPerSample: 8,
                                         samplesPerPixel: 4,
                                         hasAlpha: true,
                                         isPlanar: false,
                                         colorSpaceName: .deviceRGB,
                                         bitmapFormat: .alphaFirst,
                                         bytesPerRow: 0,
                                         bitsPerPixel: 0)!

        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)!
        context.imageInterpolation = .high

        NSGraphicsContext.saveGraphicsState()

        NSGraphicsContext.current = context

        let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let clipPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        clipPath.windingRule = .evenOdd
        clipPath.addClip()

        draw(at: NSZeroPoint, from: rect, operation: .sourceOver, fraction: 1)

        NSGraphicsContext.restoreGraphicsState()

        let composedImage = NSImage(size: size)
        composedImage.addRepresentation(bitmapRep)

        return composedImage
    }

    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        guard let tiffRepresentation = tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return false
        }

        let pngData = bitmapImage.representation(using: .png, properties: [:])

        do {
            try pngData?.write(to: url, options: options)
            return true
        }
        catch {
            print(">>> Writing png error: \(String(describing: error))")
            return false
        }
    }
}
