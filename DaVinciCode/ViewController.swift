//
//  ViewController.swift
//  DaVinciCode
//
//  Created by cruzr on 2017/8/5.
//  Copyright © 2017年 martin. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ViewController: UIViewController {

    var udpSocket : GCDAsyncUdpSocket?
    var tcpSocket : GCDAsyncSocket?
    
    var heartbeatTimer: DispatchSourceTimer?
    var pageStepTime: DispatchTimeInterval = .seconds(10)
    
    let socketQueue = DispatchQueue(label: "com.liyue.socket")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startUdp()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startUdp() {
        if udpSocket == nil {
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
            
            if heartbeatTimer != nil {
                heartbeatTimer?.cancel()
                heartbeatTimer = nil
            }
            
            broadcaseUdp()
            
            heartbeatTimer = DispatchSource.makeTimerSource(queue: socketQueue)
            
            heartbeatTimer?.scheduleRepeating(deadline: .now() + pageStepTime, interval: pageStepTime)
            heartbeatTimer?.setEventHandler {
                self.broadcaseUdp()
            }
            // 启动定时器
            heartbeatTimer?.resume()
        }
    }
    
    func broadcaseUdp() {
//        let time = UInt64(Date().timeIntervalSince1970*1000)
        var dic : [String : Any] = [:]
        dic["title"] = "creatrRoom"
        dic["roomName"] = "Room1"
        dic["creater"] = "creater"
        let data : Data? = try? JSONSerialization.data(withJSONObject: dic)
        //data转换成String打印输出
        if let jsondata = data, let str = String(data: jsondata, encoding: String.Encoding.utf8) {
            self.udpSocket?.send(str.data(using: .utf8)!, toHost: "255.255.255.255", port: 10000, withTimeout: -1, tag: 0)
        }
    }

}

extension ViewController : GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let str = String(data: data, encoding: .utf8) {
            var host : NSString? = nil
            var port : UInt16 = 0
            GCDAsyncUdpSocket.getHost(&host, port: &port, fromAddress: address)
            print("host = \(host), port = \(port), str = \(str)")
            if host != nil {
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
