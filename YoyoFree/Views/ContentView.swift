//
//  ContentView.swift
//  YoyoFree
//
//  Created by Rudy on 2021-10-25
//  Copied from BleepUKP
/*
 26Oct2021. 1/1.0. Deployed on AppStore
 29Dec2021. 2/1.0.23. Added spanish sounds (
 Procedure:
 1. "Localize" all audio files, checking the relevant <lang> in the File Inspector window
 This is done one at a time. Xcode copies the base file into the <lang> directory
 2. Expand any audio <file>. You will see the (Base) file, along with the (Lang) file
 2. Picking the <lang> file, right-click to "Show in Finder"
 3. In the Finder window, named <lang>.lproj, replace ALL the files with the
 actual <lang> audio files
 29De2021. 3/1.0.24 Modified calculation of radius to be based on width of device
  Corrected the app name (General - Display name)
  Modified target to 15.0
 16Jan2022. 5/1.0.25. Removed stoprun() from quotealert code
  Added StopAlertView to handle the stopAlert (when confirmStop is true), else alert is unresponsive
  When confirmStop, switched showStopAlert handling into dispatchqueue
 20Jan2022. 6/1.0.26. Modified "end of run" check
  Added ZoomableView to LapsImageView, ResultView
 29Jan2022. 7/1.0.27. Added yyenonorms.png
    Endurance Timing is off. Fixed MyFunctions.getExpectedRunningMs
    Endurance images (yoyoie1, yoyoie2) were incorrect (assumed 10 sec rest). Fixed
    Added image, yyenonorms for ResultView
 03Feb2022. 8/1.0.28. Fixed getSpeedLevel bug (affected endurance level display)
    Fixed display of Endurance speed (2 decimal places)
    Fixed level cue of levels like 13.5
    timerStep 0.25 (not sure when this was changed)
 06Feb22. 9/1.0.29. Fixed voicecue bug related to timerStep change (see playedLevelCue code)
 18Feb22. 10/1.0.30. Added German, Portuguese, Italian
      Some minor UI changes
 18Apr22. 11/1.0.31. Added "Rate the app" functionality. See doAppReview()
 */

import SwiftUI
import AVFoundation
import MessageUI
import MediaPlayer
import CoreMotion
import StoreKit

let MYSHUTTLEDISTANCE: Int = 20
var levelSpeedMetersPerHour = [Int] ()
var levelShuttles = [Int] ()
let COUNTDOWNMILLISECS = 5000
var RESTMILLISECS = 10000
var restBeepIntervalMs = 10000
var restedSinceBeepMs = 0
let MINVO2MAXMETERS = 1000
let timerStep: Double = 0.25      // Max cpu: 0.25-4%, 0.20-5%, 0.10-10%, 0.05-20%; 0.01-60; 0.2-42
var restAdjustMillis: Int = 0
var playedRest: Bool = true
var oldSecs: Int = 0

// Define & Initialize the arrays that define the speed and # of shuttles at
// each level for each Yoyo variant
// Speed will be in meters per hour, shuttles will be 20 m length

//// Yoyo Recovery ... simulates soccer, rugby, hockey, etc
//// the last array value, 0, is a signal to stop
let Rlevel1speed = [10000, 12000, 13000, 13500, 14000, 14500, 15000, 15500, 16000, 16500,                 17000, 17500, 18000, 18500, 19000, 0 ]
let Rlevel1shuttles = [ 2, 2, 4, 6, 8, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 0 ];
let Rlevel2speed = [ 13000, 15000, 16000, 16500, 17000, 17500, 18000, 18500, 19000, 19500,                20000, 20500, 21000, 21500, 22000, 0 ];
let Rlevel2shuttles = [ 2, 2, 4, 6, 8, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 0 ];

// Yoyo Endurance ... closer to Beep test
let Elevel1speed = [ 8000, 9000, 10000, 10500, 10750, 11000, 11250, 11500, 11750, 12000, 12250, 12500, 12750, 13000, 13250, 13500, 13750, 14000, 14250, 14500, 0 ];
let Elevel1shuttles = [ 4, 4, 4, 16, 16, 16, 6, 6, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0 ];
let Elevel2speed = [ 11500, 12500, 13500, 14000, 14250, 14500, 14750, 15000, 15250, 15500, 15750, 16000, 16250, 16500, 16750, 17000, 17250, 17500, 17750, 18000, 0 ];
let Elevel2shuttles = [ 4, 4, 4, 16, 16, 16, 6, 6, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 0 ];

let appName = NSLocalizedString("app-name", comment:"")
let appName2 = NSLocalizedString("app-name2", comment:"")

var currentLevel: Int = 1
var shuttlesAtLevel: Int = 0
var shuttlesDoneAtLevel: Int = 0
var stopTheRun = false

var totCountdownMilliSecs = 0
var totMilliSecsRun: Int = 0
var totRestMilliSecs: Int = 0
var totShuttlesRun: Int = 0
var playedLevelCue: Bool = true
var playedHalfwayBeep: Bool = false
var startTime: Date = Date()
var stopAlertStepCount: Int = 0
var resultViewCalled: Bool = false

//UIScreen.main.bounds.size.width - ipad: 1024; 8+: 414; 11ProMax:414
// Need ipad to be twice the size of 8+, 11Promax
let radius: CGFloat = 40 + UIScreen.main.bounds.size.width/5       // was 120
let linewidth: CGFloat = radius/15                                // was 10

// Fix frame dimensions. Avoids issues with device orientation changes
let framewidth = UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width ? UIScreen.main.bounds.size.width : UIScreen.main.bounds.size.height
let frameheight = UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width ? UIScreen.main.bounds.size.height : UIScreen.main.bounds.size.width

var player: AVAudioPlayer?

var checkVolume: Bool = false
var myVolume: Float = 0.0
let audioSession = AVAudioSession.sharedInstance()
let volumeView = MPVolumeView()

var motionManager: CMMotionManager!
let MIN_MOVEMENT = 0.1
let NODIFF_LIMIT = 10
var oldXY:Double = 0.0
var noDifference = 0

let developerEmail: [String] = ["rudolf.fernandes@gmail.com"]

// Expresso Quotation database
let myDb : String = "expresso.sqlite"
var myQuote: String = ""

class theSetting: ObservableObject {
  @Published var confirmStop: Bool = UserDefaults.standard.bool(forKey: "confirmStop")
  @Published var autoStop: Bool = UserDefaults.standard.bool(forKey: "autoStop")
  
  @Published var voiceOn: Bool = UserDefaults.standard.bool(forKey: "voiceOn")
  @Published var fixVolume: Bool = UserDefaults.standard.bool(forKey: "fixVolume")
  @Published var halfwayBeep: Bool = UserDefaults.standard.bool(forKey: "halfwayBeep")
  @Published var doVibrate: Bool = UserDefaults.standard.bool(forKey: "doVibrate")
  //  @Published var currentLevelSpeedMetersPerHour: Int = levelSpeedMetersPerHour[0]
}

class theInfo: ObservableObject {
  @Published var myLevelShuttle: String = ""
  @Published var myLapsImage: String = ""
  @Published var myNormsImage: String = ""
  @Published var myDistance: Int = 0
}

struct ContentView: View {
  
  @State private var isRunning = false
  @State private var showReset = false
  @State private var isCountingDown = false
  @State private var isResting = false
  @State var currentLevelSpeedMetersPerHour: Int = 0
  @State var levelMilliSeconds: Int = 60000
  @State var shuttleMilliSeconds: Int = 6000
  @State var levelMilliSecondsRemaining: Int = 60000
  @State var shuttleMilliSecondsRemaining: Int = 6000
  @State private var myFunction: myFunctions = myFunctions()
  @State private var hasTimeElapsed = false
  @State private var showingAlert: Bool = false
  @State private var showStopAlert: Bool = false
  @State private var showVolumeAlert: Bool
  @State private var showQuoteAlert: Bool = false
  @State private var autoStopped: Bool = false
  @State var restSecsLeft: Int = 0
  @State var theTime = "0:00"
  
  let testTypeArray = [
    NSLocalizedString("recovery", comment:"") + " " + NSLocalizedString("level", comment:"") + " 1",
    NSLocalizedString("recovery", comment:"") + " " + NSLocalizedString("level", comment:"") + " 2",
    NSLocalizedString("endurance", comment:"") + " " + NSLocalizedString("level", comment:"") + " 1",
    NSLocalizedString("endurance", comment:"") + " " + NSLocalizedString("level", comment:"") + " 2",
  ]
  
  @StateObject var mySetting = theSetting()
  @StateObject var myInfo = theInfo()
  
  //0-R1, 1-R2, 2-E1, 3-E2
  @State var testTypeElement: Int = UserDefaults.standard.integer(forKey: "testType")
  
  // For email
  @State var result: Result<MFMailComposeResult, Error>? = nil
  @State var isShowingMailView = false
  
  let timer = Timer.publish(every: timerStep, on: .main, in: .common).autoconnect()
  init() {
    
    // Check that volume is above 0.8
    checkVolume = UserDefaults.standard.bool(forKey: "checkVolume")
    do {
      try audioSession.setActive(true)
    } catch {
      print("Failed to activate audio session")
    }
    if (checkVolume) {
      showVolumeAlert = true
      myVolume = audioSession.outputVolume
    } else {
      showVolumeAlert = false
    }
    
    
    initDefaultSettings()
    // Running initNumbers() in init gives a warning: "Accessing StateObject's object without
    //  being installed on a View. This will create a new instance each time." Couldn't figure
    //  out what it means, but the solution is to "inject" into the view by executing
    //  initnumbers() in an .onappear attached to any element in the view. I've added it to
    //  Text(appName)
    //     initNumbers()
  }
  
  var body: some View {
    NavigationView {
      VStack(spacing: -10) {
        
        VStack {
          Text(appName)
            .font(.largeTitle)
            .foregroundColor(.yellow)
            .padding(.bottom, -5)
          //            .scaleEffect(1.1, anchor: .center)
            .onAppear {
              
              if (!resultViewCalled) {
                initNumbers()
                motionManager = CMMotionManager()
                copyExpressoDBOnce()
              }
              
            }
          
          if (!isRunning) {
            Picker(selection: $testTypeElement, label: Text("test-type")) {
              ForEach(0 ..< testTypeArray.count) {
                Text(String(testTypeArray[$0]))
              }
            }.pickerStyle(DefaultPickerStyle())
              .scaleEffect(1.5, anchor: .center)
              .onChange(of: testTypeElement) { _ in
                UserDefaults.standard.set(testTypeElement, forKey: "testType")
                //              assignSpeedShuttleArray()
                initNumbers()
              }
          } else {
            Text(String(testTypeArray[testTypeElement]))
              .font(.title)
              .foregroundColor(.green)
              .padding(.bottom, -5)
              .padding(.top, -5)
          }
        }
        .padding(.bottom)
        
        if (isRunning || showReset) {
          Text(
            // 18Feb22. Commented next line
//            NSLocalizedString("total", comment:"") + " " +
              theTime
               + " [\(totShuttlesRun * MYSHUTTLEDISTANCE) m]")
//            Text(NSLocalizedString("total", comment:"")
//               + " \(myFunction.showTime(myMilliSeconds: totMilliSecsRun)) [\(totShuttlesRun * MYSHUTTLEDISTANCE) m]")
            .font(.title2)
            .foregroundColor(.white)
            .padding(.top, 5).padding(.bottom)
        }
        
        HStack (spacing: -10){
          if (showReset && autoStopped) {
            Text ("auto-stopped")
              .font(.callout).scaleEffect(1, anchor: .center)
              .foregroundColor(.yellow)
          }
          if (!isRunning && !showReset) {
            if (mySetting.confirmStop) {
              Text ("confirm-stop")
                .font(.callout).scaleEffect(0.5, anchor: .center)
                .foregroundColor(.green)
            }
            if (mySetting.autoStop) {
              Text ("auto-stop")
                .font(.callout).scaleEffect(0.5, anchor: .center)
                .foregroundColor(.green)
            }
          }
        }
        .padding(.leading, 20).padding(.trailing, 20)
        
        VStack (spacing: -30) {
          ZStack {
            Circle().stroke(Color.gray.opacity(0.2),
                            style: StrokeStyle(lineWidth: linewidth*1.5, lineCap: .round))
              .scaleEffect(1.5, anchor: .center)
              .frame(width:radius, height: radius * 2)
            
            Circle()
              .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: 1 - CGFloat(CGFloat(levelMilliSeconds - levelMilliSecondsRemaining) / CGFloat(levelMilliSeconds)))
              .stroke(Color.green, style: StrokeStyle(lineWidth: linewidth/1.5, lineCap: .round))
              .rotationEffect(.degrees(-90))
              .animation(.easeInOut(duration: 2), value: 1)
//                          .animation(.easeInOut)
            //              .animation(.linear(duration: 2), value: levelMilliSeconds)
              .scaleEffect(1.5, anchor: .center)
              .frame(width:radius+linewidth/1.5, height: (radius+linewidth/1.5) * 2)
            
            Circle()
              .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: 1 - CGFloat(CGFloat(shuttleMilliSeconds - shuttleMilliSecondsRemaining) / CGFloat(shuttleMilliSeconds)))
              .stroke(Color.yellow, style: StrokeStyle(lineWidth: linewidth/1.5, lineCap: .round))
              .rotationEffect(.degrees(-90))
//              .animation(.easeIn, value: timerStep*20)
//                          .animation(.default)
            //              .animation(.linear(duration: 2), value: shuttleMilliSeconds)
              .scaleEffect(1.5, anchor: .center)
              .frame(width:radius-linewidth/2, height: (radius-linewidth/2) * 2)
            
            VStack (spacing: (10)){
              if (testTypeElement < 2) {   // Recovery
                Text("\(getSpeedLevel(speedMetersPerHour: currentLevelSpeedMetersPerHour)):\(shuttlesDoneAtLevel/2)").font(.title)
                  .scaleEffect(isRunning ? 1.8 : 1.6)
              } else {    // Endurance
                Text("\(getSpeedLevel(speedMetersPerHour: currentLevelSpeedMetersPerHour)):\(shuttlesDoneAtLevel/2)").font(.title)
                  .scaleEffect(isRunning ? 1.5 : 1.3)
              }
              
              if (!isRunning && showReset && (testTypeElement == 0)
                  && (totShuttlesRun * MYSHUTTLEDISTANCE >= MINVO2MAXMETERS)) {
                
                Text(String(format: "Vo2Max %.1f", myFunction.calcVo2Max(myMetersRun: totShuttlesRun * MYSHUTTLEDISTANCE)))
                  .font(.title3).padding(.top, 5)
              } else {
                  if (testTypeElement < 2) {   // Recovery
                    Text(String(format: "%.1f km/h", Double(currentLevelSpeedMetersPerHour)/1000))
                      .font(.title3).padding(.top, 5).padding(.bottom, -15)
                  } else {   // Endurance
                    Text(String(format: "%.2f km/h", Double(currentLevelSpeedMetersPerHour)/1000))
                      .scaleEffect(framewidth > 400 ? 0.9 : 0.75, anchor: .center)
                      .font(.title3).padding(.top, 5).padding(.bottom, -15)
                  }
              }
            }
            // 18Feb22. Moved this out of the vStack (level display was gettng corrupt)
            if (isResting) {
              Text(String(format: "%d", restSecsLeft))
                .font(.largeTitle)
                .foregroundColor(.gray)
                .scaleEffect(1.0, anchor: .center)
                .padding(.bottom, (framewidth > 600 ? framewidth/6 : framewidth/3.4))
            }
            
          }
          .frame(width:radius, height: radius * 2)
        }
        
        HStack (spacing: -10){
          if (!isRunning && !showReset) {
            if (mySetting.voiceOn) {
              Text ("voice-on")
                .font(.callout).scaleEffect(0.5, anchor: .center)
                .foregroundColor(.yellow)
            }
            if (mySetting.fixVolume) {
              Text ("fix-volume")
                .font(.callout).scaleEffect(0.5, anchor: .center)
                .foregroundColor(.yellow)
            }
            if (mySetting.halfwayBeep) {
              Text ("halfway-beep")
                .font(.callout).scaleEffect(0.5, anchor: .center)
                .foregroundColor(.yellow)
            }
            if (mySetting.doVibrate) {
              Text ("do-vibrate")
                .font(.callout).scaleEffect(0.5, anchor: .center)
                .foregroundColor(.yellow)
            }
          }
        }
        .padding(.leading, 20).padding(.trailing, 20)
        
        
        HStack(spacing: 15) {
          
          // Required to show responsive alert while timer is running
          // Placed here because it appears to take a tiny bit of space
          StopAlertView(showStopAlert: $showStopAlert)
          
          if (!isRunning && !showReset) {
            Button(action: {
              showingAlert = true
            }, label: {
              Image(systemName: "info.circle")
            })
              .alert(isPresented: $showingAlert) {
                Alert(title: Text("howto"),
                      message: Text("howto-msg"),
                      dismissButton: .default(Text("ok")))
              }
              .font(.title)
          }
          
          if (!isRunning && !showReset) {
            Button(action: {
              self.isShowingMailView.toggle()
            }, label: {
              Image(systemName: "envelope.fill")
            })
              .font(.title)
              .disabled(!MFMailComposeViewController.canSendMail())
              .sheet(isPresented: $isShowingMailView) {
                MailView(isShowing: self.$isShowingMailView, result: self.$result,
                         mailRecipients: developerEmail,
                         mailSubject: NSLocalizedString("app-name", comment: "") + " - "
                         + NSLocalizedString("query-comment", comment: ""),
                         mailMessageBody: """
                        <br>
                        _________________________<br>
                        """ + NSLocalizedString("write-above", comment: "")
                         + """
                        <br><br>
                        
                        \(getSettings())
                        """)
              }
          }
          
          if (isRunning || !showReset) {
            Label ("",
                   systemImage: "\(isRunning ? "xmark" : "play.fill")")
              .labelsHidden()
              .foregroundColor(isRunning ? .red : .green)
              .font(.largeTitle)
              .scaleEffect(1.5, anchor: .center)
              .onTapGesture(perform: {
                
                if (!isRunning) {
                  isRunning = true
                  // Prevent screen from dimming/going off
                  UIApplication.shared.isIdleTimerDisabled = true
                  
                  initSettings()
                  initNumbers()
                  
                  if (mySetting.autoStop) {
                    motionManager.startAccelerometerUpdates()
                    noDifference = 0
                    oldXY = 0.0
                    autoStopped = false
                  }
                  
                  isCountingDown = true
                  showReset = true
                } else {
                  
                  if (mySetting.confirmStop) {
                    //16Jan22. Modified to trigger stop alert thru a view of its own
                    //  This eliminates the responsiveness problem cause by a small timerStep (which requires a lot
                    //    or re-rendering of this main view)
                    // StopAlertView triggers stopRun() through a global variable, stopTheRun
                    showStopAlert = true          // this will trigger alert via StopAlertView (call is above)
                    
                    // 15Jan2022. Added dispatchqueue (commented code in onRecieve)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {showStopAlert = false})
                  } else {
                    stopRun()
                  }
                }
              })
              .padding()
          }
          
          if (!isRunning && showReset) {
            Label ("", systemImage: "gobackward")
              .foregroundColor(.orange)
              .font(.title)
              .scaleEffect(1.5, anchor: .center)
              .onTapGesture(perform: {
                initNumbers()
                showReset = false
                
                // Show a quote -- getQuote decides whether it's time or not
                myQuote = getQuote()
                
                // If myQuote has some length, show it
                if (myQuote.count > 0) {
                  showQuoteAlert = true
                } else {
                  doAppReview()
                }
              })
          }
          if (!isRunning && !showReset) {
            
            NavigationLink(destination: LapsImageView().environmentObject(self.myInfo)) {
              Image(systemName: "tablecells.badge.ellipsis")
                .foregroundColor(.green)
                .font(.title)
            }
            
            NavigationLink(destination: SettingsView().environmentObject(self.mySetting)) {
              Image(systemName: "gear")
                .foregroundColor(.gray)
                .font(.title)
            }
          }
          
          if (!isRunning && showReset) {
            
            NavigationLink(destination: ResultView().environmentObject(self.myInfo)) {
              Image(systemName: "person.3.fill")
                .foregroundColor(.green)
                .font(.title)
                .scaleEffect(1.2, anchor: .center)
            }.simultaneousGesture(TapGesture().onEnded{
              resultViewCalled = true   // used to prevent onAppear initialization
            })
          }
          
        }.padding(.top)
        
        if (showVolumeAlert && (myVolume < 0.8)) {
          Text("").alert(isPresented: $showVolumeAlert, content: {
            Alert(title: Text("volume-low"),
                  message: Text("volume-low-msg"),
                  primaryButton:  Alert.Button.default(
                    Text("ok"), action: {
                      showVolumeAlert = false
                    }
                  ),
                  secondaryButton: Alert.Button.default(
                    Text("dont-show-again"), action: {
                      showVolumeAlert = false
                      UserDefaults.standard.set(false, forKey: "checkVolume")
                    }
                  )
            )
          })
        }
        
        if (showQuoteAlert) {
          Text("").alert(isPresented: $showQuoteAlert, content: {
            Alert(title: Text(""),
                  message: Text(myQuote),
                  dismissButton: Alert.Button.default(
                    Text("close"), action: {
                      showQuoteAlert = false
                    }
                  )
            )
          })
        }
        
      }
      .onReceive(timer, perform: { _ in
        guard isRunning  else { return }
        
        // stopTheRun works with StopAlertView
        if (stopTheRun) {
          stopRun()
        }
        
        // If autoStop is on, start checking for movement
        if (mySetting.autoStop && !isCountingDown) {
          var newXY:Double = 0.0
          motionManager.accelerometerUpdateInterval = 0.3
          motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
            newXY = (data?.acceleration.x ?? 0.00) + (data?.acceleration.y ?? 0.00)
            
            if (oldXY - newXY >= MIN_MOVEMENT) {
              noDifference = 0
            } else {
              noDifference += 1
              if (noDifference > NODIFF_LIMIT) {
                autoStopped = true
                stopRun()
              }
            }
            oldXY = newXY
          }
        }
        
        if (isCountingDown) {
          if (totCountdownMilliSecs % 1000 == 0) {
            myFunction.playSound(numRepeats: 0, soundFile: "level\((COUNTDOWNMILLISECS - totCountdownMilliSecs)/1000)")
          }
          totCountdownMilliSecs += Int(timerStep*1000)
          
          if (totCountdownMilliSecs == COUNTDOWNMILLISECS) {
            myFunction.playSound(numRepeats: 0, soundFile: "beep2")
            isCountingDown = false
            startTime = Date()
            myVolume = audioSession.outputVolume
          }
          return
        }
        
        if (isResting) {
          
          // The following line appears to be very cpu-intensiv3 (CPU during rest -iphone7- jumps by 10-15%)
          //    Replaced with restedSinceBeepMs, restBeepIntervalMs
          // if ((totRestMilliSecs % (restAdjustMillis/(RESTMILLISECS/1000)) < Int(timerStep * 1000)) && !playedRest) {
          if (restedSinceBeepMs >= restBeepIntervalMs) {

            restedSinceBeepMs = 0
            myFunction.playSound(numRepeats: 0, soundFile: "built_in_rest_beep")
//            restSecsLeft = Int((RESTMILLISECS-totRestMilliSecs)/1000)
            restSecsLeft -= 1
            
            playedRest = true
            //            print ("totRestMilliSecs: \(totRestMilliSecs)   restAdjustMillis/(RESTMILLISECS/1000): \(restAdjustMillis/(RESTMILLISECS/1000))")
            //            print ("restSecsLeft: \(restSecsLeft)")
            //              print ("restCorrection: \(restAdjustMillis * 4 / 10)")
          } else {
            playedRest = false
          }
          
          //          print ("restAdjustMillis: \(restAdjustMillis)")
          restedSinceBeepMs += Int(timerStep*1000)
          totRestMilliSecs += Int(timerStep*1000)
          totMilliSecsRun += Int(timerStep*1000)
          setTime()     // for the seconds display
          
          //          if (totRestMilliSecs >= RESTMILLISECS-(restAdjustMillis * 2)) {
          if (totRestMilliSecs >= restAdjustMillis) {
            
            if (shuttlesDoneAtLevel == 0) { // Level had finished
              myFunction.playSound(numRepeats: 0, soundFile: "beep2")
            } else {
              myFunction.playSound(numRepeats: 0, soundFile: "beep")
            }
            isResting = false
            //            print("Rest Ended : \(Int(Date().timeIntervalSince(startTime) * 1000))")
            totRestMilliSecs = 0
            restedSinceBeepMs = 0
          }
          return
        }
        
        // Shuttle completed
        if (shuttleMilliSecondsRemaining <= 0) {
          
          if (mySetting.fixVolume) {
            if let view = volumeView.subviews.first as? UISlider {
              view.value = myVolume
            }
          }
          shuttlesDoneAtLevel += 1
          
          // Avoid conflict with Rest beep
          if (shuttlesDoneAtLevel % 2 == 1) {
            myFunction.playSound(numRepeats: 0, soundFile: "beep")
          }
          
          if (shuttlesDoneAtLevel % 2 == 0) {
            
            //            print("Rest started : \(Int(Date().timeIntervalSince(startTime) * 1000))")
            // Tried 32:40, 30:40, 39:40, 34:40 (21-4s behind), 36:40 (18-3s behind), 365:400 (17-1.5s behind)
            //    37:40, 35:40 (20-3s behind), 355:400 (14-2s behind), 365:400 (14-2sec back)
            restAdjustMillis = RESTMILLISECS - (Int(Date().timeIntervalSince(startTime) * 1000)
                                                - (totMilliSecsRun)) * 365 / 400
            //            print ("restAdjustMillis: \(restAdjustMillis)")
                      
            totMilliSecsRun += RESTMILLISECS - restAdjustMillis
//            setTime()     // for the seconds display
            restBeepIntervalMs = restAdjustMillis / (RESTMILLISECS/1000)
            
            isResting = true
            restSecsLeft = RESTMILLISECS/1000
            myFunction.playSound(numRepeats: 0, soundFile: "built_in_rest_beep")
            
          }
          totShuttlesRun += 1
          shuttleMilliSecondsRemaining = shuttleMilliSeconds
          
          if (mySetting.doVibrate) {
            vibrate()
          }
          playedHalfwayBeep = false
        }
        
        // 24Jan2022. Added next IF so that, during rest just before next level, the current level is shown
        if (isResting) {
          return
        }
        
        // Play halfway beep
        if (mySetting.halfwayBeep && !playedHalfwayBeep) {
          if (shuttleMilliSecondsRemaining < shuttleMilliSeconds/2) {
            myFunction.playSound(numRepeats: 0, soundFile: "beep_halfway")
            playedHalfwayBeep = true
          }
        }
        
        if levelMilliSecondsRemaining >= Int(timerStep*1000) {
          
          // Play speed level cue a little bit after the level beep is done
          if (!playedLevelCue && mySetting.voiceOn) {
            // 06Feb22. Modified next line. Can fail if timerStep doesn't match
//            if (levelMilliSeconds-levelMilliSecondsRemaining == 800) {
            if (levelMilliSeconds-levelMilliSecondsRemaining > 500) {
              if (currentLevelSpeedMetersPerHour % 500 == 0) {
                myFunction.playSound(numRepeats: 0, soundFile: "level\(getSpeedLevel(speedMetersPerHour: currentLevelSpeedMetersPerHour))")
              } else {
                myFunction.playSound(numRepeats: 0, soundFile: "level\(getSpeedLevel(speedMetersPerHour: (currentLevelSpeedMetersPerHour / 500) * 500))")
              
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                  myFunction.playSound(numRepeats: 0, soundFile: "level5")}
                )
              }
              
              playedLevelCue = true
            }
          }
          
        } else {    // Level completed
          
          shuttlesDoneAtLevel = 0
          currentLevel += 1
          playedLevelCue = false
          
          // Conflicts with Rest beep
          //          myFunction.playSound(numRepeats: 0, soundFile: "beep2")
          
          // 20Jan2022. Modified next line [crashes reported... obviously!]
          //          if (currentLevel > 17) {
          if (levelSpeedMetersPerHour[currentLevel-1] == 0) {
            stopRun()
          } else {
            let missedMs = Int(Date().timeIntervalSince(startTime) * 1000) - myFunction.getExpectedRunningMs(mLevel: currentLevel-1)
            
            let lostMilliSecs = Int(Date().timeIntervalSince(startTime) * 1000) - totMilliSecsRun
            
//            print ("Tag: \(currentLevel). lostMilliSecs = \(lostMilliSecs), missedMs = \(missedMs)")
            
            totMilliSecsRun += lostMilliSecs
//            setTime()     // for the seconds display
            
            currentLevelSpeedMetersPerHour = levelSpeedMetersPerHour[currentLevel-1]
            shuttlesAtLevel = levelShuttles[currentLevel-1]
            
            // Fix Rest periods. Tried 40:10 (30 secs fast thru entire test), 30:10, 27:10
            //            restAdjustMillis = RESTMILLISECS - ((lostMilliSecs * 27) / (shuttlesAtLevel * 10))
            
//            shuttleMilliSeconds = myFunction.getShuttleMilliSeconds (
//              mySpeedMetersPerHour:  currentLevelSpeedMetersPerHour,
//              noShuttles: shuttlesAtLevel, correctionMilliSecs: lostMilliSecs)
            shuttleMilliSeconds = myFunction.getShuttleMilliSeconds(myLevel: currentLevel, correctionMilliSecs: lostMilliSecs+missedMs)
            levelMilliSeconds = shuttleMilliSeconds * shuttlesAtLevel
            
            
            self.levelMilliSecondsRemaining = levelMilliSeconds
            self.shuttleMilliSecondsRemaining = shuttleMilliSeconds
          }
        }
        
        totMilliSecsRun = totMilliSecsRun + Int(timerStep*1000)
        setTime()     // for the seconds display
        levelMilliSecondsRemaining = levelMilliSecondsRemaining - Int(timerStep*1000)
        shuttleMilliSecondsRemaining = shuttleMilliSecondsRemaining - Int(timerStep*1000)
      })
    }
    .padding(.top, -100)
    .environmentObject(mySetting)
    .navigationViewStyle(StackNavigationViewStyle())  // ipad; else, blank screen
  }
  
  func getSpeedLevel(speedMetersPerHour: Int) -> String {
    let adjustedSpeed = (speedMetersPerHour-7500) * 2
    
    if (adjustedSpeed % 1000 == 0) {
      return String(format: "%.0f", Double(adjustedSpeed)/1000)
    }
//    if (adjustedSpeed % 500 == 0) {
      return String(format: "%.1f", Double(adjustedSpeed)/1000)
//    }
//    return String(format: "%.2f", Double(adjustedSpeed/1000))
  }
  
  /// Used to reduce calls to myFunction.showtime to once every second. Earlier the call was every millisecond
  ///     resulting into significant CPU usage
  func setTime () {
    if (totMilliSecsRun / 1000 != oldSecs) {
      theTime = myFunction.showTime(myMilliSeconds: totMilliSecsRun)
      oldSecs = totMilliSecsRun / 1000
    }
  }
  
  func stopRun() {
    isRunning = false
    isResting = false
    stopTheRun = false
    
    myInfo.myDistance = totShuttlesRun * MYSHUTTLEDISTANCE
    
    // Allow screen to dim/go off
    UIApplication.shared.isIdleTimerDisabled = false
    
    if (mySetting.autoStop) {
      motionManager.stopAccelerometerUpdates()
      if (autoStopped) {
        myFunction.playSound(numRepeats: 2, soundFile: "auto_stop")
      }
    }
    
    //Fix Level display if shuttlesDoneAtLevel = 0
    if (shuttlesDoneAtLevel == 0 && currentLevel > 1) {
      currentLevel -= 1
      currentLevelSpeedMetersPerHour = levelSpeedMetersPerHour [currentLevel-1]
      shuttlesDoneAtLevel = levelShuttles [currentLevel-1]
    }
    myInfo.myLevelShuttle = String(currentLevel) + ":" + String(shuttlesDoneAtLevel/2)
    
    isCountingDown = false
  }
  
  func initSettings() {
    checkVolume = UserDefaults.standard.bool(forKey: "checkVolume")
  }
  
  func initNumbers() {
    currentLevel = 1
    shuttlesDoneAtLevel = 0
    
    assignSpeedShuttleArray()
    restAdjustMillis = RESTMILLISECS
    restSecsLeft = RESTMILLISECS/1000
    
    currentLevelSpeedMetersPerHour = levelSpeedMetersPerHour [currentLevel-1]
//    shuttleMilliSeconds = myFunction.getShuttleMilliSeconds (mySpeedMetersPerHour: levelSpeedMetersPerHour[currentLevel-1], noShuttles: levelShuttles[currentLevel-1], correctionMilliSecs: 0)
    shuttleMilliSeconds = myFunction.getShuttleMilliSeconds(myLevel: currentLevel, correctionMilliSecs: 0)
    levelMilliSeconds = levelShuttles[currentLevel-1] * shuttleMilliSeconds
    
    self.levelMilliSecondsRemaining = levelMilliSeconds
    self.shuttleMilliSecondsRemaining = shuttleMilliSeconds
    
    totCountdownMilliSecs = 0
    totMilliSecsRun = 0
    setTime()     // for the seconds display
    totShuttlesRun = 0
    playedLevelCue = false
    autoStopped = false
    resultViewCalled = false
    isResting = false
    //    restAdjustMillis = 0
    totRestMilliSecs = 0
    restedSinceBeepMs = 0
  }
  
  func getSettings() -> String {
    
    // Force use of English
    let language = "en"
    let path = Bundle.main.path(forResource: language, ofType: "lproj")!
    let bundle = Bundle(path: path)!
    
    let htmlTab = "&nbsp;&nbsp;&nbsp;&nbsp;"
    var myString: String = ""
    //String(testTypeArray[testTypeElement]
    
    myString.append("<br>" + NSLocalizedString("test-options", bundle: bundle, comment:"") + "<br>")
    myString.append(htmlTab + NSLocalizedString("test-type", bundle: bundle, comment:"")
                    + ": \(String(testTypeArray[testTypeElement]))<br>")
    myString.append(htmlTab + NSLocalizedString("confirm-stop", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "confirmStop"))<br>")
    myString.append(htmlTab + NSLocalizedString("auto-stop", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "autoStop"))<br>")
    
    myString.append(NSLocalizedString("sound-options", bundle: bundle, comment:"") + "<br>")
    myString.append(htmlTab + NSLocalizedString("voice-on", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "voiceOn"))<br>")
    myString.append(htmlTab + NSLocalizedString("check-volume", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "checkVolume"))<br>")
    myString.append(htmlTab + NSLocalizedString("fix-volume", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "fixVolume"))<br>")
    myString.append(htmlTab + NSLocalizedString("halfway-beep", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "halfwayBeep"))<br>")
    myString.append(htmlTab + NSLocalizedString("do-vibrate", bundle: bundle, comment:"")
                    + ": \(UserDefaults.standard.bool(forKey: "doVibrate"))<br>")
    
    return NSLocalizedString("settings-msg", bundle: bundle, comment: "") + """
      <br>
      \(myString)
      """
  }
  
  func vibrate() {
    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {   }
  }
  
  // One-time "first launch" action. Copies bundled expresso database to a location on
  //  the user's device where it can be accessed
  func copyExpressoDBOnce() {
    let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
    if (previouslyLaunched) {
      return
    }
    
    UserDefaults.standard.set(true, forKey: "previouslyLaunched")
    
    // Default directory where the CoreDataStack will store its files
    let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    
    let appTargetDB = filePath.appendingPathComponent(myDb)
    
    // seededDatabaseURL is where the bundled db is
    let seededDatabaseURL = Bundle.main.url(
      forResource: "expresso",
      withExtension: "sqlite")!
    
    _ = try? FileManager.default.removeItem(at: appTargetDB)
    
    do {
      try FileManager.default.copyItem(at: seededDatabaseURL,
                                       to: appTargetDB)
    } catch let nserror as NSError {
      fatalError("Error: \(nserror.localizedDescription)")
    }
  }
  
  func assignSpeedShuttleArray() {
    switch testTypeElement {
    case 0:
      levelSpeedMetersPerHour = Rlevel1speed
      levelShuttles = Rlevel1shuttles
      RESTMILLISECS = 10000
      myInfo.myLapsImage = "yoyoir1"
      myInfo.myNormsImage = "yoyonorms_r1"
    case 1:
      levelSpeedMetersPerHour = Rlevel2speed
      levelShuttles = Rlevel2shuttles
      RESTMILLISECS = 10000
      myInfo.myLapsImage = "yoyoir2"
      myInfo.myNormsImage = "yoyonorms_r2"
    case 2:
      levelSpeedMetersPerHour = Elevel1speed
      levelShuttles = Elevel1shuttles
      RESTMILLISECS = 5000
      myInfo.myLapsImage = "yoyoie1"
      myInfo.myNormsImage = "yyenonorms"
    case 3:
      levelSpeedMetersPerHour = Elevel2speed
      levelShuttles = Elevel2shuttles
      RESTMILLISECS = 5000
      myInfo.myLapsImage = "yoyoie2"
      myInfo.myNormsImage = "yyenonorms"
      
    default:
      print ("What the heck!")
    }
  }
  
  // Initialize Settings in the first run. Subsequently, nothing will be done
  func initDefaultSettings() {
    
    // If confirmStop is nil, assume all others need initialization
    if UserDefaults.standard.object(forKey: "confirmStop") == nil {
      UserDefaults.standard.set(false, forKey: "confirmStop")
      UserDefaults.standard.set(false, forKey: "autoStop")
      
      UserDefaults.standard.set(true, forKey: "voiceOn")
      UserDefaults.standard.set(true, forKey: "checkVolume")
      UserDefaults.standard.set(false, forKey: "halfwayBeep")
      UserDefaults.standard.set(false, forKey: "doVibrate")
      UserDefaults.standard.set(false, forKey: "fixVolume")
      
      UserDefaults.standard.set(0, forKey: "testType")
      UserDefaults.standard.set(0, forKey: "runCount")
      assignSpeedShuttleArray()
    }
  }
}

func getQuote() -> String {
  //  var db: SQLiteDatabase
  //  var myQuote: String = "";
  
  let runCount: Int = UserDefaults.standard.integer(forKey: "runCount")
  UserDefaults.standard.set(runCount+1, forKey: "runCount")
  if (runCount % 5 == 0) {
    // Default directory where the CoreDataStack will store its files
    let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let appTargetDB = filePath.appendingPathComponent(myDb).absoluteString
    
    do {
      let db = try SQLiteDatabase.open(path: appTargetDB )
      return db.getQuote()
    } catch {
      print("Unable to open database.")
    }
  }
  
  return ""
}

// Lifted the next 4 functions from https://www.andyibanez.com/posts/strategies-asking-users-rate-your-app/
func doAppReview() {
  //print("runCount = \(UserDefaults.standard.integer(forKey: "runCount"))")
  
  if (UserDefaults.standard.integer(forKey: "runCount") < 25 ) {
    return
  }
  
  if let scene = getScene() {
      SKStoreReviewController.requestReview(in: scene)
  }
}

func getScene() -> UIWindowScene? {
    if let iPadScene = getIPadScene() {
        return iPadScene
    } else {
        return getIPhoneScene()
    }
}

func getIPadScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
}

func getIPhoneScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes.first as? UIWindowScene
}

extension Bundle {
  var releaseVersionNumber: String? {
    return infoDictionary?["CFBundleShortVersionString"] as? String
  }
  var buildVersionNumber: String? {
    return infoDictionary?["CFBundleVersion"] as? String
  }
  var releaseVersionNumberPretty: String {
    return "v\(releaseVersionNumber ?? "1.0.0")"
  }
}

struct StopAlertView: View {
  @Binding var showStopAlert: Bool
  var body: some View {
    Text("").alert(isPresented: $showStopAlert, content: {
      Alert(title: Text("stop-run"),
            message: Text("are-you-sure"),
            primaryButton:  Alert.Button.default(
              Text("yes"), action: {
                showStopAlert = false
                stopTheRun = true
              }
            ),
            secondaryButton: Alert.Button.default(
              Text("no"), action: {
                showStopAlert = false
              }
            )
      )
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
