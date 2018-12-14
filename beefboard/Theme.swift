//
//  Theme.swift
//  beefboard
//
//  Created by Oliver on 25/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import UIKit

struct Theme {
    
    static var backgroundColor:UIColor?
    static var buttonTextColor:UIColor?
    static var buttonBackgroundColor:UIColor?
    
    static public func defaultTheme() {
        self.backgroundColor = UIColor.white
        self.buttonTextColor = UIColor.red
        self.buttonBackgroundColor = UIColor.white
        updateDisplay()
    }
    
    static public func darkTheme() {
        self.backgroundColor = UIColor.darkGray
        self.buttonTextColor = UIColor.white
        self.buttonBackgroundColor = UIColor.black
        updateDisplay()
    }
    
    static private func updateDisplay() {
        let proxyButton = UIButton.appearance()
        proxyButton.setTitleColor(Theme.buttonTextColor, for: .normal)
        proxyButton.tintColor = Theme.buttonTextColor
        
        //proxyButton.backgroundColor = Theme.buttonBackgroundColor
        
        //let proxyView = UIView.appearance()
        //proxyView.backgroundColor = backgroundColor
    }
}
