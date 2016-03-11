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
        // Do any additional setup after loading the view, typically from a nib.
        LineableDetector.sharedDetector.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startButtonTapped(sender: AnyObject) {
        
        if didStart {
            //Stop
            self.didStart = false
            self.startButton.setTitle("Start", forState: UIControlState.Normal)
            LineableDetector.sharedDetector.stopTracking()
        }
        else {
            //Start
            self.didStart = true
            self.startButton.setTitle("Stop", forState: UIControlState.Normal)
            LineableDetector.sharedDetector.startTracking()
        }
    }
    
    func didStartRangingLineables() {
        self.statusLabel.text = "Lineable Detector Started."
    }
    
    func didStopRangingLineables() {
        self.statusLabel.text = "Lineable Detector Stopped."
    }
    
    func didDetectLineables(numberOfLineablesDetected:Int, missingLineable:MissingLineable?) {
        let msg = "\(numberOfLineablesDetected) Lineable Detected."
        let missingText = missingLineable == nil ? "" : "\nMissingLineable: \(missingLineable?.name)"
        self.statusLabel.text = msg + missingText
    }
    
    func statuschanged(status:LineableDetectorState) {
        var msg = ""
        switch status {
        case LineableDetectorState.ErrorSendingLineable:
            msg = "Cannot send detect info to server."
        case LineableDetectorState.GatewayNoMovement:
            msg = "Gateway didn't move specific amount of distance."
        case LineableDetectorState.NoDetectedLineables:
            msg = "No Lineable Detected."
        case LineableDetectorState.Idle:
            msg = "Waiting.."
        case LineableDetectorState.PreparingToSendToServer:
            msg = "Listening to nearby Lineables."
        default:
            return
        }
        self.statusLabel.text = msg
    }
    
}

