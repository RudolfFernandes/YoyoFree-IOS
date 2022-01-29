//
//  ResultView.swift
//  BeepTest
//
//  Created by Rudy on 2021-10-20.
//

import SwiftUI

struct ResultView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var myInfo: theInfo
  
  var body: some View {
    
    VStack(spacing: -10) {
      Text(appName + " " + NSLocalizedString("result", comment: ""))
        .font(.largeTitle)
        .foregroundColor(.blue)
        .padding()
      Text(NSLocalizedString("you-scored", comment: "") + " \(myInfo.myDistance) m")
//      + String(format: "%d", myInfo.myDistance))
        .font(.title2)
        .foregroundColor(.green)
        .padding(.bottom)
//      Image(myInfo.myNormsImage)
//        .resizable()
//        .scaledToFit()
//        .padding()
      
      ZoomableScrollView {
        Image(myInfo.myNormsImage)
          .resizable()
          .scaledToFit()
//          .padding()
      }
      
      Label ("",
             systemImage: "arrowshape.turn.up.backward.fill")
        .labelsHidden()
        .foregroundColor(.blue)
        .font(.title)
        .scaleEffect(framewidth > 350 ? 1.25 : 1.0, anchor: .center)
        .onTapGesture(perform: {
          self.presentationMode.wrappedValue.dismiss()
        })
        .padding(.leading, framewidth > 350 ? 13 : 7)
        .padding(.trailing, framewidth > 350 ? 13 : 7)
    }
  }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView()
    }
}
