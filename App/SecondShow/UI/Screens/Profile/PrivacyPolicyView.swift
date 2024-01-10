//
//  PrivacyPolicyView.swift
//  SecondShow
//
//  Created by Alan on 1/10/24.
//

import SwiftUI
import WebKit


struct PrivacyPolicyView: UIViewRepresentable {
    
    let htmlFileName = "PrivatePolicy"
    
    private let webView = WKWebView()
    
    func makeUIView(context: Context) -> some UIView {
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        webView.load(htmlFileName)
    }
}

extension WKWebView {
    func load(_ htmlFileName: String) {
        guard !htmlFileName.isEmpty else {
            return print("Empty file name")
        }
        
        guard let filePath = Bundle.main.path(forResource: htmlFileName, ofType: "html") else {
            return print("Error file path")
        }
        
        do {
            let htmlString = try String(contentsOfFile: filePath, encoding: .utf8)
            loadHTMLString(htmlString, baseURL: URL(fileURLWithPath: filePath))
        } catch {
            print("Error loading HTML string")
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
