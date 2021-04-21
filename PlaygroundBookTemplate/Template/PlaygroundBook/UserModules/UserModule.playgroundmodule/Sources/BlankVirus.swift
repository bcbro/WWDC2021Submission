
import SpriteKit
import UIKit
import PlaygroundSupport

public class BlankVirus: SKSpriteNode {
    
    ///initialization for BlankVirus
    init(size: CGSize) {
        super.init(texture: SKTexture(image:  UIImage(named: "blank.png")!), color: .clear, size: CGSize(width: size.width*0.04, height: size.width*0.04))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
