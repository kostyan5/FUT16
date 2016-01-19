//
//  FUT16+Bid.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/20/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import SwiftyJSON

// POST URL: https://utas.s3.fut.ea.com/ut/game/fifa16/trade/1218165632/bid
// Params: {"bid":200}

extension FUT16 {
    func placeBidOnAuction(auctionId: String, amount: UInt, completion: (error: FutError) -> Void) {
        let bidUrl = "trade/\(auctionId)/bid"
        let parameters = ["bid" : amount]
        
        self.requestForPath(bidUrl, withParameters: parameters, encoding: .JSON, methodOverride: "PUT") { (json) -> Void in
            let tradeId = json["auctionInfo"][0]["tradeId"].stringValue
            let funds = json["currencies"][0]["finalFunds"].stringValue
            let fundCurrency = json["currencies"][0]["name"].stringValue
            
            var error = FutError.None
            
            if fundCurrency == "COINS" {
                self.coinFunds = funds
            }
            if tradeId == "" {
                if json["code"] == "461" {    // Reason: "You are not allowed to bid on this trade" 
                    error = .BidNotAllowed
                } else {
                    print(json)
                    error = .PurchaseFailed
                }
            } else {
                print("Purchased \(tradeId) for \(amount) - \(json["auctionInfo"][0]["tradeState"]) (Bal: \(self.coinsBalance))")
            }
            
            completion(error: error)
        }
    }
    
    func searchForAuction(auctionId: String, completion: (JSON) -> Void) {
        let tradeSearchUrl = "trade/status?tradeIds=\(auctionId)"
        
        requestForPath(tradeSearchUrl) { (json) -> Void in
            completion(json)
        }
    }
}

// Format:

//auctionInfo: [{tradeId: 1221506371,…}]
//0: {tradeId: 1221506371,…}
//bidState: "buyNow"
//buyNowPrice: 200
//confidenceValue: 100
//currentBid: 200
//expires: -1
//itemData: {id: 102344688961, timestamp: 1450658209, formation: "f3412", untradeable: false, assetId: 153275,…}
//offers: 0
//sellerEstablished: 0
//sellerId: 0
//sellerName: "FIFA UT"
//startingBid: 150
//tradeId: 1221506371
//tradeOwner: false
//tradeState: "closed"
//watched: false

// Money Left:
//currencies: [{name: "COINS", funds: 4264, finalFunds: 4264}, {name: "POINTS", funds: 0, finalFunds: 0},…]
//0: {name: "COINS", funds: 4264, finalFunds: 4264}
//finalFunds: 4264
//funds: 4264
//name: "COINS"