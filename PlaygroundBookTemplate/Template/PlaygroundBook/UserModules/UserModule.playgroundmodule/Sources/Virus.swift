import SpriteKit
import UIKit
import PlaygroundSupport

protocol VirusDelegate: class {
    func deleteVirus()
}

public class Virus: SKSpriteNode {
    
    ///initialization of a newly created Virus
    init(size: CGSize) {
        super.init(texture: SKTexture(image: UIImage(named: "virus-removebg-preview.png")!), color: .clear, size: CGSize(width: size.width*0.04, height: size.width*0.04))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
