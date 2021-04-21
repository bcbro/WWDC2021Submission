import SpriteKit
import UIKit
import PlaygroundSupport

protocol VirusPathDelegate: class{
    ///calls on GameScene to send an existing Virus to a point
    func sendVirus(virus: Virus, position: CGPoint)
    
    ///calls on GameScene to send an newly created Virus to an endPoint
    func sendNewVirus(startPosition: CGPoint, endPosition: CGPoint)
}

public class VirusPath {
    
    ///delegate for the virusPath
    var delegate: VirusPathDelegate?
    
    ///list of viruses
    var viruses = [Virus]()
    
    ///list of aliveCells
    var aliveCells = [SKSpriteNode]()
    
    ///initialization for a Virus Path Visualizer
    init(viruses: [Virus], aliveCells: [SKSpriteNode]) {
        self.viruses=viruses
        self.aliveCells=aliveCells
    }
    
    ///sets its viruses list to the given list of viruses
    public func setViruses(viruses: [Virus]) {
        self.viruses=viruses
    }
    
    ///sets its aliveCells list to the given list of aliveCells
    public func setAliveCells(aliveCells: [SKSpriteNode]) {
        self.aliveCells=aliveCells
    }
    
    ///determines target Cells/Positions for a given Virus
    func determineTargetCell(virus: Virus) {
        
        var closestCell = SKSpriteNode()
        var closestCellDistance=CGFloat.greatestFiniteMagnitude
        
        for cell in aliveCells {
            if((cell != nil) && (cell.position != nil)) {
                var cellVirusDistance=findDistanceFrom(positionOne: cell.position, positionTwo: virus.position)
                if(cellVirusDistance < closestCellDistance) {
                    closestCell=cell
                    closestCellDistance=cellVirusDistance
                }
            }
        }
        
        delegate?.sendVirus(virus: virus, position: closestCell.position)
    }
    
    ///determines target Cells/Positions for each of the Viruses
    func determineTargetCells() {
        if(viruses.count != 0){
            for i in 0...viruses.count-1 {
                if(viruses != nil) {
                    if(i <= viruses.count-1) {
                        determineTargetCell(virus: viruses[i])
                    }
                }
            }
        }
        
    }
    
    ///clears the cells list
    public func clearCells() {
        aliveCells.removeAll()
    }
    
    ///clears the viruses list
    public func clearViruses() {
        viruses.removeAll()
    }
    
    ///adds a SKSpriteNode to the cells list
    public func appendCell(cell: SKSpriteNode) {
        aliveCells.append(cell)
    }
    
    ///adds a Virus to the viruses list
    public func appendVirus(virus: Virus) {
        viruses.append(virus)
    }
    
    ///finds the closest Cell to the given Virus's position
    func findClosestCellToPosition(position: CGPoint) {
        var closestCell = SKSpriteNode()
        var closestCellDistance=CGFloat.greatestFiniteMagnitude
        
        for cell in aliveCells {
            if(cell != nil && cell is redBloodCell) {
                var cellVirusDistance=findDistanceFrom(positionOne: cell.position, positionTwo: position)
                if(cellVirusDistance < closestCellDistance) {
                    closestCell=cell
                    closestCellDistance=cellVirusDistance
                }
            }
        }
        
        delegate?.sendNewVirus(startPosition: position, endPosition: closestCell.position)
    }
    
    ///finds the distance from one given point to another given point
    func findDistanceFrom(positionOne: CGPoint, positionTwo: CGPoint) -> CGFloat  {
        let xChangeSquared = CGFloat(sqrt(positionOne.x-positionTwo.x)) * CGFloat(sqrt(positionOne.x-positionTwo.x))
        let yChangeSquared = CGFloat(sqrt(positionOne.y-positionTwo.y)) * CGFloat(sqrt(positionOne.y-positionTwo.y))
        return CGFloat(sqrt(xChangeSquared+yChangeSquared))
    }
}
