//
//  MemoryGameController.swift
//  showSkills
//
//  Created by Kim on 3/12/22.
//

import Foundation
import UIKit

class MemoryGameController: UIViewController {
  // font awesome array
  var funFontAwesomeShapes = ["\u{f0f9}","\u{f2a3}","\u{f13d}","\u{f17b}","\u{f179}","\u{f206}","\u{f140}","\u{f0f4}","\u{f21c}","\u{f094}","\u{f084}","\u{f135}","\u{f807}","\u{f1ba}","\u{f023}","\u{f001}","\u{f025}","\u{f07a}","\u{f0c4}","\u{f0d1}","\u{f11a}","\u{f130}","\u{f188}"]
  // delete below for testing short game
  //funFontAwesomeShapes = ["\u{f0c4}","\u{f0d1}","\u{f11a}","\u{f130}","\u{f188}"]
  // build array of possible colors
  var gameColors = [UIColor.red, UIColor.blue, UIColor.green, UIColor.orange, UIColor.purple, UIColor.systemPink]
  var selectedShapes : [Items]?
  var shapesToChooseFrom : [String]?
  var correctCount : Int = 0
  
  // Items for selected shapes
  struct Items {
    var fontAwesomeText : String
    var tag: Int
    var color: UIColor
    var hintGiver: Bool
  }
  
  struct FrameGrid {
    var xvalue: Int
    var yvalue: Int
  }
  
  // don't want images overlapping so created grid
  // of possible unique image frames
  var availableGridForObjects : [FrameGrid]?  // populated once
  var usedGridForObjects : [FrameGrid]!       // each turn gets copy from availableGridForObjects

 
  @IBOutlet weak var lblScoreBoard: UILabel!
  @IBOutlet weak var btnClose: UIButton!
  
  override func viewDidLoad() {
    self.view.backgroundColor = UIColor(red: 204/255, green: 255/255, blue: 255/255, alpha: 1)
    buildGrid()
    newGame()
  }
  
  @IBAction func btnCloseGame(_ sender: Any) {
    self.dismiss(animated: true)
  }
  
  /// buildGrid - Build array of all possible label frames.  This prevent labels
  /// from overlaying each other
  func buildGrid () {
    // this is to build an array of possible
    // object locations
    let xbound = UInt32(self.view.frame.width - 90)
    let ybound = UInt32(self.view.frame.height - 220)
    let xGridCount = Int(xbound / 45)
    let yGridCount = Int(ybound / 45)
    availableGridForObjects = []  // init grid
    for x in 0...xGridCount {
      for y in 0...yGridCount {
        let frame = FrameGrid(xvalue: (x * 45) + 45, yvalue: (y * 45) + 140)
        availableGridForObjects?.append(frame)
      }
    }
  }
  
  /// newGame - Start new game
  func newGame ()  {
    correctCount = 0    // reset the score
    lblScoreBoard.text = "Correct : \(correctCount)"
    usedGridForObjects = availableGridForObjects
    selectedShapes = []  // reset grid
    shapesToChooseFrom = funFontAwesomeShapes  // make a copy of possible shaps
    addRandomItems()
  }
  
  /// addRandomItems - add radom labels with images to view
  func addRandomItems () {
    guard let shapesToChooseFrom = shapesToChooseFrom
    else {
      showAlertMessageOK(title: "Error", message: "Missing info to play game.")
      return
    }

    let getRandom = randomSequenceGenerator(min: 0, max: shapesToChooseFrom.count - 1)
    // lets give them 3 random shapes
    var shapeCount = 3
    // check to see if less than 3 available
    if (shapesToChooseFrom.count < 3) {
      shapeCount = shapesToChooseFrom.count
    }
   
    for _ in 1...shapeCount {
      let tag = getRandom()
      let label = newLabel()
      let randomColorIndex = Int.random(in: 0..<gameColors.count)
      label.textColor = gameColors[randomColorIndex]
      label.text = shapesToChooseFrom[tag]
      label.tag = tag
      var touchGesture = UITapGestureRecognizer()
      label.isUserInteractionEnabled = true
      touchGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectShape(_:)))
      label.addGestureRecognizer(touchGesture)
      self.view.addSubview(label)
    }
    
  }
  
  
  
  /// btnPlayAgain - Play game again , reset screen and start new game
  /// - Parameter recognizer: - button user  tapped
  @objc func btnPlayAgain(_ recognizer: UIPanGestureRecognizer) {
    clearScreen()
    newGame()
  }
  
  /// selectShape - Call only by selecting a new image, game continues
  /// - Parameter recognizer: label user  tapped
  ///
  @objc func selectShape(_ recognizer: UIPanGestureRecognizer) {
    let thisLabel = recognizer.view as! UILabel
    let selectedShape = Items(fontAwesomeText: thisLabel.text!, tag: thisLabel.tag, color: thisLabel.textColor, hintGiver: false)
    selectedShapes?.append(selectedShape)
    shapesToChooseFrom?.remove(at: thisLabel.tag)
    correctCount += 1
    lblScoreBoard.text = "Correct : \(correctCount)"
    nextScreen()
  }
  
  /// showResults - End of game. so show how many correct guess they made.
  /// If game over by wrong selection grey duplicated image.
  func showResults (thisLabel: UILabel?) {
    if let selectedShapes = selectedShapes {
        var count : Int =  0
        for item in selectedShapes {
          // kim was here starting ppint
          
          let xbound = Int(self.view.frame.width - 80)
          let maxRows = Int(xbound/42)
          let yrows = Int(count / maxRows)
          let yvalue = 100 + (yrows * 42)
          let adjCound = count % maxRows
          let xvalue = (42 * adjCound ) + 20
          
          let label = UILabel(frame: CGRect(x: xvalue, y: yvalue, width: 40, height: 40))
          label.font = UIFont(name: "FontAwesome", size: 30)
          label.textAlignment = .center
          label.layer.borderColor = UIColor.black.cgColor
          label.layer.borderWidth = 1
          label.textColor = item.color
          label.text = item.fontAwesomeText
          if let thisLabel = thisLabel {
            if (thisLabel.text == item.fontAwesomeText) {
              label.backgroundColor = UIColor.lightGray
            }
          }
          self.view.addSubview(label)
          count += 1
        }
    }

  }
  
  /// gameOver - Called whenuser selects duplicate image.
  /// - Parameter recognizer: label with duplicated image
  @objc func gameOver(_ recognizer: UIPanGestureRecognizer){
    clearScreen()
    let thisLabel = recognizer.view as! UILabel
    showResults (thisLabel: thisLabel)
    
    // frame calculation for last item selection (duplicate)
    let count = selectedShapes!.count
    let xbound = Int(self.view.frame.width - 80)
    let maxRows = Int(xbound/42)
    let yrows = Int(count / maxRows)
    let yvalue = 100 + (yrows * 42)
    let adjCound = count % maxRows
    let xvalue = (42 * adjCound ) + 20
    // create duplicate item
    let label = UILabel(frame: CGRect(x: xvalue, y: yvalue, width: 40, height: 40))
    label.font = UIFont(name: "FontAwesome", size: 30)
    label.textAlignment = .center
    label.layer.borderColor = UIColor.black.cgColor
    label.layer.borderWidth = 1
    label.textColor = thisLabel.textColor
    label.text = thisLabel.text
    self.view.addSubview(label)
    
    // play again button
    // put button below last row of results
    let buttonYvalue = yvalue + 100
    let button:UIButton = UIButton(frame: CGRect(x: (Int(self.view.frame.width) / 2 - 50), y: buttonYvalue, width: 100, height: 50))
    button.tag = 100
    button.backgroundColor = .systemBlue
    button.setTitle("Play Again", for: .normal)
    button.addTarget(self, action:#selector(self.btnPlayAgain), for: .touchUpInside)
    self.view.addSubview(button)
  }
  
  /// clearScreen - remove all the shape / labels and play again button
  func clearScreen () {
    // items with tag 1000 will remain, ie close button and score label
    view.subviews.forEach {
      if $0.tag != 1000 {
        $0.removeFromSuperview()
      }
    }
  }
  
  /// nextScreen - New screen with new radom images and selected images.
  func nextScreen () {
    clearScreen()
    if let shapesToChooseFrom = shapesToChooseFrom {
      if (shapesToChooseFrom.count == 0) {
        // we are out of shapes to play game..
        showAlertMessageOK(title: "Game Over", message: "Thank you for playing.  You must purchase the Paid version to have more items to choose from.")
        showResults (thisLabel: nil)
        return
      }
    }
    usedGridForObjects = availableGridForObjects // reset grid available display
    addRandomItems()
    for item in selectedShapes! {
      let label = newLabel()
      label.textColor = item.color
      label.text = item.fontAwesomeText
      // add event for selecting shape already selected
      var touchGesture = UITapGestureRecognizer()
      label.isUserInteractionEnabled = true
      touchGesture = UITapGestureRecognizer(target: self, action: #selector(self.gameOver(_:)))
      label.addGestureRecognizer(touchGesture)
      self.view.addSubview(label)
    }
   
  }
  
  /// newLabel - new label
  /// - Returns: label with unique frame  and properties
  func newLabel () -> UILabel {
    let frameIndex = Int.random(in: 0..<usedGridForObjects.count)
    let framexy = usedGridForObjects[frameIndex]
    let label = UILabel(frame: CGRect(x: framexy.xvalue , y: framexy.yvalue, width: 40, height: 40))
    label.font = UIFont(name: "FontAwesome", size: 30)
    label.textAlignment = .center
    usedGridForObjects.remove(at: frameIndex)
    return label
  }
  
  // NOT used, but keeping because I might use it...
  func removeUsedGridFrame (frameArray : [Int] ) {
    let sortedFrame = frameArray.sorted(by: {$0 > $1})
    print (sortedFrame)
    for index in sortedFrame {
      usedGridForObjects?.remove(at: index)
    }
  }
  
  /// randomSequenceGenerator
  /// - Parameters:
  ///   - min: minimum index
  ///   - max: max index
  /// - Returns: returns  unique indexs of an array
  func randomSequenceGenerator(min: Int, max: Int) -> () -> Int {
    var numbers: [Int] = []
    
    return {
      if numbers.isEmpty {
        numbers = Array(min ... max)
      }
      let index = Int(arc4random_uniform(UInt32(numbers.count)))
      return numbers.remove(at: index)
    }
  }
  
  func showAlertMessageOK (title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle:UIAlertController.Style.alert)
    
    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                              { action -> Void in
      // user has selected ok
      
    })
    
    self.present(alertController, animated: true, completion: nil)
  }
  
}
