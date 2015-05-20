 //
 //  GameScene.swift
 //  Gravity
 //
 //  Created by Cal on 11/8/14.
 //  Copyright (c) 2014 Cal. All rights reserved.
 //
 
 import SpriteKit
 import Darwin
 
 class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var planetCount: Int = 2 {
        willSet(newCount) {
            let plural = "s"
            let singular = ""
            (self.childNodeWithName("GUI")!.childNodeWithName("PlanetCount")! as! SKLabelNode).text = "\(newCount) planet\(newCount == 1 ? singular : plural)"
            (self.childNodeWithName("GUI")!.childNodeWithName("PPS")! as! SKLabelNode).text = "\(max(newCount - 1, 0)) point\((newCount - 1) == 1 ? singular : plural) per second"
        }
    }
    var points: Int = 0 {
        willSet(newPoints) {
            (self.childNodeWithName("GUI")!.childNodeWithName("Points")! as! SKLabelNode).text = "\(newPoints)"
        }
    }
    var touchTracker : TouchTracker? = nil
    let GUINode = SKNode()
    let gameOverLabel = SKLabelNode(fontNamed: "HelveticaNeue-UltraLight")
    var screenSize : (width: CGFloat, height: CGFloat) = (0, 0)
    
    override func didMoveToView(view: SKView) {
        //GUI setup
        GUINode.name = "GUI"
        screenSize = (760, 1365)
        let countLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
        countLabel.name = "PlanetCount"
        countLabel.text = "2 planets"
        countLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.15, alpha: 1)
        countLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        countLabel.fontSize = 60
        countLabel.position = CGPointMake(20, 20)
        GUINode.addChild(countLabel)
        let pointsLabel = SKLabelNode(fontNamed: "HelveticaNeue-UltraLight")
        pointsLabel.name = "Points"
        pointsLabel.text = "200"
        pointsLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        pointsLabel.fontSize = 150
        pointsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        pointsLabel.position = CGPointMake(20, screenSize.height - 120)
        GUINode.addChild(pointsLabel)
        gameOverLabel.name = "GameOver"
        gameOverLabel.text = "game over"
        gameOverLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        gameOverLabel.fontSize = 140
        gameOverLabel.position = CGPointMake(screenSize.width / 2, screenSize.height / 2)
        gameOverLabel.hidden = true
        GUINode.addChild(gameOverLabel)
        let ppsLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
        ppsLabel.name = "PPS"
        ppsLabel.text = "1 point per second"
        ppsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        ppsLabel.fontColor = UIColor(hue: 0, saturation: 0, brightness: 0.15, alpha: 1)
        ppsLabel.fontSize = 40
        ppsLabel.position = CGPointMake(screenSize.width - 10, 20)
        GUINode.addChild(ppsLabel)
        GUINode.zPosition = 100
        addChild(GUINode)
        let updatePoints = SKAction.sequence([
            SKAction.runBlock({ self.points += max(self.planetCount - 1, 0) }),
            SKAction.waitForDuration(0.5)
            ])
        runAction(SKAction.repeatActionForever(updatePoints))
        
        let center = CGPointMake(screenSize.width / 2, screenSize.height / 2)

        
        /*let startPlanet1 = Planet(radius: 40, color: getRandomColor(), position: CGPointMake(center.x, center.y - 250), physicsMode: .SceneStationary)
        let startPlanet2 = Planet(radius: 40, color: getRandomColor(), position: CGPointMake(center.x, center.y + 250), physicsMode: .SceneStationary)
        addChild(startPlanet1)
        addChild(startPlanet2)*/
        
        //addChild(Planet(radius: 40, color: getRandomColor(), position: center, physicsMode: .SceneStationary))
        
        //game setup
        physicsWorld.contactDelegate = self
        let doCalculations = SKAction.sequence([
            SKAction.runBlock(doForceCaculations),
            SKAction.waitForDuration(0.005)
            ])
        runAction(SKAction.repeatActionForever(doCalculations))
    }
    
    func doForceCaculations() {
        for child in self.children{
            if let touch = child as? PlanetTouch {
                touch.drawPlanetPath()
            }
            if !(child is Planet){ continue }
            let planet = child as! Planet
            for child in self.children{
                if !(child is Planet){ continue }
                let other = child as! Planet
                if other == planet{ continue }
                planet.applyForcesOf(other)
            }
            planet.updatePosition()
        }
    }
    
    func gameOver(loser: Planet){
        self.paused = true
        self.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1)
        loser.fillColor = UIColor.blackColor()
        gameOverLabel.hidden = false
    }
    
    func didBeginContact(contact: SKPhysicsContact){
        if contact.bodyA.node is Planet && contact.bodyB.node is Planet{
            let planet1 = contact.bodyA.node as! Planet
            let planet2 = contact.bodyB.node as! Planet
            
            let newPlanet = planet1.mergeWithPlanet(planet2)
            
            removeChildrenInArray([planet1, planet2])
            addChild(newPlanet)
            planetCount--
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if !gameOverLabel.hidden {
            for node in self.children{
                if node is Planet {
                    self.removeChildrenInArray([node])
                }
            }
            points = 0
            planetCount = 0
            backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.95, alpha: 1)
            self.paused = false
            gameOverLabel.hidden = true
            touchTracker = nil
        } else {
            if touchTracker == nil{
                touchTracker = TouchTracker()
            }
            for touch in touches{
                let position = (touch as! UITouch).previousLocationInNode(self)
                let planetTouch = touchTracker!.startTracking(position)
                self.addChild(planetTouch)
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as! UITouch).previousLocationInNode(self)
            touchTracker?.didMove(position)
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch in touches{
            let position = (touch as! UITouch).previousLocationInNode(self)
            if touchTracker != nil{
                if var planet = touchTracker!.stopTracking(position) {
                    addChild(planet)
                    planetCount++
                }
            }
        }
    }
    
 }
 
 func getRandomColor() -> SKColor{
    return SKColor(hue: random(min: 0.15, max: 1.0), saturation: random(min: 0.8, max: 1.0), brightness: random(min: 0.5, max: 0.8), alpha: 1.0)
 }
 
 func random(#min: CGFloat, #max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
 }