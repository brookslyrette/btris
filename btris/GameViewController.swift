//
//  GameViewController.swift
//  btris
//
//  Created by Brooks Lyrette on 2015-02-08.
//  Copyright (c) 2015 Brooks Lyrette. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, BtrisDelegate, UIGestureRecognizerDelegate {
    
    var scene: GameScene!
    var btris: Btris!
    var panPointReference:CGPoint?
    
    
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = view as SKView
        skView.multipleTouchEnabled = false
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        btris = Btris()
        btris.delegate = self
        btris.beginGame()
        
        skView.presentScene(scene)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBOutlet var didTap: UITapGestureRecognizer!
    
    func didTick() {
        btris.letShapeFall()
    }
    
    func nextShape() {
        let newShapes = btris.newShape()
        if let fallingShape = newShapes.fallingShape {
            self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
            self.scene.movePreviewShape(fallingShape) {
                // #2
                self.view.userInteractionEnabled = true
                self.scene.startTicking()
            }
        }
    }
    
    func gameDidBegin(btris: Btris) {
        levelLabel.text = "\(btris.level)"
        scoreLabel.text = "\(btris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if btris.nextShape != nil && btris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(btris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(btris: Btris) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(btris.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {
            btris.beginGame()
        }
    }
    
    func gameDidLevelUp(btris: Btris) {
        levelLabel.text = "\(btris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(btris: Btris) {
        scene.stopTicking()
        scene.redrawShape(btris.fallingShape!) {
            btris.letShapeFall()
        }
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(btris: Btris) {
        scene.stopTicking()
        self.view.userInteractionEnabled = false
        let removedLines = btris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(btris.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                self.gameShapeDidLand(btris)
            }
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(btris: Btris) {
        scene.redrawShape(btris.fallingShape!) {}
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
        if let swipeRec = gestureRecognizer as? UISwipeGestureRecognizer {
            if let panRec = otherGestureRecognizer as? UIPanGestureRecognizer {
                return true
            }
        } else if let panRec = gestureRecognizer as? UIPanGestureRecognizer {
            if let tapRec = otherGestureRecognizer as? UITapGestureRecognizer {
                return true
            }
        }
        return false
    }

    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference {
           
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
               
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    btris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    btris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        btris.rotateShape()
    }
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        btris.dropShape()
    }
}