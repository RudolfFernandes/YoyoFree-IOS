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
  
  /// Calculates the total milliseconds that should elapse (since the start) at the end of a specific level
  /// Will be used to adjust the time for the next level
  /// - Returns: Total milliseconds that should have elapsed at the end of a level
  func getExpectedRunningMs (mLevel: Int) -> Int {
    var i = 0
    var totMs = 0
    while (i < mLevel) {
      totMs += (levelShuttles[i] * MYSHUTTLEDISTANCE * 3600 * 1000) / levelSpeedMetersPerHour[i]
      
      // 29Jan2022. Significant bug (Endurance goes for a toss) -- changed next line
      //      totMs += levelShuttles[i] * 10 * 1000 / 2     // Rest secs
      totMs += levelShuttles[i] * RESTMILLISECS / 2     // Rest secs
      i += 1
    }
    return totMs
  }
  
  func getShuttleMilliSeconds (myLevel: Int, correctionMilliSecs: Int) -> Int {
//    print ("mySpeedMetersPerSecond: \(mySpeedMetersPerSecond)   myShuttleDistance: \(myShuttleDistance)")
    
    
//    print ("correctionMilliSecs: \(correctionMilliSecs)")
    
    // Apply correction, if any.
    // Turns out, most correction can be effected in the rest period
    // 10000: 15-1.5s back; 12000: 21-2s back; 14000: 19-1.5s back; 16000: 19-1.5s back;
    let baseMsPerShuttle = Int ((Double(MYSHUTTLEDISTANCE * 1000)) / (Double(levelSpeedMetersPerHour[myLevel-1])/3600))
    
    var extrapolatedCorrectMs = correctionMilliSecs
    if (myLevel > 1) {      // Can't do this for Level 1
      // Increase the correction proportionately
      extrapolatedCorrectMs = correctionMilliSecs * levelShuttles[myLevel-1] / levelShuttles[myLevel-2]
    }
    let msPerShuttle = baseMsPerShuttle - ((extrapolatedCorrectMs * 11) / (levelShuttles[myLevel-1] * 10))
    
    // Need to round this to the nearest timerStep millisecs
    let roundFactor = Int(timerStep * 1000)
    
//    print ("msPerShuttle: \(msPerShuttle)    Rounded: \(((msPerShuttle+roundFactor)/roundFactor) * roundFactor)")

    return ((msPerShuttle+roundFactor)/roundFactor) * roundFactor
  }
  
//  func getShuttleMilliSeconds (mySpeedMetersPerHour: Int, noShuttles: Int, correctionMilliSecs: Int) -> Int {
////    print ("mySpeedMetersPerSecond: \(mySpeedMetersPerSecond)   myShuttleDistance: \(myShuttleDistance)")
//
//
////    print ("correctionMilliSecs: \(correctionMilliSecs)")
//
//    // Apply correction, if any. Factore tried (iphone 7): 135:100, 145:199, 13:10
//    // Turns out, most correction can be effected in the rest period
//    // 10000: 15-1.5s back; 12000: 21-2s back; 14000: 19-1.5s back; 16000: 19-1.5s back;
//    let baseMsPerShuttle = Int ((Double(MYSHUTTLEDISTANCE * 1000)) / (Double(mySpeedMetersPerHour)/3600))
//
//    let msPerShuttle: Int = Int ((Double(MYSHUTTLEDISTANCE * 1000)) / (Double(mySpeedMetersPerHour)/3600))
//        - (correctionMilliSecs  * 12000) / (noShuttles * baseMsPerShuttle)
//
//
//    // Need to round this to the nearest timerStep millisecs
//    let roundFactor = Int(timerStep * 1000)
//
////    print ("msPerShuttle: \(msPerShuttle)    Rounded: \(((msPerShuttle+roundFactor)/roundFactor) * roundFactor)")
//
//    return ((msPerShuttle+roundFactor)/roundFactor) * roundFactor
//  }
  
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
