//
//  SocketClient.swift
//  DaVinciCode
//
//  Created by cruzr on 2017/8/7.
//  Copyright © 2017年 martin. All rights reserved.
//

import UIKit
import CocoaAsyncSocket


enum RoleType {
    case none
    case creator
    case Player
}

class Room {
    var host = ""
    var port = 0
    var creator = ""
    var roomName = ""
}

class SocketClient: NSObject {
    
    static let share = SocketClient()
    
    var role : RoleType = .none
    var udpSocket : GCDAsyncUdpSocket?
    var tcpSocket : GCDAsyncSocket?
    
    var room : Room? = nil
    
    var heartbeatTimer: DispatchSourceTimer?
    var pageStepTime: DispatchTimeInterval = .seconds(10)
    
    let socketQueue = DispatchQueue(label: "com.liyue.socket")

    var receiveRoomBlock : ((_ host : String, _ port : UInt16, _ roomName : String) -> Void)? = nil
    
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
    
    func startUdp() {
        role = .creator
        broadcaseUdp()
        if heartbeatTimer != nil {
            heartbeatTimer?.cancel()
            heartbeatTimer = nil
        }
        heartbeatTimer = DispatchSource.makeTimerSource(queue: socketQueue)
        
        heartbeatTimer?.scheduleRepeating(deadline: .now() + pageStepTime, interval: pageStepTime)
        heartbeatTimer?.setEventHandler {
            self.broadcaseUdp()
        }
        heartbeatTimer?.resume()
    }

    
    func broadcaseUdp() {
        //        let time = UInt64(Date().timeIntervalSince1970*1000)
        var dic : [String : Any] = [:]
        dic["title"] = "createRoom"
        dic["roomName"] = "Room1"
        dic["creater"] = "creater"
        let data : Data? = try? JSONSerialization.data(withJSONObject: dic)
        //data转换成String打印输出
        if let jsondata = data, let str = String(data: jsondata, encoding: String.Encoding.utf8) {
            self.udpSocket?.send(str.data(using: .utf8)!, toHost: "255.255.255.255", port: 10000, withTimeout: -1, tag: 0)
        }
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
                        
                        let room = Room()
                        room.roomName = dic["roomName"]!
                        room.creator = dic["creater"]!
                        room.host = host! as String
                        room.port = Int(port)
                        self.room = room
                        
                        receiveRoomBlock?(host! as String, port, room.roomName)
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
