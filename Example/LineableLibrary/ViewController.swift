//
//  ViewController.swift
//  LineableLibrary
//
//  Created by Doheny Yoon on 03/11/2016.
//  Copyright (c) 2016 Doheny Yoon. All rights reserved.
//

import UIKit
import LineableLibrary

class ViewController: UIViewController, LineableDetectorDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    var didStart = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        *  Customize Detecting Options
        */
        LineableDetector.sharedDetector.setup(delegate: self, apiKey: "111111", detectInterval: 10.0, backgroundModeEnabled: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.didStart = LineableDetector.sharedDetector.state == LineableDetectorState.Idle ? false : true
        self.toggle()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startButtonTapped(sender: AnyObject) {
        self.didStart = !self.didStart
        self.toggle()
    }
    
    func toggle() {
        if didStart {
            //Start
            self.startButton.setTitle("Stop", forState: UIControlState.Normal)
            LineableDetector.sharedDetector.start()
        }
        else {
            //Stop
            self.startButton.setTitle("Start", forState: UIControlState.Normal)
            LineableDetector.sharedDetector.stop()
        }
    }
    
    func didStartRangingLineables() {
        self.statusLabel.text = "Lineable Detector Started."
    }
    
    func didStopRangingLineables() {
        self.statusLabel.text = "Lineable Detector Stopped."
    }
    
    func willDetectLineables() {
        self.statusLabel.text = "Preparing to detect nearby Lineables."
    }
    
    func didDetectLineables(numberOfLineablesDetected:Int, missingLineable:MissingLineable?) {
        let msg = "\(numberOfLineablesDetected) Lineable Detected."
        let missingText = missingLineable == nil ? "" : "\nMissingLineable: \(missingLineable!.name)"
        self.statusLabel.text = msg + missingText
    }
    
    func didFailDetectingLineables(error: LineableDetectorError) {
        var msg = ""
        switch error {
        case .BluetoothOff:
            msg = "Bluetooth is turned off"
        case .ConnectionFailed:
            msg = "Connection Failed with server"
        case .GatewayDidNotMove:
            msg = "Gateway didn't move specific amount of distance."
        case .NoLineableDetected:
            msg = "No Lineables Detected"
        case .ConnectionTimeout:
            msg = "Connection Timeout"
        }
        
        self.statusLabel.text = msg
    }

}

