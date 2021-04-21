
import SpriteKit
import PlaygroundSupport
import UIKit

public class Antibody: SKSpriteNode {
    
    ///initialization for antibody creation
    init(size: CGSize) {
        super.init(texture: SKTexture(image: UIImage(named: "virus_antibody-removebg-preview.png")!), color: .clear, size: CGSize(width: size.width*0.04, height: size.width*0.04))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

