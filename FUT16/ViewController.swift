//
//  ViewController.swift
//  FUT16
//
//  Created by Kon on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    
    @IBOutlet weak var playerNameTextField: NSTextField!
    @IBOutlet weak var playerImage: NSImageView!
    @IBOutlet weak var playerLeagueTextField: NSTextField!
    @IBOutlet weak var playerTeamTextField: NSTextField!
    @IBOutlet weak var playerNationTextField: NSTextField!
    
    @IBOutlet weak var typeSegment: NSSegmentedControl!
    
    @IBOutlet weak var playerIdTextField: NSTextField!
    @IBOutlet weak var nationalityComboBox: NSComboBox!
    @IBOutlet weak var leagueComboBox: NSComboBox!
    @IBOutlet weak var teamComboBox: NSComboBox!
    @IBOutlet weak var levelComboBox: NSComboBox!
    @IBOutlet weak var minBinTextField: NSTextField!
    @IBOutlet weak var maxBinTextField: NSTextField!
    @IBOutlet weak var buyAtTextField: NSTextField!
    @IBOutlet weak var breakEvenTextField: NSTextField!
    
    @IBOutlet weak var recentPurchasesTextField: NSTextField!
    
    // Settings outlets
    @IBOutlet weak var reqTimingMinTextField: NSTextField!
    @IBOutlet weak var reqTimingMaxTextField: NSTextField!
    @IBOutlet weak var cycleTimeTextField: NSTextField!
    @IBOutlet weak var cycleBreakTextField: NSTextField!
    @IBOutlet weak var unlockCodeTextField: NSTextField!
    
    @IBOutlet weak var userFileTextField: NSTextField!
    
    @IBOutlet var logTextView: NSTextView!
    
    var openPanel = NSOpenPanel()
    
    dynamic var autoTrader: AutoTrader!
    var users: [FutUser]!
    
    lazy var user0: FutUser = { return self.users[0] }()

    var aggregateStats = AggregateStats.sharedInstance

    var settings = Settings.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(AccountViewItem.self, forItemWithIdentifier: "AccountViewItem")
        
        
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = ["txt"]
        openPanel.directoryURL = URL(fileURLWithPath: NSString(string: "~").expandingTildeInPath)
        
        updateFieldsStateForSearchType(typeSegment.selectedLabel())
        updateSettings()
        updatePlayerInfo()
        
        users = UserLoader.getUsers(from: Settings.sharedInstance.userFile)
        
        if users == nil || users.count == 0 {
            selectUsersFile()
        } else {
            autoTrader = AutoTrader(users: users, update: nil)
        }
    }
    
    func getIdFromComboBox(_ comboBox: NSComboBox) -> String? {
        if comboBox.stringValue == "Any" {
            return ""
        }
        
        if comboBox == levelComboBox {
            return comboBox.stringValue
        } else {
            // assuming format is "Label: ID"
            let comps = comboBox.stringValue.components(separatedBy: CharacterSet(charactersIn: ": "))
            return comps.last
        }
    }
    
    func log(_ string: String) {
        logTextView.textStorage?.append(NSAttributedString(string: string, attributes: [NSFontAttributeName : NSFont(name: "Menlo", size: 11)!]))
        logTextView.scrollToEndOfDocument(nil)
    }
    
    func clearLog() {
        logTextView.string = ""
    }
    
    func updateFieldsStateForSearchType(_ type: String) {
        // enable all and then disabled necessary fields based on type
        playerIdTextField.isEnabled = true
        playerIdTextField.isEnabled = true
        teamComboBox.isEnabled = true
        leagueComboBox.isEnabled = true
        nationalityComboBox.isEnabled = true
        
        switch type {
        case "Player":
            break
        case "Chemistry":
            playerIdTextField.isEnabled = false
            teamComboBox.isEnabled = false
            leagueComboBox.isEnabled = false
            nationalityComboBox.isEnabled = false
        case "Manager":
            playerIdTextField.isEnabled = false
        default:
            break
        }
    }
    
    func updateSettings() {
        var reqTimingMin = reqTimingMinTextField.doubleValue
        let reqTimingMax = reqTimingMaxTextField.doubleValue
        
        // clip min timing to 1.5 seconds
        reqTimingMin = reqTimingMin < 1.5 ? 1.5 : reqTimingMin
        reqTimingMinTextField.doubleValue = reqTimingMin
        
        settings.reqTimingMin = reqTimingMin
        settings.reqTimingMax = reqTimingMax
        settings.cycleTime    = cycleTimeTextField.doubleValue * 60.0       // convert from min to seconds
        settings.cycleBreak   = cycleBreakTextField.doubleValue * 60.0      // convert from min to seconds
        settings.unlockCode   = unlockCodeTextField.stringValue
        settings.userFile     = userFileTextField.stringValue
    }
    
    func selectUsersFile() {
        openPanel.begin { (result) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self.userFileTextField.stringValue = self.openPanel.url!.path
            UserDefaults.standard.set(self.userFileTextField.stringValue, forKey: "userFile")
            self.updateSettings()
            self.users = UserLoader.getUsers(from: Settings.sharedInstance.userFile)
            self.collectionView.reloadData()
        }
    }
    
    func updatePlayerInfo() {
        FutDatabase.getPlayerInfo(baseId: playerIdTextField.stringValue) { [unowned self] (playerInfo) in
            guard let playerInfo = playerInfo else {
                self.playerNameTextField.stringValue = "Not Found"
                self.playerLeagueTextField.stringValue = ""
                self.playerTeamTextField.stringValue = ""
                self.playerNationTextField.stringValue = ""
                self.playerImage.image = NSImage(named: "NSInfo")
                return
            }
            
            self.playerNameTextField.stringValue = "\(playerInfo.firstName) \(playerInfo.lastName) (\(playerInfo.rating))"
            self.playerLeagueTextField.stringValue = playerInfo.league
            self.playerTeamTextField.stringValue = playerInfo.team
            self.playerNationTextField.stringValue = playerInfo.nation
            if let imageUrl = URL(string: playerInfo.imageUrl) {
//                self.playerImage.image = NSImage(contentsOf: imageUrl)
            }
        }
    }
}

// MARK: UI Actions
extension ViewController {
    @IBAction func setSearchParamsPressed(_ sender: NSButton) {
        let nationality = getIdFromComboBox(nationalityComboBox) ?? ""
        let league = getIdFromComboBox(leagueComboBox) ?? ""
        let team = getIdFromComboBox(teamComboBox) ?? ""
        let level  = getIdFromComboBox(levelComboBox) ?? ""
        
        let minSearchBin = UInt(minBinTextField.stringValue.replacingOccurrences(of: ",", with: "")) ?? 0
        let maxSearchBin = UInt(maxBinTextField.stringValue.replacingOccurrences(of: ",", with: "")) ?? 0
        let buyAtBin = UInt(buyAtTextField.stringValue.replacingOccurrences(of: ",", with: "")) ?? 0
        
        var params: FUT16.ItemParams!
        
        switch typeSegment.selectedLabel() {
        case "Player":
            let playerId = playerIdTextField.stringValue
            params = FUT16.PlayerParams(playerId: playerId, nationality: nationality, league: league, team: team, level: level, minBin: minSearchBin, maxBin: maxSearchBin)
        case "Chemistry":
            params = FUT16.ConsumableParams(category: "playStyle", level: level, minBin: minSearchBin, maxBin: maxSearchBin)
        case "Manager":
            break
        default:
            break
        }
        
        let breakEvenPrice = autoTrader?.setTradeParams(params, buyAtBin: buyAtBin)
        breakEvenTextField.integerValue = Int(breakEvenPrice!)
        
        updatePlayerInfo();
    }
    
    @IBAction func updateMaxBin(_ sender: NSButton) {
        let maxSearchBin = UInt(maxBinTextField.stringValue.replacingOccurrences(of: ",", with: "")) ?? 0
        
        if sender.tag > 0 {
            maxBinTextField.integerValue = Int(incrementPrice(maxSearchBin));
        } else {
            maxBinTextField.integerValue = Int(decrementPrice(maxSearchBin));
        }
        
        setSearchParamsPressed(sender);
    }
    
    @IBAction func typeSegmentChanged(_ sender: NSSegmentedControl) {
        updateFieldsStateForSearchType(sender.selectedLabel())
    }

    
    @IBAction func doStuffPressed(_ sender: NSButton) {
        setSearchParamsPressed(sender)
        autoTrader?.startTrading()
    }
    
    @IBAction func stopPressed(_ sender: NSButton) {
        autoTrader?.stopTrading("UI")
    }
    
    @IBAction func resetStatsPressed(_ sender: NSButton) {
        autoTrader?.resetStats(nil)
        if sender.tag == 99 {
            clearLog()
        }
    }
    
    @IBAction func saveSettingsPressed(_ sender: NSButton) {
        updateSettings()
        Log.print("Settings: \(settings)")
    }
    
    @IBAction func browsePressed(_ sender: AnyObject) {
        selectUsersFile()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "AccountViewItem", for: indexPath)
        guard let accountItem = item as? AccountViewItem else {
            print("Not account view")
            return item
        }
        
        accountItem.user = users[(indexPath as NSIndexPath).item]
        
        return accountItem
    }
}

extension NSSegmentedControl {
    func selectedLabel() -> String {
        return self.label(forSegment: self.selectedSegment) ?? ""
    }
}

