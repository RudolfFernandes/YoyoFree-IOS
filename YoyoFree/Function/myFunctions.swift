//
//  myFunctions.swift
//  RepeatingReminder
//
//  Created by Rudy on 2021-09-27.
//

import Foundation
import AVFoundation

//var mPlayer: AVAudioPlayer?
let audioBaseName: String = "audio"

struct myFunctions {
  
  func playSound(numRepeats: Int, soundFile: String) {
    guard let path = Bundle.main.path(forResource: soundFile, ofType: "mp3") else {return}
    let url = URL(fileURLWithPath: path)
    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.numberOfLoops = numRepeats
      player?.play()
    } catch let error {
      print(error.localizedDescription)
    }
  }
  
  func voiceOnSounds(myTimeRemaining: Double, myStep: Double) {
    // Play audio using the following logic
    //  1. If over a minute, countdown every minute below 10, and beep every 30 seconds
    //  2. If 60 seconds or under, countdown 60, 50, 40...
    //  3. If 10 seconds or under, countdown 10, 9, 8...
    if (myTimeRemaining > 11 ) {
      let factorTimeRemaining = Int(myTimeRemaining/myStep)
      let factorTimeStep = Int(1/myStep)    // Assumes myStep is 1 or less (typically 0.1)
      let factorMinute = 60 * factorTimeStep
      let factorTen = 10 * factorTimeStep
      
      if (factorTimeRemaining % factorMinute == 0) {
        playSound(numRepeats: 1, soundFile: audioBaseName + String(factorTimeRemaining/factorMinute))
      } else if (factorTimeRemaining < factorMinute && factorTimeRemaining % factorTen == 0) {
        playSound(numRepeats: 1, soundFile: audioBaseName + String(factorTimeRemaining/factorTimeStep))
      } else if (factorTimeRemaining % (factorTen * 3) == 0){
        playSound(numRepeats: 1, soundFile: "beep_halfway")
      }
      
    } else {
      
      if  (myTimeRemaining >= 1) {
        let myIntTime = Int(myTimeRemaining)
        if ( ((myTimeRemaining - (Double(myIntTime))) < myStep) ) {
          playSound(numRepeats: 1, soundFile: audioBaseName + String(myIntTime))
        }
      }
    }
  }
  
  func getShuttleMilliSeconds (mySpeedMetersPerHour: Int, noShuttles: Int, correctionMilliSecs: Int) -> Int {
//    print ("mySpeedMetersPerSecond: \(mySpeedMetersPerSecond)   myShuttleDistance: \(myShuttleDistance)")
    
    
//    print ("correctionMilliSecs: \(correctionMilliSecs)")
    
    // Apply correction, if any. Factore tried (iphone 7): 15:10, 13:10, 10:10
    // Turns out, most correction can be effected in the rest period
    let msPerShuttle: Int = Int ((Double(MYSHUTTLEDISTANCE * 1000)) / (Double(mySpeedMetersPerHour)/3600))
        - ((correctionMilliSecs * 13) / (noShuttles * 10))
    
    
    // Need to round this to the nearest timerStep millisecs
    let roundFactor = Int(timerStep * 1000)
    
    print ("msPerShuttle: \(msPerShuttle)    Rounded: \(((msPerShuttle+roundFactor)/roundFactor) * roundFactor)")

    return ((msPerShuttle+roundFactor)/roundFactor) * roundFactor
  }
  
  func showTime (myMilliSeconds: Int) -> String {
    let myTime: Double = Double(myMilliSeconds)/1000
    var myMinutes: Int = 0
    var mySeconds: Int = 0
    myMinutes = Int(myTime / 60)
    mySeconds = (Int(myTime) - (myMinutes * 60))
    
    return String(format: "%d", myMinutes) + ":"
      + String(format: "%02d", mySeconds)
  }
  
  func calcVo2Max (myMetersRun: Int) -> Double {
    // Applicable only for Recovery Level 1, provided at least 1000m run
    return ((Double(myMetersRun) * 0.0084) + 36.4)
  }
}
