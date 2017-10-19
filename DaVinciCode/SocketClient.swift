//
//  SocketClient.swift
//  DaVinciCode
//
//  Created by cruzr on 2017/8/7.
//  Copyright © 2017年 martin. All rights reserved.
//

import UIKit
import CocoaAsyncSocket


enum RoleType : Int {
    case none = 100
    case creator
    case player
}

class Room {
    var host = ""
    var port = 0
    var creator = ""
    var roomName = ""
    var lastTime : Int64 = 0
}

class SocketClient: NSObject {
    
    static let share = SocketClient()
    
    var role : RoleType = .none
    var udpSocket : GCDAsyncUdpSocket?
    
    var tcpSocket : GCDAsyncSocket?
    
    var tempStr = ""
    var rooms : [Room] = [Room]()
    
    var turnRole : RoleType = .none
    
    var steps = [[String : Any]]()
    
    var allArr : [UInt32] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ,13 ,14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
    var blackArr : [UInt32] = []
    var whiteArr : [UInt32] = []
    
    var joinedPlayer : String? = nil
    
    var heartbeatTimer: DispatchSourceTimer?
    var pageStepTime: DispatchTimeInterval = .seconds(10)
    
    var roomCheckTimer: DispatchSourceTimer?
    var roomCheckTime: DispatchTimeInterval = .seconds(20)
    
    let socketQueue = DispatchQueue(label: "com.liyue.socket")

    var receiveRoomBlock : ((_ host : String, _ port : UInt16, _ roomName : String) -> Void)? = nil
    
    var noRoomBlock : (() -> Void)? = nil
    
    var playerJoinedBlock : ((_ playerNmae : String) -> Void)? = nil
    
    var dataInitedBlock : ((_ creatorArr : [UInt32], _ playerArr : [UInt32]) -> Void)? = nil
    
    var turnChangeBlock : (() -> Void)? = nil
    
    var sendCardBlock : ((_ role : RoleType, _ number : Int) -> Void)? = nil
    
    var selectCardBlock : ((_ role : RoleType, _ number : Int) -> Void)? = nil
    
    var chooseCardNumberBlock : ((_ number : UInt32) -> Void)? = nil

    var conformBlock : ((_ choosenNumber : UInt32, _ realNumber : UInt32) -> Void)? = nil
    
    override init() {
        super.init()
        
        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }
    
    func setUpUdp() {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try udpSocket?.enableBroadcast(true)
        } catch  {
            print("Error enableBroadcast (bind):\(error)")
        }
        
        do {
            try udpSocket?.bind(toPort: 10000)
        } catch  {
            print("Error binding:\(error)")
        }
        
        //            do {
        //                try udpSocket?.joinMulticastGroup(UBSocketModel.udpHost)
        //            } catch  {
        //                print("Error joinMulticastGroup (bind):\(error)")
        //            }
        
        do {
            try udpSocket?.beginReceiving()
        } catch  {
            print("Error receiving:\(error)")
        }
        
        print("ready")
        
        
    }
    
    func readyToAccept() {
        //初始化socket
        
        do {
            try tcpSocket?.accept(onPort: 10001)
        } catch  {
            
        }
    }
    
    func joinRoom() {
        
        
        let room = rooms[0]
        do {
            try tcpSocket!.connect(toHost: room.host, onPort: UInt16(10001), withTimeout: -1)
        } catch  {
            print("Error connect:\(error)")
        }
        var dic = [String:String]()
        dic["title"] = "joinRoom"
        dic["playerName"] = "player1"
        sendTcp(dic: dic)

    }
    
    func sendTcp(dic : [String : Any]) {
        let data : Data? = try? JSONSerialization.data(withJSONObject: dic)
        var str = String(data: data!, encoding: String.Encoding.utf8)!
        str += "|"
        tcpSocket?.write(str.data(using: .utf8)!, withTimeout: -1, tag: 0)
    }
    
    func startUdp() {
        
        role = .creator
        broadcaseUdp()
        if heartbeatTimer != nil {
            heartbeatTimer?.cancel()
            heartbeatTimer = nil
        }
        heartbeatTimer = DispatchSource.makeTimerSource(queue: socketQueue)
        
        heartbeatTimer?.schedule(deadline: .now() + pageStepTime, repeating: pageStepTime)
        heartbeatTimer?.setEventHandler {
            self.broadcaseUdp()
        }
        heartbeatTimer?.resume()
    }
    
    func stopUdp() {
        heartbeatTimer?.cancel()
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }
    
    func checkRooms() {
        if roomCheckTimer == nil {
            roomCheckTimer = DispatchSource.makeTimerSource(queue: socketQueue)
            
            roomCheckTimer?.schedule(deadline: .now() + roomCheckTime, repeating: roomCheckTime)
            roomCheckTimer?.setEventHandler {
                let time = Int64(Date().timeIntervalSince1970)
                var newrooms = [Room]()
                for room in self.rooms {
                    if time - room.lastTime < 20 {
                        newrooms.append(room)
                    }
                }
                self.rooms = newrooms
                if self.rooms.count > 0 {
                    self.receiveRoomBlock?(self.rooms[0].host, UInt16(self.rooms[0].port), self.rooms[0].roomName)
                } else {
                    self.noRoomBlock?()
                    self.roomCheckTimer?.cancel()
                    self.roomCheckTimer = nil
                }
                
            }
            roomCheckTimer?.resume()
        }
    }

    
    func broadcaseUdp() {
        //        let time = UInt64(Date().timeIntervalSince1970*1000)
        var dic : [String : Any] = [:]
        dic["title"] = "createRoom"
        dic["roomName"] = "Room1"
        dic["creator"] = "creator"
        let data : Data? = try? JSONSerialization.data(withJSONObject: dic)
        //data转换成String打印输出
        if let jsondata = data, let str = String(data: jsondata, encoding: String.Encoding.utf8) {
            self.udpSocket?.send(str.data(using: .utf8)!, toHost: "255.255.255.255", port: 10000, withTimeout: -1, tag: 0)
            print("send udp")
        }
    }
    
    func randomInitData() -> [UInt32] {
        var result : [UInt32] = [0, 0, 0, 0, 0, 0, 0, 0]
        for index in 0...7 {
            let t = arc4random() % UInt32(allArr.count)
            result[index] = allArr[Int(t)]
            allArr[Int(t)] = allArr.last!
            allArr.removeLast()
        }
        for item in allArr {
            if item % 2 == 1 {
                whiteArr.append(item)
            } else {
                blackArr.append(item)
            }
        }
        print("white = \(whiteArr)")
        print("black = \(blackArr)")
        return result
    }
    
    func randomTurn() {
        let t = arc4random() % UInt32(2)
        
        var dic = [String:String]()
        dic["title"] = "startTurn"
        if t == 0 {
            dic["turn"] = "creator"
            self.turnRole = .creator
        } else {
            dic["turn"] = "player"
            self.turnRole = .player
        }
        sendTcp(dic: dic)
        turnChangeBlock?()
        
//        if role == .creator {
//            sendCard()
//        }
    }
    
    func isYourTurn() -> Bool {
        return self.turnRole == self.role
    }
    
    func randomCard(color : Bool) {
        
        if color {
//            black
            if blackArr.count > 0 {
                let t = arc4random() % UInt32(blackArr.count)
                let number = blackArr[Int(t)]
                blackArr.remove(at: Int(t))
                
                var dic = [String:Any]()
                dic["title"] = "selectCard"
                dic["role"] = self.role.rawValue
                dic["number"] = number
                dic["blackArr"] = blackArr
                dic["whiteArr"] = whiteArr
                sendTcp(dic: dic)
                
                selectCardBlock?(RoleType(rawValue: dic["role"] as! Int)!, Int(number))
            }
        } else {
            if whiteArr.count > 0 {
                let t = arc4random() % UInt32(whiteArr.count)
                let number = whiteArr[Int(t)]
                whiteArr.remove(at: Int(t))
                
                var dic = [String:Any]()
                dic["title"] = "selectCard"
                dic["role"] = self.role.rawValue
                dic["number"] = number
                dic["blackArr"] = blackArr
                dic["whiteArr"] = whiteArr
                sendTcp(dic: dic)
                
                selectCardBlock?(RoleType(rawValue: dic["role"] as! Int)!, Int(number))
            }
        }
    }
    
    func chooseChad(number : UInt32) {
        var dic = [String:Any]()
        dic["title"] = "chooseCard"
        dic["number"] = number
        sendTcp(dic: dic)
    }
    
    func conformResult(choosenNumber : Int, realNumber : Int) {
        var dic = [String:Any]()
        dic["title"] = "conformResult"
        dic["choosenNumber"] = choosenNumber
        dic["realNumber"] = realNumber
        sendTcp(dic: dic)
    }
    
    func changeTurn() {
        if turnRole == .creator {
            turnRole = .player
        } else {
            turnRole = .creator
        }
        turnChangeBlock?()
        
//        if role == .creator {
//            sendCard()
//        }
    }
}

extension SocketClient : GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        if role == .creator {
            return
        }
        
        if let str = String(data: data, encoding: .utf8) {
            
            var parsedJSON: Any?
            do {
                parsedJSON = try JSONSerialization.jsonObject(with: str.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.mutableLeaves)
            } catch let error {
                print(error)
            }
            
            if let dic = parsedJSON as? [String : String] {
                if dic["title"] == "createRoom" {
                    var host : NSString? = nil
                    var port : UInt16 = 0
                    GCDAsyncUdpSocket.getHost(&host, port: &port, fromAddress: address)
                    print("host = \(String(describing: host)), port = \(port), str = \(str)")
                    
                    if host != nil, !(host?.contains("ffff"))! {
                        let time = Int64(Date().timeIntervalSince1970)
                        var exist = false
                        for existRoom in self.rooms {
                            if existRoom.host == host! as String {
                                exist = true
                                existRoom.lastTime = time
                            }
                        }
                        if !exist {
                            let room = Room()
                            room.roomName = dic["roomName"]!
                            room.creator = dic["creator"]!
                            room.host = host! as String
                            room.port = Int(port)
                            room.lastTime = time
                            self.rooms.append(room)
                        }
                        receiveRoomBlock?(host! as String, port, rooms[0].roomName)
                        checkRooms()
                    }
                }
            }
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        
    }
}
extension SocketClient : GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("did connect to host = \(host)")
        tcpSocket?.readData(withTimeout: -1, tag: 0)
        
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        if joinedPlayer == nil {
            tcpSocket = newSocket
            tcpSocket?.delegate = self
            tcpSocket?.readData(withTimeout: -1, tag: 0)
            stopUdp()
        } else {
            //todo 返回房间已满
            var dic = [String:String]()
            dic["title"] = "roomFull"
            let data : Data? = try? JSONSerialization.data(withJSONObject: dic)
            var str = String(data: data!, encoding: String.Encoding.utf8)!
            str += "|"
            newSocket.write(str.data(using: .utf8)!, withTimeout: -1, tag: 0)
//            newSocket.disconnect()
        }
        
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        tcpSocket?.readData(withTimeout: -1, tag: 0)
        
        if let str = String(data: data, encoding: .utf8) {
            print("Message didReceiveData : \(str)")
            
            for c in str.characters {
                if c != "|" {
                    tempStr += String(c)
                    
                } else {
                    parseDic(msg: tempStr)
                    tempStr = ""
                }
                
            }
            
        }
        
    }
    
    func parseDic(msg : String)  {
        
        var parsedJSON: Any?
        do {
            parsedJSON = try JSONSerialization.jsonObject(with: msg.data(using: .utf8)!, options: JSONSerialization.ReadingOptions.mutableLeaves)
        } catch let error {
            print(error)
        }
        if let dic = parsedJSON as? [String : Any] {
            if dic["title"] as! String == "joinRoom" {
                if joinedPlayer == nil {
                    if let playerName = dic["playerName"] {
                        joinedPlayer = playerName as! String
                        playerJoinedBlock?(playerName as! String)
                        
                        let arr = self.randomInitData()
                        var creatorArr = [UInt32]()
                        var playerArr = [UInt32]()
                        for index in 0...7 {
                       
                            if index % 2 == 1 {
                                creatorArr.append(arr[index])
                            } else {
                                playerArr.append(arr[index])
                            }
                        }
                        
                        var dic = [String:Any]()
                        dic["title"] = "initData"
                        dic["creatorArr"] = creatorArr
                        dic["playerArr"] = playerArr
                        dic["allArr"] = allArr
                        dic["step"] = self.steps.count
                        sendTcp(dic: dic)
                        self.dataInitedBlock?(creatorArr, playerArr)
                        self.steps.append(dic)
                    }
                }
            } else if dic["title"] as! String == "roomFull" {
                tcpSocket?.disconnect()
            } else if dic["title"] as! String == "initData" {
                let creatorArr = dic["creatorArr"] as! [UInt32]
                let playerArr = dic["playerArr"] as! [UInt32]
                self.allArr = dic["allArr"] as! [UInt32]
                for item in self.allArr {
                    if item % 2 == 1 {
                        whiteArr.append(item)
                    } else {
                        blackArr.append(item)
                    }
                }
                print("white = \(whiteArr)")
                print("black = \(blackArr)")
                self.dataInitedBlock?(creatorArr, playerArr)
                self.steps.append(dic)
            } else if dic["title"] as! String == "startTurn" {
                if let turn = dic["turn"] as? String {
                    if turn == "creator" {
                        self.turnRole = .creator
                    } else {
                        self.turnRole = .player
                    }
                    self.turnChangeBlock?()
                }
            } else if dic["title"] as! String == "sendCard" {
                let role = dic["role"] as! RoleType.RawValue
                let number = dic["number"] as! Int
                sendCardBlock?(RoleType(rawValue: role)!, number)
            } else if dic["title"] as! String == "selectCard" {
                let role = dic["role"] as! RoleType.RawValue
                let number = dic["number"] as! Int
                self.blackArr = dic["blackArr"] as! [UInt32]
                self.whiteArr = dic["whiteArr"] as! [UInt32]
                selectCardBlock?(RoleType(rawValue: role)!, number)
            } else if dic["title"] as! String == "chooseCard" {
                let number = dic["number"] as! UInt32
                chooseCardNumberBlock?(number)
            } else if dic["title"] as! String == "conformResult" {
                let choosenNumber = dic["choosenNumber"] as! UInt32
                let realNumber = dic["realNumber"] as! UInt32
                conformBlock?(choosenNumber, realNumber)
            }
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("didWriteDataWithTag")
    }
    
    func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        
        return -1;
    }
}
