import CoreGraphics

extension CGRect {
    /// Center point of rect
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    /// Top left corner
    var topLeft: CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    
    /// Top right corner
    var topRight: CGPoint {
        return CGPoint(x: maxX, y: minY)
    }
    
    /// Bottom left corner
    var bottomLeft: CGPoint {
        return CGPoint(x: minX, y: maxY)
    }
    
    /// Bottom right corner
    var bottomRight: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    
    /// Create rect centered at point
    init(center: CGPoint, size: CGSize) {
        self.init(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
    
    /// Inset rect by amount
    func inset(by amount: CGFloat) -> CGRect {
        return insetBy(dx: amount, dy: amount)
    }
    
    /// Scale rect by factor
    func scaled(by factor: CGFloat) -> CGRect {
        return CGRect(
            x: origin.x * factor,
            y: origin.y * factor,
            width: size.width * factor,
            height: size.height * factor
        )
    }
}
