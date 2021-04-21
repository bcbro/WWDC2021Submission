import SpriteKit
import PlaygroundSupport

protocol InfectedCellDelegate {
    ///delegate gives VirusPath the most recent list of viruses
    func getViruse(virusPath: VirusPath)
    ///delegate gives VirusPath the most recent list of viruses
    func getCelle(virusPath: VirusPath)
    ///delegate sends a Virus from a startPoint to endPoint.
    func sendVirus(startPoint: CGPoint, endPoint: CGPoint)
}

public class InfectedCell: SKSpriteNode {
    
    ///list of viruses
    var viruses = [Virus]()
    
    ///list of aliveCells of type SKSpriteNode
    var aliveCells = [SKSpriteNode]()
    
    ///dispatchQueue that creates Viruses
    let virusEmitterCalQueue = DispatchQueue(label: "virusEmitterCal", attributes: .concurrent)
    
    ///VirusPath to calculate paths for the infectedCells' emitted Viruses
    var virusEmitterPath: VirusPath!
    
    ///the infectedCell's delegate
    var delegate: InfectedCellDelegate?
    
    ///initialization for a InfectedCell at a given position
    init(size: CGSize, position: CGPoint) {
        super.init(texture: SKTexture(image:  UIImage(named: "infectedCell.png")!), color: .clear, size: CGSize(width: size.width*0.05, height: size.width*0.05))
        self.position=position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///sets its viruses to given list of viruses
    public func setViruses(viruses: [Virus]) {
        self.viruses=viruses
    }
    
    ///sets its cells to given list of cells
    public func setAliveCells(aliveCells: [SKSpriteNode]) {
        self.aliveCells=aliveCells
    }
    
    ///calculates paths for the newly created viruses
    public func startSpewingViruses() {
        delegate?.getCelle(virusPath: self.virusEmitterPath)
        delegate?.getViruse(virusPath: self.virusEmitterPath)
        
        
        virusEmitterPath = VirusPath(viruses: self.viruses, aliveCells: aliveCells)
        virusEmitterPath.delegate=self
    }
    
    ///clears the cell List
    public func clearCells() {
        aliveCells.removeAll()
    }
    
    ///clears the viruses List
    public func clearViruses() {
        viruses.removeAll()
    }
    
    ///adds a Cell object to the cell List
    public func appendCell(cell: redBloodCell) {
        aliveCells.append(cell)
    }
    
    ///adds a Virus object to the viruses List
    public func appendVirus(virus: Virus) {
        viruses.append(virus)
    }
    
    ///constantly calculate the infectedCell's Viruses
    public func queueCalculation() {
        virusEmitterCalQueue.async { [self] in
            delegate?.getCelle(virusPath: self.virusEmitterPath)
            delegate?.getViruse(virusPath: self.virusEmitterPath)
            if(self.position != nil) {
                for x in aliveCells {
                    print(x.position.y)
                }
                virusEmitterPath.findClosestCellToPosition(position: self.position)
            }
        }
    }
}

extension InfectedCell: VirusPathDelegate {
    ///returns viruses to the delegate
    func getViruses() -> [Virus] {
        return viruses
    }
    
    ///returns cells to the delegate
    func getCells() -> [SKSpriteNode] {
        return aliveCells
    }
    
    func sendVirus(virus: Virus, position: CGPoint) {
    }
    
    ///sends a newly created virus from a startPoint to an endPoint
    func sendNewVirus(startPosition: CGPoint, endPosition: CGPoint) {
        delegate?.sendVirus(startPoint: startPosition, endPoint: endPosition)
    }
}
