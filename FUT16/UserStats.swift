//
//  UserStats.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/9/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import Cocoa

private let managedObjectContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext

class UserStats: NSObject {
    var email: String {
        didSet {
            reset()
            fetchAllTimeStats()
        }
    }
    dynamic var coinsBalance = 0
    
    init(email: String) {
        self.email = email
        super.init()
        fetchAllTimeStats()
    }
    
    dynamic var searchCount = 0
    dynamic var searchCount1Hr = 0
    dynamic var searchCount2Hr = 0
    dynamic var searchCount24Hr = 0
    dynamic var searchCountAllTime = 0
    
    dynamic var purchaseCount = 0
    dynamic var purchaseFailCount = 0 {
        didSet {
            // only update if fail count increasing, otherwise it's a reset
            let diff = purchaseFailCount - oldValue
            if diff > 0 {
                AggregateStats.sharedInstance.purchaseFailCount += diff
            }
        }
    }
    dynamic var purchaseTotalCost = 0
    dynamic var averagePurchaseCost = 0
    dynamic var lastPurchaseCost = 0
    dynamic var purchaseTotalAllTime = 0
    
    var unassignedItems = 0
    
    var errorCount = 0
    
    fileprivate let managedObjectContext = (NSApplication.shared().delegate as! AppDelegate).managedObjectContext
    
    func searchCountHours(_ hours: Double) -> Int {
        return Search.numSearchesSinceDate(Date(timeIntervalSinceNow: -3600*hours), forEmail: email, managedObjectContext: managedObjectContext)
    }
    
    func logSearch() {
        Search.NewSearch(email, managedObjectContext: managedObjectContext)
        // this should be done after search is logged so that didSet updates various counters with new search
        searchCount += 1
        searchCountAllTime += 1
        AggregateStats.sharedInstance.searchCount += 1
        
        fetchHourlyStats()
        
        Stats.updateSearchCount(email, searchCount: Int32(searchCountAllTime), managedObjectContext: managedObjectContext)
    }
    
    func logPurchase(_ purchaseCost: Int, maxBin: Int, coinsBalance: Int) {
        // add to CoreData
        Purchase.NewPurchase(email, price: purchaseCost, maxBin: maxBin, coinBallance: coinsBalance, managedObjectContext: managedObjectContext)
        
        // this should be done after purchase is logged so that didSet updates various counters with new purchase
        lastPurchaseCost = purchaseCost
        self.coinsBalance = coinsBalance
        unassignedItems += 1
        
        purchaseCount += 1
        purchaseTotalCost += lastPurchaseCost
        averagePurchaseCost = Int(round(Double(purchaseTotalCost) / Double(purchaseCount)))
        purchaseTotalAllTime += lastPurchaseCost
        
        AggregateStats.sharedInstance.purchaseCount += 1
        AggregateStats.sharedInstance.lastPurchaseCost = lastPurchaseCost
        
    }
    
    func fetchAllTimeStats() {
        searchCountAllTime = Stats.getSearchCountForEmail(email, managedObjectContext: managedObjectContext)
        purchaseTotalAllTime = Int(Purchase.getPurchasesSinceDate(Date.allTime, forEmail: email, managedObjectContext: managedObjectContext).reduce(0) { $0 + $1.price })
        
        fetchHourlyStats()
    }
    
    func fetchHourlyStats() {
        searchCount1Hr = Search.numSearchesSinceDate(Date.hourAgo, forEmail: email, managedObjectContext: managedObjectContext)
        //searchCount2Hr = Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -2*3600), forEmail: email, managedObjectContext: managedObjectContext)
        searchCount24Hr = Search.numSearchesSinceDate(Date.dayAgo, forEmail: email, managedObjectContext: managedObjectContext)
    }
    
    func reset() {
        searchCount = 0
        purchaseCount = 0
        purchaseFailCount = 0
        purchaseTotalCost = 0
        lastPurchaseCost = 0
        averagePurchaseCost = 0
        
        coinsBalance = 0
        
        fetchHourlyStats()
        
        // get the last search that happened less than 24 hours ago
        let searches = Search.getSearchesSinceDate(Date.dayAgo, forEmail: email, managedObjectContext: managedObjectContext)
        
        if let search = searches.first {
            AggregateStats.sharedInstance.last24HrSearch = Date(timeIntervalSinceReferenceDate:search.time).localTime
        }

    }
    
    func purgeOldSearches() {
        Search.purgeSearchesOlderThan(Date.hoursAgo(26), forEmail: email, managedObjectContext: managedObjectContext)
    }
    
    func save() {
        Transaction.save(managedObjectContext)
        Stats.save(managedObjectContext)
    }
}

class AggregateStats: NSObject {
    static var sharedInstance = AggregateStats()
    
    dynamic var searchCount = 0
    dynamic var purchaseCount = 0
    dynamic var purchaseFailCount = 0
    dynamic var purchaseTotalCost = 0
    dynamic var lastPurchaseCost = 0 {
        didSet {
            purchaseTotalCost += lastPurchaseCost
            averagePurchaseCost = (purchaseCount == 0) ? 0 : Int(round(Double(purchaseTotalCost) / Double(purchaseCount)))
        }
    }
    dynamic var averagePurchaseCost = 0
    
    dynamic var cycleStart = ""
    dynamic var last24HrSearch = ""
    
    func reset() {
        searchCount = 0
        purchaseCount = 0
        purchaseFailCount = 0
        purchaseTotalCost = 0
        lastPurchaseCost = 0
    }
}
