
import SpriteKit
import CoreImage

public class bCell: SKSpriteNode {
    ///initialization of a bCell
    init(size: CGSize) {
        super.init(texture: SKTexture(image:  UIImage(named: "bCell-removebg-preview.png")!), color: .clear, size: CGSize(width: size.width*0.05, height: size.width*0.05))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
