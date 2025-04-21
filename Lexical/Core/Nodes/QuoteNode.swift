/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

public class QuoteNode: ElementNode {
  override public init() {
    super.init()
  }

  override public required init(_ key: NodeKey?) {
    super.init(key)
  }

  public required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
  }

  override public class func getType() -> NodeType {
    return .quote
  }

  override public func clone() -> Self {
    Self(key)
  }

  override public func getAttributedStringAttributes(theme: Theme) -> [NSAttributedString.Key: Any] {
      var attributes: [NSAttributedString.Key: Any] =   theme.quote ?? [:]
      attributes[.quoteCustomDrawing] = QuoteCustomDrawingAttributes(
        barColor: .init(hexString: "#C2C2C8"),
        barWidth: 4,
        rounded: true,
        barInsets: .init(top: .zero, left: .zero, bottom: .zero, right: .zero)
      )
      return attributes
  }

  override public func getIndent() -> Int {
    1
  }

  // MARK: - Mutation

  override open func insertNewAfter(selection: RangeSelection?) throws -> Node? {
    let newBlock = createParagraphNode()
    let direction = getDirection()
    try newBlock.setDirection(direction: direction)

    try insertAfter(nodeToInsert: newBlock)

    return newBlock
  }

  override public func collapseAtStart(selection: RangeSelection) throws -> Bool {
    let paragraph = createParagraphNode()
    let children = getChildren()
    try children.forEach({ try paragraph.append([$0]) })
    try replace(replaceWith: paragraph)

    return true
  }
}

@objc public class QuoteCustomDrawingAttributes: NSObject {
  public init(barColor: UIColor, barWidth: CGFloat, rounded: Bool, barInsets: UIEdgeInsets) {
    self.barColor = barColor
    self.barWidth = barWidth
    self.rounded = rounded
    self.barInsets = barInsets
  }

  let barColor: UIColor
  let barWidth: CGFloat
  let rounded: Bool
  let barInsets: UIEdgeInsets

  override public func isEqual(_ object: Any?) -> Bool {
    let lhs = self
    guard let rhs = object as? QuoteCustomDrawingAttributes else {
      return false
    }
    return lhs.barColor == rhs.barColor && lhs.barWidth == rhs.barWidth && lhs.rounded == rhs.rounded && lhs.barInsets == rhs.barInsets
  }
}

public extension NSAttributedString.Key {
  static let quoteCustomDrawing: NSAttributedString.Key = .init(rawValue: "quoteCustomDrawing")
}

extension QuoteNode {
  internal static var quoteBackgroundDrawing: CustomDrawingHandler {
    get {
      return { attributeKey, attributeValue, layoutManager, attributeRunCharacterRange, granularityExpandedCharacterRange, glyphRange, rect, firstLineFragment in
        guard let attributeValue = attributeValue as? QuoteCustomDrawingAttributes else { return }

        let barRect = CGRect(
          x: rect.minX + attributeValue.barInsets.left,
          y: rect.minY + attributeValue.barInsets.top,
          width: attributeValue.barWidth,
          height: rect.height - attributeValue.barInsets.top - attributeValue.barInsets.bottom)
        attributeValue.barColor.setFill()

        if attributeValue.rounded {
          let bezierPath = UIBezierPath(roundedRect: barRect, cornerRadius: attributeValue.barWidth / 2)
          bezierPath.fill()
        } else {
          UIRectFill(barRect)
        }
      }
    }
  }
}

private extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    convenience init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF
        )
    }
}
