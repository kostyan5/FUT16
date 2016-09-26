//
//  FutDatabase.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 9/26/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class FutDatabase {
    fileprivate static let databaseUrl = "https://www.easports.com/fifa/ultimate-team/api/fut/item"
    
    static func getPlayerInfo(baseId: String, completion: @escaping (JSON)->()) {
        let params = ["jsonParamObject": "{\"baseid\":\"\(baseId)\"}"]
        
        Alamofire.request(databaseUrl, parameters: params, encoding: URLEncoding.default).responseJSON { (response) in
            print(response.request!.url!.absoluteString)
            guard let result = response.result.value else { return }
            let item = JSON(result)["items"][0]
            print("\(item["firstName"]) \(item["name"])")
        }
    }
}
