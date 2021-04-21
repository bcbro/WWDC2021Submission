
import SpriteKit
import PlaygroundSupport

public class InfectedBCell: SKSpriteNode {
    
    ///initialization for a InfectedBCell at a given position
    init(size: CGSize, position: CGPoint) {
        super.init(texture: SKTexture(image:  UIImage(named: "infectedBCell-removebg-preview.png")!), color: .clear, size: CGSize(width: size.width*0.05, height: size.width*0.05))
        self.position=position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

