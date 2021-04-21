
import SpriteKit

public class redBloodCell: SKSpriteNode {
    ///initialization of a newly created redBloodCell
    init(size: CGSize) {
        super.init(texture: SKTexture(image: UIImage(named: "bloodCell.png")!), color: .clear, size: CGSize(width: size.width*0.05, height: size.width*0.05))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
