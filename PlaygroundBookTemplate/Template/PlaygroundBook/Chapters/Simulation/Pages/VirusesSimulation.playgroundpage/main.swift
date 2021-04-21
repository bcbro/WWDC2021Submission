//#-hidden-code

///import statements
import SpriteKit
import PlaygroundSupport
import UIKit


///Keep in mind this game works best wih results disabled.



///creates an SKView
let skView = SKView(frame: .zero)

///creates a GameScene from the screen constraints
let gameScene=GameScene(size: UIScreen.main.bounds.size)

//#-end-hidden-code

//:#localized(key: "ProseBlock")

/// sets the number of floating Viruses on the display (you can change this)
gameScene.setNumberOfViruses(numberOfViruses: /*#-editable-code*/4/*#-end-editable-code*/ )

/// sets the number of stationary redBloodCells on the display (you can change this)
gameScene.setNumberOfRedBloodCells(numberOfRedBloodCells:  /*#-editable-code*/20/*#-end-editable-code*/ )

//#-hidden-code
//
//  See LICENSE folder for this template’s licensing information.
//

/// sets final Scaling Settings
gameScene.scaleMode = .aspectFill

    
///sets gameScene onto SKView
skView.presentScene(gameScene)

    
///sets prefered FPS to 60
skView.preferredFramesPerSecond=60

    
///presents SKView onto the playground page
PlaygroundPage.current.liveView=skView

    
///requests full screen
PlaygroundPage.current.wantsFullScreenLiveView=true

//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//
//#-end-hidden-code
