//
//  MailView.swift
//
//  Created by Rudy on 2021-09-30.
//

import SwiftUI
import UIKit
import MessageUI

struct MailView: UIViewControllerRepresentable {
  
  @Binding var isShowing: Bool
  @Binding var result: Result<MFMailComposeResult, Error>?
  var mailRecipients = [String]()
  var mailSubject = ""
  var mailMessageBody = ""
  
  class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    init(isShowing: Binding<Bool>,
         result: Binding<Result<MFMailComposeResult, Error>?>) {
      _isShowing = isShowing
      _result = result
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
      defer {
        isShowing = false
      }
      guard error == nil else {
        self.result = .failure(error!)
        return
      }
      self.result = .success(result)
    }
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(isShowing: $isShowing,
                       result: $result)
  }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
    let vc = MFMailComposeViewController()
    vc.setToRecipients(mailRecipients)
    vc.setSubject(mailSubject)
    vc.setMessageBody(mailMessageBody, isHTML: true)
    vc.mailComposeDelegate = context.coordinator
    return vc
  }
  
  func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                              context: UIViewControllerRepresentableContext<MailView>) {
    
  }
}
