//
//  FutUser.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/9/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import OneTimePassword

open class FutUser: NSObject {
    let fut16 = FUT16()
    
    lazy var stats: UserStats = { [unowned self] in return UserStats(email: self.email) }()
    
    var email = "" {
        didSet {
            username = email.components(separatedBy: "@")[0]
            stats.email = self.email
        }
    }
    dynamic var username = ""
    var password = ""
    var answer = ""
    var totpToken = ""
    
    lazy fileprivate var totp: Token = { [unowned self] in
        let secretData = NSData(base32String: self.totpToken)
        let generator = Generator(factor: .Timer(period: 30), secret: secretData, algorithm: .SHA1, digits: 6)!
        return Token(generator: generator)
    }()
    
    var authCode: String {
        return totp.currentPassword ?? ""
    }
    
    var enabled = true
    var ready: Bool {
        return !fut16.sessionId.isEmpty && enabled
    }
    
    func resetStats() {
        stats.reset()
    }
}
