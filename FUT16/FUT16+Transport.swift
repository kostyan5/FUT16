//
//  FUT16+Transport.swift
//  FUT16
//
//  Created by Kon on 12/17/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// generic transport functions
extension FUT16 {
    func requestForPath(_ urlPath: String, withParameters parameters: [String : AnyObject]? = nil, encoding: ParameterEncoding = .url, methodOverride: String = "GET", completion: (_ json: JSON) -> Void) -> Request! {
        
        guard isSessionValid else {
            Log.print("Waiting for valid session...")
            completion(json: "")
            return nil
        }
        
        let url: URLStringConvertible = futUrl.URLString + urlPath
        
        let headers = ["X-UT-SID" : sessionId,
                       "X-UT-PHISHING-TOKEN" : phishingToken,
                       "X-HTTP-Method-Override" : methodOverride,
                       "X-UT-Embed-Error" : "true"]
        
        return alamo.request(.POST, url, headers: headers, parameters: parameters, encoding: encoding).responseJSON { (response) -> Void in
            switch response.result {
            case .success:
                completion(json: JSON(response.result.value!))
            case .failure (let error):
                completion(json: "")
                Log.print("Failed to fetch JSON (error: \(error)")
            }
        }
    }
    
    func getUserInfo() {
        requestForPath("user") { [unowned self] (json) -> Void in
            self.coinFunds = json["credits"].stringValue
            Log.print("Coins Balance: \(self.coinFunds)")
            self.loginCompletion?()
        }
    }
}
