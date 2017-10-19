//
//  MainGameViewController.swift
//  DaVinciCode
//
//  Created by cruzr on 2017/8/7.
//  Copyright © 2017年 martin. All rights reserved.
//

import UIKit

class CareView: UIView {
    
    var label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.frame = CGRect(x: 5, y: 5, width: frame.size.width - 10, height: frame.size.height - 10)
        self.addSubview(label)
    }
    
    func setFrame(frame: CGRect) {
        self.frame = frame
        label.frame = CGRect(x: 5, y: 5, width: frame.size.width - 10, height: frame.size.height - 10)
        label.font = UIFont.systemFont(ofSize: 26)
        label.textAlignment = .center
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.red.cgColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CardModel {
    var serialNumber : UInt32 = 0
    var isHidden = true
    var isSelected = false
    var view = CareView(frame:CGRect(x: 0, y: 0, width: 0, height: 0))
    
    func color() -> UIColor {
        if serialNumber % 2 == 0 {
            return UIColor.black
        } else {
            return UIColor.white
        }
    }
    
    func labelColor() -> UIColor {
        if serialNumber % 2 == 0 {
            return UIColor.white
        } else {
            return UIColor.black
        }
    }
    
    func number() -> UInt32 {
        return UInt32(serialNumber/2)
    }
}

class MainGameViewController: UIViewController {
    
    @IBOutlet weak var blackCardView: UIImageView! {
        didSet {
            blackCardView.isUserInteractionEnabled = true
        }
    }
    @IBOutlet weak var whiteCardView: UIImageView! {
        didSet {
            whiteCardView.layer.borderWidth = 1
            whiteCardView.layer.borderColor = UIColor.black.cgColor
            whiteCardView.isUserInteractionEnabled = true
        }
    }
    
    @IBOutlet weak var myName: UILabel!

    @IBOutlet weak var playerName: UILabel!
    
    @IBOutlet weak var remindLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.isHidden = true
        }
    }
    
    var selectedCard : CardModel? = nil
    var pendingCard : CardModel? = nil
    
    var creatorArr = [CardModel]()
    var playerArr = [CardModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.blackCardTap(ges:)))
        blackCardView.addGestureRecognizer(tap)
        tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.whiteCardTap(ges:)))
        whiteCardView.addGestureRecognizer(tap)

        if SocketClient.share.role == .creator {
            remindLabel.text = "等待其他玩家加入。。。"
            myName.text = "creator"
            playerName.isHidden = true
        } else if SocketClient.share.role == .player {
            playerName.text = "creator"
            remindLabel.isHidden = true
            myName.text = "player1"
        }
        
        
        SocketClient.share.playerJoinedBlock = { playerName in
            
            self.showRemind(msg: "\(playerName)加入游戏")
            self.playerName.isHidden = false
            self.playerName.text = playerName
        }
        
        SocketClient.share.dataInitedBlock = { (creatorArr, playerArr) in
            var newcreatorArr = creatorArr
            var newplayerArr = playerArr
            newcreatorArr.sort(){
                $0 < $1
            }
            newplayerArr.sort(){
                $0 < $1
            }
            
            DispatchQueue.main.async {
                for item in newcreatorArr {
                    let card = CardModel()
                    card.serialNumber = item
                    card.view.setFrame(frame: self.blackCardView.frame)
                    card.view.tag = Int(item)
                    self.view.addSubview(card.view)
                    self.creatorArr.append(card)
                    if SocketClient.share.role == .player {
                        let tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.cardTap(ges:)))
                        card.view.addGestureRecognizer(tap)
                    }
                }
                
                for item in newplayerArr {
                    let card = CardModel()
                    card.serialNumber = item
                    card.view.setFrame(frame: self.blackCardView.frame)
                    card.view.tag = Int(item)
                    self.view.addSubview(card.view)
                    self.playerArr.append(card)
                    if SocketClient.share.role == .creator {
                        let tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.cardTap(ges:)))
                        card.view.addGestureRecognizer(tap)
                    }
                }
                
                self.placedAllCard()
            }
        }
        
        SocketClient.share.turnChangeBlock = {
            DispatchQueue.main.async {
                if SocketClient.share.isYourTurn() {
                    self.showRemind(msg: "你的回合")
                } else {
                    self.showRemind(msg: "对手回合")
                }
            }
        }
        
        SocketClient.share.selectCardBlock = { (role, number) in
            print("select card = \(number)")
            self.pendingCard = CardModel()
            self.pendingCard!.serialNumber = UInt32(number)
           
            if number%2 == 1 {
                self.pendingCard!.view.setFrame(frame: self.whiteCardView.frame)
            } else {
                self.pendingCard!.view.setFrame(frame: self.blackCardView.frame)
            }
            self.pendingCard!.view.tag = number
            self.view.addSubview(self.pendingCard!.view)
            
            UIView.animate(withDuration: 2, animations: { 
                if role == SocketClient.share.role {
                    self.pendingCard!.view.label.text = "\(self.pendingCard!.number())"
                   
                    if number%2 == 1 {

                        self.pendingCard!.view.setFrame(frame: CGRect(x: self.whiteCardView.frame.origin.x - 70, y: self.whiteCardView.frame.origin.y + 10, width: 50, height: 80))
                    } else {
                        self.pendingCard!.view.setFrame(frame: CGRect(x: self.blackCardView.frame.origin.x + 70, y: self.blackCardView.frame.origin.y + 10, width: 50, height: 80))
                    }
                } else {
                    self.pendingCard!.view.label.text = ""
                   
                    if number%2 == 1 {
                        self.pendingCard!.view.setFrame(frame: CGRect(x: self.whiteCardView.frame.origin.x - 70, y: self.whiteCardView.frame.origin.y - 10, width: 50, height: 80))
                    } else {
                        self.pendingCard!.view.setFrame(frame: CGRect(x: self.blackCardView.frame.origin.x + 70, y: self.blackCardView.frame.origin.y - 10, width: 50, height: 80))
                    }
                }
                
                self.pendingCard!.view.label.textColor = self.pendingCard!.labelColor()
                self.pendingCard!.view.label.backgroundColor = self.pendingCard!.color()
            }, completion: { (_) in
                
            })
            
        }
        
        SocketClient.share.chooseCardNumberBlock = { number in
            if SocketClient.share.role == .creator {
                self.reloadCreatorView()
                for card in self.creatorArr {
                    if card.serialNumber == number {
                        if card.isHidden {
                            card.view.frame.origin.y -= 20
                        }
                        break
                    }
                }
            } else {
                self.reloadPlayerView()
                for card in self.playerArr {
                    if card.serialNumber == number {
                        if card.isHidden {
                            card.view.frame.origin.y -= 20
                        }
                        break
                    }
                }
            }
        }
        
        SocketClient.share.conformBlock = { (choosenNumber, realNumber) in
            if choosenNumber == UInt32(realNumber/2) {
                self.showRemind(msg: "对手猜\(choosenNumber), 猜对了")
                if SocketClient.share.role == .creator {
                    for card in self.creatorArr {
                        if card.serialNumber == realNumber {
                            card.isHidden = false
                            break
                        }
                    }
                    if self.pendingCard != nil {
                        let tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.cardTap(ges:)))
                        self.pendingCard!.view.addGestureRecognizer(tap)
                        var inserted = false
                        for index in 0...self.playerArr.count-1 {
                            let card = self.playerArr[index]
                            if self.pendingCard!.serialNumber < card.serialNumber {
                                self.playerArr.insert(self.pendingCard!, at: index)
                                self.pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            self.playerArr.append(self.pendingCard!)
                            self.pendingCard = nil
                        }
                    }
                } else {
                    for card in self.playerArr {
                        if card.serialNumber == realNumber {
                            card.isHidden = false
                            break
                        }
                    }
                    if self.pendingCard != nil {
                        let tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.cardTap(ges:)))
                        self.pendingCard!.view.addGestureRecognizer(tap)
                        var inserted = false
                        for index in 0...self.creatorArr.count-1 {
                            let card = self.creatorArr[index]
                            if self.pendingCard!.serialNumber < card.serialNumber {
                                self.creatorArr.insert(self.pendingCard!, at: index)
                                self.pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            self.creatorArr.append(self.pendingCard!)
                            self.pendingCard = nil
                        }
                    }
                }
            } else {
                self.showRemind(msg: "对手猜\(choosenNumber), 猜错了")
                if self.pendingCard != nil {
                    let tap = UITapGestureRecognizer(target: self, action: #selector(MainGameViewController.cardTap(ges:)))
                    self.pendingCard!.view.addGestureRecognizer(tap)
                    if SocketClient.share.role == .creator {
                        var inserted = false
                        for index in 0...self.playerArr.count-1 {
                            let card = self.playerArr[index]
                            if self.pendingCard!.serialNumber < card.serialNumber {
                                self.pendingCard!.isHidden = false
                                self.playerArr.insert(self.pendingCard!, at: index)
                                self.pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            self.playerArr.append(self.pendingCard!)
                            self.pendingCard =  nil
                        }
                    } else {
                        var inserted = false
                        for index in 0...self.creatorArr.count-1 {
                            let card = self.creatorArr[index]
                            if self.pendingCard!.serialNumber < card.serialNumber {
                                self.pendingCard!.isHidden = false
                                self.creatorArr.insert(self.pendingCard!, at: index)
                                self.pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            self.creatorArr.append(self.pendingCard!)
                            self.pendingCard =  nil
                        }
                    }
                }
            }
            UIView.animate(withDuration: 2, animations: { 
                self.reloadPlayerView()
                self.reloadCreatorView()
            }, completion: { (_) in
                if SocketClient.share.blackArr.count == 0 {
                    self.blackCardView.isHidden = true
                }
                if SocketClient.share.whiteArr.count == 0 {
                    self.whiteCardView.isHidden = true
                }
                if self.judgeResult() == .none {
                    SocketClient.share.changeTurn()
                } else if self.judgeResult() == SocketClient.share.role {
                    self.showRemind(msg: "你输了")
                } else {
                    self.showRemind(msg: "你赢了")
                }
            })
        }
        // Do any additional setup after loading the view.
    }
    
    func placedAllCard() {
        UIView.animate(withDuration: 3, animations: {
            self.reloadCreatorView()
        }) { (_) in
        }
        
        UIView.animate(withDuration: 3, animations: {
            self.reloadPlayerView()
        }) { (_) in
            if SocketClient.share.role == .creator {
                SocketClient.share.randomTurn()
            }
        }
    }
    
    func reloadCreatorView() {
        let width = CGFloat(50 * creatorArr.count)
        let startx = (self.view.frame.size.width - width)/2
        for index in 0...self.creatorArr.count-1 {
            let card = self.creatorArr[index]
            let x = startx + 50*CGFloat(index)
            var y : CGFloat = 10
            if SocketClient.share.role == .creator {
                if card.isHidden {
                    y = self.view.frame.size.height - 110
                } else {
                    y = self.view.frame.size.height - 130
                }
                card.view.label.text = "\(card.number())"
            } else {
                if card.isHidden {
                    y = 30
                    card.view.label.text = ""
                } else {
                    y = 50
                    card.view.label.text = "\(card.number())"
                }
            }
            card.view.label.textColor = card.labelColor()
            card.view.label.backgroundColor = card.color()
            card.view.setFrame(frame: CGRect(x: x, y: y, width: 50, height: 80))
        }
    }
    
    func reloadPlayerView() {
        let width = CGFloat(50 * playerArr.count)
        let startx = (self.view.frame.size.width - width)/2
        for index in 0...self.playerArr.count-1 {
            let card = self.playerArr[index]
            let x = startx + 50*CGFloat(index)
            var y : CGFloat = 10
            if SocketClient.share.role == .creator {
                if card.isHidden {
                    y = 30
                    card.view.label.text = ""
                } else {
                    y = 50
                    card.view.label.text = "\(card.number())"
                }
                
            } else {
                if card.isHidden {
                    y = self.view.frame.size.height - 110
                } else {
                    y = self.view.frame.size.height - 130
                }
                card.view.label.text = "\(card.number())"
            }
            card.view.label.textColor = card.labelColor()
            card.view.label.backgroundColor = card.color()
            card.view.setFrame(frame: CGRect(x: x, y: y, width: 50, height: 80))
        }
    }
    
    func showRemind(msg : String) {
//        self.remindLabel.layer.removeAllAnimations()
        self.remindLabel.alpha = 1
        self.remindLabel.text = msg
        self.remindLabel.isHidden = false
//        UIView.animate(withDuration: 3, animations: {
//            self.remindLabel.alpha = 0
//        }) { (finished) in
//            self.remindLabel.isHidden = true
//            self.remindLabel.alpha = 1
//        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnClicked(_ sender: UIButton) {
        SocketClient.share.stopUdp()
        self.navigationController?.popViewController(animated: true)
    }
    
    func judgeResult() -> RoleType {
        var hashide = false
        for item in creatorArr {
            if item.isHidden == true {
               hashide = true
            }
        }
        if !hashide {
            return .creator
        }
        hashide = false
        
        for item in playerArr {
            if item.isHidden == true {
                hashide = true
            }
        }
        if !hashide {
            return .player
        }
        return .none
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func cardTap(ges : UITapGestureRecognizer) {
        if (SocketClient.share.isYourTurn() && pendingCard != nil) || (SocketClient.share.isYourTurn() && blackCardView.isHidden == true && whiteCardView.isHidden == true) {
            if SocketClient.share.role == .creator {
                reloadPlayerView()
                for card in playerArr {
                    if card.serialNumber == UInt32(ges.view!.tag) {
                        if card.isHidden {
                            card.view.frame.origin.y += 20
                            SocketClient.share.chooseChad(number: card.serialNumber)
                            collectionView.isHidden = false
                            self.selectedCard = card
                        }
                        break
                    }
                }
            } else {
                
                reloadCreatorView()
                for card in creatorArr {
                    if card.serialNumber == UInt32(ges.view!.tag) {
                        if card.isHidden {
                            card.view.frame.origin.y += 20
                            SocketClient.share.chooseChad(number: card.serialNumber)
                            collectionView.isHidden = false
                            self.selectedCard = card
                        }
                        break
                    }
                }
            }
        }
    }

    @objc func blackCardTap(ges : UITapGestureRecognizer) {
        if SocketClient.share.isYourTurn() && pendingCard == nil {
            SocketClient.share.randomCard(color: true)
        }
    }
    @objc func whiteCardTap(ges : UITapGestureRecognizer) {
        if SocketClient.share.isYourTurn() && pendingCard == nil {
            SocketClient.share.randomCard(color: false)
        }
    }
}

extension MainGameViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberChooseCell", for: indexPath) as! NumberChooseCollectionViewCell
        
        cell.title.text = "\(indexPath.row)"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected \(indexPath.row)")
        if selectedCard != nil {
            SocketClient.share.conformResult(choosenNumber: indexPath.row, realNumber: Int(selectedCard!.serialNumber))
            
            if indexPath.row == Int(selectedCard!.number()) {
                self.showRemind(msg: "你猜\(indexPath.row), 猜对了")
                if SocketClient.share.role == .creator {
                    for card in self.playerArr {
                        if card.serialNumber == selectedCard!.serialNumber {
                            card.isHidden = false
                            break
                        }
                    }
                    if pendingCard != nil {
                        var inserted = false
                        for index in 0...self.creatorArr.count-1 {
                            let card = creatorArr[index]
                            if pendingCard!.serialNumber < card.serialNumber {
                                creatorArr.insert(pendingCard!, at: index)
                                pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            creatorArr.append(pendingCard!)
                            pendingCard = nil
                        }
                    }
                } else {
                    for card in self.creatorArr {
                        if card.serialNumber == selectedCard!.serialNumber {
                            card.isHidden = false
                            break
                        }
                    }
                    if pendingCard != nil {
                        var inserted = false
                        for index in 0...self.playerArr.count-1 {
                            let card = playerArr[index]
                            if pendingCard!.serialNumber < card.serialNumber {
                                playerArr.insert(pendingCard!, at: index)
                                pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            playerArr.append(pendingCard!)
                            pendingCard = nil
                        }
                    }
                }
            } else {
                self.showRemind(msg: "你猜\(indexPath.row), 猜错了")
                if pendingCard != nil {
                    if SocketClient.share.role == .creator {
                        var inserted = false
                        for index in 0...self.creatorArr.count-1 {
                            let card = creatorArr[index]
                            if pendingCard!.serialNumber < card.serialNumber {
                                pendingCard!.isHidden = false
                                creatorArr.insert(pendingCard!, at: index)
                                pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            creatorArr.append(pendingCard!)
                            pendingCard = nil
                        }
                    } else {
                        var inserted = false
                        for index in 0...self.playerArr.count-1 {
                            let card = playerArr[index]
                            if pendingCard!.serialNumber < card.serialNumber {
                                pendingCard!.isHidden = false
                                playerArr.insert(pendingCard!, at: index)
                                pendingCard = nil
                                inserted = true
                                break
                            }
                        }
                        if !inserted {
                            playerArr.append(pendingCard!)
                            pendingCard = nil
                        }
                    }
 
                }
            }
            UIView.animate(withDuration: 3, animations: {
                self.reloadPlayerView()
                self.reloadCreatorView()
            }, completion: { (_) in
                if self.judgeResult() == .none {
                    SocketClient.share.changeTurn()
                } else if self.judgeResult() == SocketClient.share.role {
                    self.showRemind(msg: "你输了")
                } else {
                    self.showRemind(msg: "你赢了")
                }
                
            })
            collectionView.isHidden = true
        }
    }
}
