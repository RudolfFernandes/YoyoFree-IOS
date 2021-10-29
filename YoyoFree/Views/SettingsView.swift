//
//  SettingsView.swift
//  RepeatingReminder
//
//  Created by Rudy on 2021-10-06.
//

import SwiftUI
import CoreMotion

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var mySetting: theSetting
  
  @State var notificationsEnabled: Bool = false
  @State var checkVolume: Bool
  @State private var showAutoStopAlert: Bool = false
  
  init(){
    _checkVolume = State(initialValue: UserDefaults.standard.bool(forKey: "checkVolume"))
  }
  
  //  var previewOptions = ["Always", "When Unlocked", "Never"]
  
  var body: some View {
    Form {      // this scrolls, if required
      
      Section {
        Label ("", systemImage: "arrow.backward")
          .font(.title2)
          .onTapGesture(perform: {
            presentationMode.wrappedValue.dismiss()
          })
      } //.padding(.bottom, -30)
      
      // Sections have a limit to the number of options. Had to split this
      Section(header: Text("test-options").foregroundColor(.green)) {
        
        Text ("test-type").font(.callout).foregroundColor(.white).padding(.bottom, -10)
        Text ("test-type-msg").font(.callout).foregroundColor(.gray).padding(.top, -5).padding(.bottom, 10)
        
        Toggle("confirm-stop", isOn: $mySetting.confirmStop)
          .onChange(of: mySetting.confirmStop, perform: { value in
            UserDefaults.standard.set(mySetting.confirmStop, forKey: "confirmStop")
          })
        Text ("confirm-stop-msg").font(.callout).foregroundColor(.gray)
        
        Toggle("auto-stop", isOn: $mySetting.autoStop)
          .onChange(of: mySetting.autoStop, perform: { value in
            UserDefaults.standard.set(mySetting.autoStop, forKey: "autoStop")
            
            // If AutoStop selected, make sure there is an accelerometer
            if (mySetting.autoStop) {
              let manager = CMMotionManager()
              guard manager.isAccelerometerAvailable else {
                mySetting.autoStop = false
                UserDefaults.standard.set(false, forKey: "autoStop")
                showAutoStopAlert = true
                return
              }
            }
          })
        Text ("auto-stop-msg").font(.callout).foregroundColor(.gray)
        
      } //.padding(.top, -10).padding(.bottom, -10)
      
      Section(header: Text("sound-options").foregroundColor(.green)) {
        
        Toggle("voice-on", isOn: $mySetting.voiceOn)
          .onChange(of: mySetting.voiceOn, perform: { value in
            UserDefaults.standard.set(mySetting.voiceOn, forKey: "voiceOn")
            //            storeBoolDefault(myKey: "voiceOn", myBool: voiceOn)
          })
        Text ("voice-on-msg").font(.callout).foregroundColor(.gray)
        
        Toggle("check-volume", isOn: $checkVolume)
          .onChange(of: checkVolume, perform: { value in
            UserDefaults.standard.set(checkVolume, forKey: "checkVolume")
          })
        Text ("check-volume-msg").font(.callout).foregroundColor(.gray)
        
        Toggle("fix-volume", isOn: $mySetting.fixVolume)
          .onChange(of: mySetting.fixVolume, perform: { value in
            UserDefaults.standard.set(mySetting.fixVolume, forKey: "fixVolume")
          })
        Text ("fix-volume-msg").font(.callout).foregroundColor(.gray)
        
        Toggle("halfway-beep", isOn: $mySetting.halfwayBeep)
          .onChange(of: mySetting.halfwayBeep, perform: { value in
            UserDefaults.standard.set(mySetting.halfwayBeep, forKey: "halfwayBeep")
          })
        Text ("halfway-beep-msg").font(.callout).foregroundColor(.gray)
        
        Toggle("do-vibrate", isOn: $mySetting.doVibrate)
          .onChange(of: mySetting.doVibrate, perform: { value in
            UserDefaults.standard.set(mySetting.doVibrate, forKey: "doVibrate")
          })
        Text ("do-vibrate-msg").font(.callout).foregroundColor(.gray)
        
      } //.padding(.top, -10).padding(.bottom, -10)
      
      
      Section(header: Text("about")) {
        HStack {
          Text("version")
          Spacer()
          Text(Bundle.main.releaseVersionNumberPretty)
        }
        Label ("", systemImage: "arrow.backward")
          .font(.title2)
          .onTapGesture(perform: {
            presentationMode.wrappedValue.dismiss()
          })
      } //.padding(.top, -10).padding(.bottom, -10)
      
      
      
    }
    
    Text("").alert(isPresented: $showAutoStopAlert, content: {
      Alert(title: Text(""),
            message: Text("auto-stop-alert"),
            dismissButton: Alert.Button.default(
              Text("ok"), action: {
                showAutoStopAlert = false
              }
            )
      )
    })
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
