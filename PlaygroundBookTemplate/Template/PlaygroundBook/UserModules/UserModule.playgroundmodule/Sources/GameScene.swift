import SpriteKit
import UIKit
import SwiftUI
import PlaygroundSupport

public class GameScene: SKScene {
    ///boolean for whether audio is still playing
    var stillPlayingAudio=false
    
    ///audio node for backgroundMusic
    var backGroundAudioPlayer: SKAudioNode?
    
    ///list of active Antibodies
    var activeAntibodies=[Antibody]()
    
    ///default cells on display
    var numberOfCells=10
    
    ///default viruses on display
    var numberOfViruses=5
    
    ///default redBloodCells on display
    var numberOfRedBloodCells=9
    
    ///default number of viruses that can be emitted from an infected cell
    var virusesStoredInInfectedCells = 30
    
    ///default number of AliveCells on display
    var numberOfAliveCells=9
    
    ///label for the score on scene
    var scoreLabel = SKLabelNode(text: "Score: ")
    
    ///Label that asks users to tap to begin simulation/game
    var tapGameLabel: SKLabelNode?
    
    ///boolean for whether bCell has been infected
    var bCellInfected=false
    
    ///score Tracking Values
    var virusesUtilizedInInfection=0
    var virusesDestroyed=0
    
    ///whether the most recent tap was the first tap made by user
    var firstTap = true
    
    ///dispatch queue to play audio
    let audioPlayerAsync = DispatchQueue(label: "audioPlayer")
    
    ///whether player can shoot antibodies or not
    var playerAllowedToShoot = false
    
    ///list of infectedCells
    var infectedCells = [InfectedCell]()
    
    ///dispatchQueue to collect results and finish up the game
    let resultUpdater = DispatchQueue(label: "resultUpdater")
    
    ///dispatchQueue for calculating the path of InfectedCells' emitted viruses
    let infectedCellsCal = DispatchQueue(label: "infectedCellCal", attributes: .concurrent)
    
    ///dispatchQueue for calculating the path of all Viruses on display
    let virusProjectileSender = DispatchQueue(label: "projectileShooter")
    
    ///defined Physics Body Radius Addition for Cells
    var definedCellContactDistance=0.05
    ///defined Physics Body Radius Addition for Viruses
    var definedVirusCellContactDistance=0.05
    
    ///list of aliveCells
    var aliveCells = [SKSpriteNode]()
    
    ///list of BlankVirus
    var blankViruses = [BlankVirus]()
    
    ///player bCell element
    var player: bCell!
    
    ///list of Cells, includes alive and infected Cells
    var cells=[SKSpriteNode]()
    
    ///list of Viruses
    var viruses=[Virus]()
    
    ///boolean of whether the game is Over
    var gameOver = false
    
    ///whether the player is currently Shooting
    var playerShooting = false
    
    ///offset from virus to the new targetPosition
    var offset: CGPoint!
    
    ///Virus Path, which tracks and calculates paths for the projectile Viruses
    var virusPathVisualizer =  VirusPath(viruses: [Virus](), aliveCells: [SKSpriteNode]())
    
    ///sets the number of redBloodCells you have to Protect
    public func setNumberOfRedBloodCells(numberOfRedBloodCells: Int) {
        self.numberOfRedBloodCells=numberOfRedBloodCells
        self.numberOfAliveCells=numberOfRedBloodCells
        self.numberOfCells=numberOfRedBloodCells
    }
    
    ///sets the number of Viruses that start off on the display
    public func setNumberOfViruses(numberOfViruses: Int) {
        self.numberOfViruses=numberOfViruses
    }
    
    ///sets the number of Viruses that can be emitted from the Cells
    public func setNumberOfVirusesStoredInInfectedCells(numberOfVirusesStoredInInfectedCells: Int) {
        self.virusesStoredInInfectedCells=numberOfVirusesStoredInInfectedCells
    }
    
    ///sets Game Scene to game mode, allowing player to shoot antibodies
    public func setPlayerAllowedToShoot() {
        playerAllowedToShoot=true
    }
    
    ///initiates as soon as skView presents this scene
    public override func didMove(to view: SKView) {
        if(playerAllowedToShoot) {
            playAudioBackground()
        }
        virusPathVisualizer.delegate=self
        
        physicsBody=SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction=0.0
        physicsWorld.contactDelegate=self
        physicsWorld.gravity=CGVector(dx: 0, dy: 0.0)
        
        scoreLabel.position=CGPoint(x: frame.midX+300.0, y: frame.midY+400.0)
        scoreLabel.zPosition=3
        scoreLabel.fontColor = .yellow
        scoreLabel.fontSize=30.0
        addChild(scoreLabel)
        
        let backGround=SKSpriteNode(texture: SKTexture(image: UIImage(named: "bloodstream2.jpg")!))
        backGround.setScale(2.42)
        backGround.zPosition = -10
        backGround.position=CGPoint(x: frame.midX, y: frame.midY)
        addChild(backGround)
        createBCell()
        for _ in 0...numberOfRedBloodCells-1 {
            createRedBloodCell()
        }
        for x in 0...numberOfViruses-1 {
            createVirusRandom()
            createBlankVirus(point: viruses[x].position)
        }
        if(playerAllowedToShoot) {
            tapGameLabel=SKLabelNode(text: "Tap to Start Game")
        }
        else {
            tapGameLabel=SKLabelNode(text: "Tap to Start Simulation")
        }
        tapGameLabel?.fontSize = 70.0
        tapGameLabel?.position=CGPoint(x: frame.midX, y: frame.midY)
        tapGameLabel?.zPosition=3
        tapGameLabel?.fontColor = .yellow
        addChild(tapGameLabel!)
//          startSendingUpdateInfoToInfectedCell()
//          sendVirusesFromInfectedCells()
////          sendAntibody(targetPosition: CGPoint(x: frame.midX, y: frame.midY))
//          sleep(1)
//          print("Huh")
//          determineTargetForInfectedCell()
        sendVirus()
    }
    
    ///starts sending Viruses to the redBloodCells through the Virus Path class
    func startSendingVirusesToCells() {
        virusPathVisualizer.determineTargetCells()
    }
    
    ///updates the viruses, cells, and antibodies list to the VirusPath
    func startUpdateVirusesAndCells() {
        virusProjectileSender.async { [self] in
            if(aliveCells.count != 0) {
                for x in 0..<aliveCells.count {
                    if aliveCells[x] is InfectedCell {
                        aliveCells.remove(at: x)
                    }
                }
            }
            
            virusPathVisualizer.setAliveCells(aliveCells: aliveCells)
            if(!playerAllowedToShoot) {
                if(activeAntibodies.count != 0) {
                    for x in 0...activeAntibodies.count-1 {
                        if activeAntibodies[x].position.x==frame.midX && activeAntibodies[x].position.y==frame.midY {
                            activeAntibodies.remove(at: x)
                        }
                    }
                }
            }
            if(viruses.count != 0){
                for x in 0..<viruses.count {
                    if viruses[x]==nil {
                        viruses.remove(at: x)
                    }
                }
            }
            virusPathVisualizer.setViruses(viruses: viruses)
            sleep(1)
            startSendingVirusesToCells()
        }
        
    }
    
    ///sends Virus from an infectedCell to a redBloodCell
    func sendVirus(infectedCellPoint: CGPoint, redCellPoint: CGPoint) {
        let virus=Virus(size: size)
        virus.position=infectedCellPoint
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: redCellPoint.x-virus.position.x, y: redCellPoint.y-virus.position.y))
        path.close()
        let move = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 10)
        
        virus.physicsBody=SKPhysicsBody(circleOfRadius: virus.size.width * CGFloat((0.5 + definedCellContactDistance)))
        virus.physicsBody?.mass=10
        virus.physicsBody?.categoryBitMask=BitMasks.virus
        
        virus.run(move)
        
        addChild(virus)
        
        viruses.append(virus)
    }
    
    ///finds the distance from one given point to another given point
    func findDistanceFrom(positionOne: CGPoint, positionTwo: CGPoint) -> CGFloat  {
        let xChangeSquared = CGFloat(sqrt(positionOne.x-positionTwo.x)) * CGFloat(sqrt(positionOne.x-positionTwo.x))
        let yChangeSquared = CGFloat(sqrt(positionOne.y-positionTwo.y)) * CGFloat(sqrt(positionOne.y-positionTwo.y))
        return CGFloat(sqrt(xChangeSquared+yChangeSquared))
    }
    
    ///randomly finds a value between the constraints
    func positionWithinRange(range: CGFloat, containerSize: CGFloat) -> CGFloat {
        let partOne=CGFloat(arc4random_uniform(100)) / 100.0
        let partTwo = (containerSize * (1.0-range) * 0.5)
        let partThree=(containerSize * range + partTwo)
        return partOne * partThree
    }
    
    ///creates a bCell in the middle of the Scene
    func createBCell() {
        player=bCell(size: size)
        player.position=CGPoint(x: frame.midX, y: frame.midY)
        
        player.physicsBody=SKPhysicsBody(circleOfRadius: player.size.width * CGFloat((0.5 + definedCellContactDistance)))
        player.physicsBody?.isDynamic=false
        player.physicsBody?.categoryBitMask=BitMasks.bCell
        player.physicsBody?.contactTestBitMask=BitMasks.virus
        
        addChild(player)
        cells.append(player)
    }
    
    ///creates a redBloodCell in a random Point along the constraints
    func createRedBloodCell() {
        let cell=redBloodCell(size: size)
        cell.position=CGPoint(x: positionWithinRange(range: 0.8, containerSize: size.width), y: positionWithinRange(range: 0.8, containerSize: size.height))
        
        while (cell.position.y<100 || cell.position.x<600 || cell.position.x>1200 || (findDistanceFrom(positionOne: cell.position, positionTwo: player.position) < cell.size.width * CGFloat(definedCellContactDistance))) {
            cell.position=CGPoint(x: positionWithinRange(range: 0.8, containerSize: size.width), y: positionWithinRange(range: 0.8, containerSize: size.height))
        }
        
        cell.physicsBody=SKPhysicsBody(circleOfRadius: cell.size.width * CGFloat((0.5 + definedCellContactDistance)))
        cell.physicsBody?.isDynamic=false
        cell.physicsBody?.categoryBitMask=BitMasks.redBloodCell
        cell.physicsBody?.contactTestBitMask=BitMasks.virus
        
        addChild(cell)
        cells.append(cell)
        aliveCells.append(cell)
    }
    
    ///creates an Infected Cell at a given Point
    func createInfectedCell(point: CGPoint) {
        
        let infectedCell = InfectedCell(size: size, position: point)
        
        infectedCell.physicsBody=SKPhysicsBody(circleOfRadius: infectedCell.size.width * CGFloat((0.5 + definedCellContactDistance)))
        infectedCell.physicsBody?.isDynamic=false
        infectedCell.physicsBody?.categoryBitMask=BitMasks.infectedCell
        
        infectedCell.delegate=self
        
        addChild(infectedCell)
        
        infectedCells.append(infectedCell)
    }
    
    ///creates an InfectedBCell to replace a bCell at a given point
    func createInfectedBCell(point: CGPoint) {
        
        let infectedCell = InfectedBCell(size: size, position: point)
        
        infectedCell.physicsBody=SKPhysicsBody(circleOfRadius: infectedCell.size.width * CGFloat((0.5 + definedCellContactDistance)))
        infectedCell.physicsBody?.isDynamic=false
        infectedCell.physicsBody?.categoryBitMask=BitMasks.infectedCell
        addChild(infectedCell)
    }
    
    ///creates a Virus in a random Point along the constraints
    func createVirusRandom() {
        let virus=Virus(size: size)
        virus.position=CGPoint(x: positionWithinRange(range: 0.8, containerSize: size.width), y: positionWithinRange(range: 0.8, containerSize: size.height))
        while (virus.position.y<100 || virus.position.x<600 || virus.position.x>1200) {
            virus.position=CGPoint(x: positionWithinRange(range: 0.8, containerSize: size.width), y: positionWithinRange(range: 0.8, containerSize: size.height))
        }
        
        virus.physicsBody=SKPhysicsBody(circleOfRadius: virus.size.width * CGFloat((0.5 + definedCellContactDistance)))
        virus.physicsBody?.isDynamic=true
        virus.physicsBody?.mass=0
        virus.physicsBody?.categoryBitMask=BitMasks.virus
        
        addChild(virus)
        
        viruses.append(virus)
        
    }
    
    ///creates a Virus at a given Point
    func createVirus(point: CGPoint) {
        guard !gameOver else {return}
        
        let virus=Virus(size: size)
        virus.position=point
        
        virus.physicsBody=SKPhysicsBody(circleOfRadius: virus.size.width * CGFloat((0.5 + definedCellContactDistance)))
        virus.physicsBody?.isDynamic=true
        virus.physicsBody?.mass=0
        virus.physicsBody?.categoryBitMask=BitMasks.virus
        
        addChild(virus)
        
        viruses.append(virus)
        
    }
    
    ///creates a BlankVirus to replace a dead Virus
    func createBlankVirus(point: CGPoint) {
        let blankVirus=BlankVirus(size: size)
        blankVirus.position=point
        
        addChild(blankVirus)
        
        blankViruses.append(blankVirus)
    }
    
    ///sends an newly created Antibody to a given target Position
    func sendAntibody(targetPosition: CGPoint) {
        guard !gameOver else {
            return
        }
        
        let antibody=createAntibody()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: offset.x, y: offset.y))
        path.close()
        let move = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 150)
        
        antibody.physicsBody=SKPhysicsBody(circleOfRadius: antibody.size.width * CGFloat((0.5 + definedCellContactDistance)))
        antibody.physicsBody?.mass=250
        antibody.physicsBody?.isDynamic=false
        antibody.physicsBody?.categoryBitMask=BitMasks.antibody
        antibody.physicsBody?.contactTestBitMask=BitMasks.virus
        antibody.run(move)
        
        addChild(antibody)
        activeAntibodies.append(antibody)
    }
    
    ///creates a new Antibody
    func createAntibody() ->Antibody {
        let antibody=Antibody(size: size)
        antibody.position=CGPoint(x: frame.midX, y: frame.midY)
        return antibody
    }
    
    ///handles User touches on screen
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.startUpdateVirusesAndCells()
        if(firstTap) {
            self.tapGameLabel?.removeFromParent()
        }
        guard !gameOver && playerAllowedToShoot && !firstTap
        else {
            firstTap=false
            return
        }
        guard let touchFirst=touches.first else {return }
        let touchPosition=touchFirst.location(in: self)
        offset=CGPoint(x: touchPosition.x-player.position.x, y: touchPosition.y-player.position.y)
        if(playerAllowedToShoot) {
            antibodyShooter(generalTarget: offset)
        }
        
        playerShooting=true
    }
    
    ///updates the antibodies list
    func updateAntibodies() {
        if self.activeAntibodies.count==0 {
            return
        }
        for i in 0...self.activeAntibodies.count-1 {
            if(self.activeAntibodies[i].position.x==self.frame.midX && self.activeAntibodies[i].position.y==self.frame.midY) {
                self.activeAntibodies.remove(at: i)
                self.removeChildren(in: [self.activeAntibodies[i]])
            }
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    ///shoot a newly Created Antibody to a given target
    func antibodyShooter(generalTarget: CGPoint) {
        sendAntibody(targetPosition: generalTarget)
    }
    
    ///removes the given cell from the cells list
    func removeFromAliveCells(deadCell: redBloodCell) {
        for x in aliveCells {
            if(x.position==deadCell.position) {
                aliveCells.removeAll { (y) -> Bool in
                    y.position==deadCell.position
                }
            }
        }
    }
    
    ///removes the given Virus from the viruses list
    func removeFromViruses(attachedVirus: Virus) {
        for x in viruses {
            if(x.position==attachedVirus.position) {
                viruses.removeAll { (y) -> Bool in
                    y.position==attachedVirus.position
                }
            }
        }
    }
    
    ///removes the given Antibody from the antibodies list
    func removeFromAntibodies(contactAntibody: Antibody) {
        for x in activeAntibodies {
            if(x.position==contactAntibody.position) {
                activeAntibodies.removeAll { (y) -> Bool in
                    y.position==contactAntibody.position
                }
            }
        }
    }
    
    ///infects the given redBloodCell with another given value of type Virus
    func infectRedBloodCell(cell: redBloodCell, virus: Virus) {
        print("infectRedBloodCell")
        removeFromAliveCells(deadCell: cell)
        let positionToFill = cell.position
        removeFromViruses(attachedVirus: virus)
        removeChildren(in: [cell, virus])
        virus.removeFromParent()
        cell.removeFromParent()
        createInfectedCell(point: positionToFill)
        
        numberOfAliveCells-=1
    }
    
    ///destroys the given Virus with the given Antibody
    func destroyVirus(antibody: Antibody, virus: Virus) {
        removeFromAntibodies(contactAntibody: antibody)
        removeFromViruses(attachedVirus: virus)
        virus.removeFromParent()
        antibody.removeFromParent()
        print("destroyVirus")
    }
    
    ///ends motion of all elements in GameScene
    func endGame() {
        gameOver=true
        print("game ended")
        backGroundAudioPlayer?.autoplayLooped=false
        backGroundAudioPlayer?.run(SKAction.stop())
        children.forEach{ child in
            child.removeAllActions()
        }
    }
}

///deals with the physics of the gameScene
extension GameScene: SKPhysicsContactDelegate {
    ///deals with collisions of elements in the GameScene
    public func didBegin(_ contact: SKPhysicsContact) {
        
        guard !gameOver && !firstTap else {
            return
        }
        
        if contact.bodyA.categoryBitMask==BitMasks.antibody && contact.bodyB.categoryBitMask==BitMasks.virus {
            virusesDestroyed+=1
            
            if(contact.bodyA.node==nil || contact.bodyB.node==nil) {
                return
            }
            destroyVirus(antibody: contact.bodyA.node as! Antibody, virus: contact.bodyB.node as! Virus)
            startUpdateVirusesAndCells()
            updateScore()
        }
        if contact.bodyB.categoryBitMask==BitMasks.antibody && contact.bodyA.categoryBitMask==BitMasks.virus {
            if(contact.bodyA.node==nil || contact.bodyB.node==nil) {
                return
            }
            destroyVirus(antibody: contact.bodyB.node as! Antibody, virus: contact.bodyA.node as! Virus)
            startUpdateVirusesAndCells()
            updateScore()
        }
        
        
        if contact.bodyA.categoryBitMask==BitMasks.redBloodCell && contact.bodyB.categoryBitMask==BitMasks.virus {
            virusesUtilizedInInfection+=1
            
            if(contact.bodyA.node==nil || contact.bodyB.node==nil) {
                return
            }
            infectRedBloodCell(cell: contact.bodyA.node as! redBloodCell, virus: contact.bodyB.node as! Virus)
            startUpdateVirusesAndCells()
            updateScore()
        }
        if contact.bodyB.categoryBitMask==BitMasks.redBloodCell && contact.bodyA.categoryBitMask==BitMasks.virus {
            numberOfAliveCells-=1
            
            if(contact.bodyA.node==nil || contact.bodyB.node==nil) {
                return
            }
            infectRedBloodCell(cell: contact.bodyB.node as! redBloodCell, virus: contact.bodyA.node as! Virus)
            startUpdateVirusesAndCells()
            updateScore()
        }
        
        
        if contact.bodyA.categoryBitMask==BitMasks.bCell && contact.bodyB.categoryBitMask==BitMasks.virus {
            bCellInfected=true
            removeChildren(in: [player])
            if(contact.bodyB.node != nil) {
                removeChildren(in: [contact.bodyB.node!])
            }
            
            createInfectedBCell(point: CGPoint(x: frame.midX, y: frame.midY))
            updateScore()
            checkResults()
        }
        
        if contact.bodyB.categoryBitMask==BitMasks.bCell && contact.bodyA.categoryBitMask==BitMasks.virus {
            bCellInfected=true
            virusesUtilizedInInfection+=1
            numberOfAliveCells-=1
            removeChildren(in: [player])
            removeChildren(in: [contact.bodyA.node!])
            
            createInfectedBCell(point: CGPoint(x: frame.midX, y: frame.midY))
            updateScore()
        }
    }
}
extension GameScene: VirusPathDelegate {
    ///returns viruses list to instances of VirusPath
    func getViruses() -> [Virus] {
        return viruses
    }
    
    ///returns cells list to instances of VirusPath
    func getCells() -> [SKSpriteNode] {
        return aliveCells
    }
    
    ///sends given Virus to another given position
    func sendVirus(virus: Virus, position: CGPoint) {
        guard !gameOver && !firstTap else {
            return
        }
        
        if(virus != nil && virus.physicsBody != nil && virus.position != nil && virus.size != nil && definedCellContactDistance != nil) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: position.x-virus.position.x, y: position.y-virus.position.y))
            path.close()
            let move = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 20)
            
            do {
                try virus.run(move)
            } catch {
                print("Couldn't move virus. Error: \(error)")
            }
        }
    }
    
    func sendNewVirus(startPosition: CGPoint, endPosition: CGPoint){
    }
}
extension GameScene: InfectedCellDelegate {
    ///returns virus list to instances of InfectedCell
    func getViruse(virusPath: VirusPath) {
        virusPath.clearViruses()
        for x in viruses {
            virusPath.appendVirus(virus: x)
        }
    }
    
    ///returns cell list to instances of InfectedCell
    func getCelle(virusPath: VirusPath) {
        virusPath.clearCells()
        for x in aliveCells {
            virusPath.appendCell(cell: x as! SKSpriteNode)
        }
    }
    
    ///sends Virus from the given startPoint to the other given value, endPoint
    func sendVirus(startPoint: CGPoint, endPoint: CGPoint) {
        
        let virus=Virus(size: size)
        virus.position=startPoint
        
        virus.run(SKAction.move(by: CGVector(dx: 0, dy: 0), duration: 1))
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: endPoint.x-virus.position.x, y: endPoint.y-virus.position.y))
        path.close()
        let move = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 50)
        
        virus.physicsBody=SKPhysicsBody(circleOfRadius: virus.size.width * CGFloat((0.5 + definedCellContactDistance)))
        virus.physicsBody?.mass=10
        virus.physicsBody?.categoryBitMask=BitMasks.virus
        do {
            try virus.run(move)
        }
        
        catch {
            print("Missing virus")
        }
        
        addChild(virus)
        
        viruses.append(virus)
    }
}
extension GameScene {
    
    ///sends Viruses from a random Infected Cell up to the given value, virusesStoredInInfectionCells
    func sendVirus() {
        infectedCellsCal.async { [self] in
            for x in 1...virusesStoredInInfectedCells {
                sleep(1)
                virusesStoredInInfectedCells-=1
                if(virusesStoredInInfectedCells>0 && infectedCells.count != 0) {
                    let randomInfectedCellIndex=arc4random_uniform(UInt32(infectedCells.count-1))
                    createVirus(point: infectedCells[Int(randomInfectedCellIndex)].position)
                }
                if(viruses.count > 0 && aliveCells.count > 0) {
                    startUpdateVirusesAndCells()
                    virusPathVisualizer.determineTargetCells()
                }
            }
            sleep(5)
            checkResults()
        }
    }
}
extension GameScene {
    
    ///function to update the Score whenever a collision occurs
    func updateScore() {
        var bCellInfectedConstant: Int=0
        if(bCellInfected) {
            bCellInfectedConstant = -50
        }
        let score: Int = 400 + (30 * virusesDestroyed + -10 * virusesUtilizedInInfection + bCellInfectedConstant) * 10
        scoreLabel.text="Score: " + String(score)
    }
    
    ///function to check Results of the game once done
    func checkResults() {
        if(gameOver) {
            return
        }
        resultUpdater.async { [self] in
            while(virusesDestroyed+virusesUtilizedInInfection+3 < numberOfViruses+virusesStoredInInfectedCells && !bCellInfected) {
                virusPathVisualizer.determineTargetCells()
                print(virusesDestroyed+virusesUtilizedInInfection)
                sleep(1)
            }
            endGame()
            
            if(Double(Double(numberOfAliveCells+4)/Double(numberOfRedBloodCells))<0.5 || bCellInfected) {
                audioPlayerAsync.async { [self] in
                    backGroundAudioPlayer?.run(SKAction.changeVolume(by: -10, duration: 0.5))
                    if(playerAllowedToShoot) {
                        playAudioGameOver()
                        sleep(2)
                    }
                    playAudioGameLost()
                }
                gameLost()
            }
            else {
                audioPlayerAsync.async { [self] in
                    backGroundAudioPlayer?.run(SKAction.changeVolume(by: -10, duration: 0.5))
                    playAudioGameWon()
                }
                gameWon()
            }
        }
    }
    
    ///function to go through all losing case conditions
    func gameLost() {
        children.forEach{ child in
            child.removeAllActions()
        }
        
        if(playerAllowedToShoot) {
            let gameLostLabel=SKLabelNode(text: "The Viruses Have Taked Over the Body, Run The Code to Try Again")
            gameLostLabel.fontSize = 30.0
            if(bCellInfected) {
                gameLostLabel.text="The B Cell has been infected, All defensive measures demolished, Run The Code to Try Again"
                gameLostLabel.fontSize = 24.0
            }
            gameLostLabel.position=CGPoint(x: frame.midX, y: frame.midY-480.0)
            gameLostLabel.zPosition=3
            gameLostLabel.fontColor = .yellow
            addChild(gameLostLabel)
        }
        else {
            let gameLostLabel=SKLabelNode(text: "The Viruses Have Taked Over the Body")
            gameLostLabel.fontSize = 30.0
            gameLostLabel.position=CGPoint(x: frame.midX-40, y: frame.midY+450)
            gameLostLabel.zPosition=3
            gameLostLabel.fontColor = .yellow
            addChild(gameLostLabel)
            let gameLostLabel2=SKLabelNode(text: "Run The Game on the Next Page to See the Influence of Vaccines on the Immune System")
            gameLostLabel2.fontSize = 23.0
            gameLostLabel2.position=CGPoint(x: frame.midX, y: frame.midY+450-30.0)
            gameLostLabel2.zPosition=3
            gameLostLabel2.fontColor = .yellow
            addChild(gameLostLabel2)
        }
    }
    
    ///function to go through all winning case conditions
    func gameWon() {
        children.forEach{ child in
            child.removeAllActions()
        }
        print("game won")
        
        let gameWonLabel=SKLabelNode(text: "You won, The Viruses have been staved off, Great job")
        gameWonLabel.fontSize = 30.0
        gameWonLabel.position=CGPoint(x: frame.midX, y: frame.midY)
        gameWonLabel.zPosition=3
        gameWonLabel.fontColor = .yellow
        addChild(gameWonLabel)
        sleep(2)
    }
}



///audio Addition
extension GameScene {
    /// function to play gameOver them sound effect to let user know the game is done.
    func playAudioGameOver() {
        if let audioURL = Bundle.main.url(forResource: "gameOver_Sound_Effect", withExtension: "mp3") {
            do {
                let audioPlayer=SKAudioNode(url: audioURL)
                audioPlayer.autoplayLooped=false
                audioPlayer.run(SKAction.changeVolume(by: -0.95, duration: 0.5))
                addChild(audioPlayer)
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run({
                        audioPlayer.run(SKAction.play())
                    })
                ]))
            } catch {
                print("Couldn't play audio. Error: \(error)")
            }
            
        } else {
            print("No audio file found")
        }
    }
    
    /// function to play losing theme sound effect
    func playAudioGameLost() {
        if let audioURL = Bundle.main.url(forResource: "gameLost_Sound_Effect", withExtension: "mp3") {
            do {
                let audioPlayer=SKAudioNode(url: audioURL)
                audioPlayer.autoplayLooped=false
                audioPlayer.run(SKAction.changeVolume(by: -0.95, duration: 0.5))
                addChild(audioPlayer)
                run(SKAction.sequence([
                    SKAction.run({
                        audioPlayer.run(SKAction.play())
                    })
                ]))
            } catch {
                print("Couldn't play audio. Error: \(error)")
            }
            
        } else {
            print("No audio file found")
        }
    }
    
    /// function to play winning theme sound effect
    func playAudioGameWon() {
        if let audioURL = Bundle.main.url(forResource: "gameWin_Sound_Effect", withExtension: "mp3") {
            do {
                let audioPlayer=SKAudioNode(url: audioURL)
                audioPlayer.autoplayLooped=false
                audioPlayer.run(SKAction.changeVolume(by: -0.25, duration: 0.5))
                player.addChild(audioPlayer)
                player.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run({
                        audioPlayer.run(SKAction.play())
                    })
                ]))
            } catch {
                print("Couldn't play audio. Error: \(error)")
            }
            
        } else {
            print("No audio file found")
        }
    }
    
    /// function to play background audio
    func playAudioBackground() {
        if let audioURL = Bundle.main.url(forResource: "backGroundMusic", withExtension: "mp3") {
            do {
                backGroundAudioPlayer=SKAudioNode(url: audioURL)
                backGroundAudioPlayer?.autoplayLooped=true
                addChild(backGroundAudioPlayer!)
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run({ [self] in
                        backGroundAudioPlayer?.run(SKAction.play())
                        backGroundAudioPlayer?.run(SKAction.changeVolume(by: -0.95, duration: 0.5))
                    })
                ]))
            } catch {
                print("Couldn't play audio. Error: \(error)")
            }
            
        } else {
            print("No audio file found")
        }
    }
    
    
}

