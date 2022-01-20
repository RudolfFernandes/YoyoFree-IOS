//
//  LapsImageView.swift
//  BeepTest
//
//  Created by Rudy on 2021-10-20.
//

import SwiftUI

struct LapsImageView: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var myInfo: theInfo
  
  var body: some View {
    
    VStack(spacing: -10) {
      Text(appName)
        .font(.largeTitle)
        .foregroundColor(.blue)
        .padding()
      Text("Laps Table")
        .font(.title.weight(.bold))
        .foregroundColor(.green)
        .padding(.bottom)
      
      ZoomableScrollView {
        Image(myInfo.myLapsImage)
          .resizable()
          .scaledToFit()
//          .padding()
      }
      
      //      Image(myInfo.myLapsImage)
      //        .resizable()
      //        .scaledToFit()
      //        .padding()
      
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
      
      //      Button(action: {
      //        presentationMode.wrappedValue.dismiss()
      //      }) {
      //        Text("ok")
      //          .font(.callout)
      //          .foregroundColor(.black)
      //          .padding(5)
      //      }
      //      .buttonStyle(PlainButtonStyle())
      //      .frame(minWidth:100)
      //      .background(Color(UIColor.lightGray))
      //      .cornerRadius(20)
      //      .padding(10)
      //    }
    }
  }
}

struct LapsImageView_Previews: PreviewProvider {
  static var previews: some View {
    LapsImageView()
  }
}
