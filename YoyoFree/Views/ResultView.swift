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
      Image(myInfo.myNormsImage)
        .resizable()
        .scaledToFit()
        .padding()
      Button(action: {
        presentationMode.wrappedValue.dismiss()
      }) {
        Text("ok")
          .font(.callout)
          .foregroundColor(.black)
          .padding(5)
      }
      .buttonStyle(PlainButtonStyle())
      .frame(minWidth:100)
      .background(Color(UIColor.lightGray))
      .cornerRadius(20)
      .padding(10)
    }
  }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView()
    }
}
