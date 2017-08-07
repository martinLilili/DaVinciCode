//
//  ViewController.swift
//  DaVinciCode
//
//  Created by cruzr on 2017/8/5.
//  Copyright © 2017年 martin. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    
    @IBOutlet weak var existRoomlable: UILabel! {
        didSet {
            existRoomlable.isHidden = true
        }
    }
    
    @IBOutlet weak var joinBtn: UIButton! {
        didSet {
            joinBtn.isHidden = true
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        SocketClient.share.setUpUdp()
        SocketClient.share.receiveRoomBlock = {(host, port, name) in
            self.existRoomlable.isHidden = false
            self.joinBtn.isHidden = false
            self.existRoomlable.text = "已存在房间：\(name)"
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func AIGameBtnClicked(_ sender: UIButton) {
    }
    
    @IBAction func createBtnClicked(_ sender: UIButton) {
        SocketClient.share.startUdp()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let gameVC = storyboard.instantiateViewController(withIdentifier: "MainGameViewController") as! MainGameViewController
        self.show(gameVC, sender: nil)
    }
    
    @IBAction func joinBtnClicked(_ sender: UIButton) {
    }

}
