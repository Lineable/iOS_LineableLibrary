//
//  LineableDetector.swift
//  LineableDetector
//
//  Created by Berrymelon on 10/15/15.
//  Copyright © 2015 Lineable. All rights reserved.
//


import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

@objc public enum LineableDetectorError:Int {
    case BluetoothOff
    case NoLineableDetected
    case ConnectionFailed
    case ConnectionTimeout
    case GatewayDidNotMove
}

@objc public enum LineableDetectorState:Int {
    case Idle
    case Listening
}

@objc public protocol LineableDetectorDelegate {
    
    func didStartRangingLineables()
    func didStopRangingLineables()
    
    func willDetectLineables()
    func didDetectLineables(numberOfLineablesDetected:Int, missingLineable:MissingLineable?)
    func didFailDetectingLineables(error:LineableDetectorError)
}

public protocol LineableDetectorProtocol {
    func updateLineables(withListenedBeacons beacons:[CLBeacon])
    func connectedLineables()->[[String:String]]
}

public class LineableDetector: NSObject, CLLocationManagerDelegate, LineableHTTP {
    
    public static let sharedDetector = LineableDetector()
    
    public var state:LineableDetectorState = .Idle
    
    private var delegate:LineableDetectorDelegate? = nil
    private var apiKey:String = ""
    private var detectInterval = 60.0
    private var backgroundModeEnabled = true
    
    public var lineableDetectorProtocol:LineableDetectorProtocol? = nil
    
    public var missingLineable:MissingLineable? = nil
    public var user:UserProtocol? = nil
    
    let locationManager:CLLocationManager = CLLocationManager()
    public var lastLocation:CLLocation?
    
    var lineableRegions = LineableRegions()
    var isTracking = false
    var isPreparingDetection = false
    
    let kListeningTime = 5.0
    
    var listenedBeacons = [CLBeacon]()
    
    var gateway:Gateway? = nil
    
    private var didListenToAllRegions = false
    private var regionsListened:[String:Bool] = [String:Bool]()
    
    private override init() {
        super.init()
        
        let region = LineableRegions()
        for uuid in region.uuidstrs {
            regionsListened[uuid] = false
        }
        
        self.locationManager.requestAlwaysAuthorization()
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10.0
        self.locationManager.pausesLocationUpdatesAutomatically = true;
        self.locationManager.delegate = self
        
        self.locationManager.startUpdatingLocation()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationEnteredBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    dynamic private func applicationEnteredBackground() {
        if !self.backgroundModeEnabled && self.isTracking {
            self.stop()
        }
    }
    
    dynamic private func applicationWillEnterForeground() {
        if !self.backgroundModeEnabled && self.isTracking {
            self.start()
        }
    }
    
    //MARK: Only For ObjC
    public func setup(delegate delegate:LineableDetectorDelegate,apiKey:String) {
        self.setup(delegate: delegate, apiKey: apiKey, detectInterval: detectInterval, backgroundModeEnabled: backgroundModeEnabled)
    }
    public func setDetectInterval(interval:Double) {
        self.detectInterval = interval
    }
    public func setBackgroundMode(enabled:Bool) {
        self.backgroundModeEnabled = enabled
    }
    
    //MARK: For Swift
    public func setup(delegate delegate:LineableDetectorDelegate,apiKey:String,detectInterval:Double?,backgroundModeEnabled:Bool?) {
        
        self.delegate = delegate
        self.apiKey = apiKey
        
        if let detectInterval = detectInterval {
            if detectInterval < 10.0 { self.detectInterval = 10.0 }
            else { self.detectInterval = detectInterval }
        }
        
        if let backgroundModeEnabled = backgroundModeEnabled {
            self.backgroundModeEnabled = backgroundModeEnabled
        }
    }
    
    public func stop() {
        
        self.isTracking = false
        
        for region in lineableRegions.regions {
            let locationRegion = region as CLRegion
            locationManager.stopMonitoringForRegion(locationRegion)
        }
        
        self.state = .Idle
        self.stopRanging()
    }
    
    public func start() {
        
        self.isTracking = true
        
        for region in lineableRegions.regions {
            let locationRegion = region as CLRegion
            locationManager.startMonitoringForRegion(locationRegion)
        }
        
        self.state = .Listening
        self.startRanging()
    }
    
    private func startRanging() {
        
        var rangingCount = 0
        
        for region in lineableRegions.regions {
            
            if !lineableRegions.isRangingForRegion[region.proximityUUID.UUIDString]! {
                locationManager.startRangingBeaconsInRegion(region)
                lineableRegions.isRangingForRegion[region.proximityUUID.UUIDString] = true
                
                rangingCount++
            }
            
        }
        
        if rangingCount > 0 {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.didStartRangingLineables()
            }
        }
        
    }
    
    private func stopRanging() {
        
        var rangingCount = 0
        
        for region in lineableRegions.regions {
            
            if lineableRegions.isRangingForRegion[region.proximityUUID.UUIDString]! {
                locationManager.stopRangingBeaconsInRegion(region)
                
                lineableRegions.isRangingForRegion[region.proximityUUID.UUIDString] = false
                
                rangingCount++
            }
            
        }
        
        if rangingCount > 0 {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.didStopRangingLineables()
            }
        }
        
    }
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if self.backgroundModeEnabled {
            self.start()
        }
        
    }
    
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        if self.backgroundModeEnabled {
            self.start()
        }
    }
    
    public func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        if self.backgroundModeEnabled {
            self.start()
        }
    }
    
    public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        for uuid in self.regionsListened.keys {
            if region.proximityUUID.UUIDString == uuid {
                self.regionsListened[uuid] = true
                break
            }
        }
        
        var filteredBeacons = [CLBeacon]()
        for beacon in beacons {
            if beacon.rssi < 0 || beacon.proximity != CLProximity.Unknown {
                filteredBeacons.append(beacon)
            }
        }
        
        for beacon in beacons {
            
            var hasIt = false
            
            for b in self.listenedBeacons {
                if b == beacon {
                    hasIt = true
                    break
                }
            }
            
            if !hasIt {
                self.listenedBeacons.append(beacon)
            }
        }
        
        if allRegionsListened() {
            
            self.lineableDetectorProtocol?.updateLineables(withListenedBeacons: self.listenedBeacons)
            
            self.detectToServerIfPossible()
            self.checkForHeartBeat()
        }
        
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        var location:CLLocation? = nil
        
        for l in locations {
            let newLocation = l
            let newLocationAge = -newLocation.timestamp.timeIntervalSinceNow
            
            if newLocationAge > 60.0 || !CLLocationCoordinate2DIsValid(newLocation.coordinate) {
                continue
            }
            
            if newLocation.horizontalAccuracy > 0 {
                location = newLocation
            }
        }
        
        self.lastLocation = location
        
        if let timeStamp = self.lastDetectTimeStamp {
            let interval:Double = NSDate().timeIntervalSinceDate(timeStamp)
            if interval >= self.detectInterval {
                
                if self.isTracking {
                    start()
                }
                
            }
        }
        
    }
    
    private var lastDetectTimeStamp:NSDate? {
        get {
            if NSUserDefaults.standardUserDefaults().objectForKey("LineableLib_DetectTimeStamp") != nil {
                return NSUserDefaults.standardUserDefaults().objectForKey("LineableLib_DetectTimeStamp") as? NSDate
            }
            else {
                return nil
            }
        }
        set (newValue) {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "LineableLib_DetectTimeStamp")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var lastHeartbeatTimeStamp:NSDate? {
        get {
            if NSUserDefaults.standardUserDefaults().objectForKey("LineableLib_HeartbeatTimeStamp") != nil {
                return NSUserDefaults.standardUserDefaults().objectForKey("LineableLib_HeartbeatTimeStamp") as? NSDate
            }
            else {
                return nil
            }
        }
        set (newValue) {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "LineableLib_HeartbeatTimeStamp")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var movingGatewayDistanceLimit = 50.0
    private var previousCoordinate:CLLocationCoordinate2D?
    private func detectToServerIfPossible() {
        
        if self.isPreparingDetection || !self.isTracking {
            return
        }
        
        var timeStamp:NSDate? = nil
        if self.lastDetectTimeStamp != nil {
            timeStamp = self.lastDetectTimeStamp
        }
        
        var needsToDetect = false
        if timeStamp == nil {
            needsToDetect = true
        }
        else {
            
            let interval:Double = NSDate().timeIntervalSinceDate(timeStamp!)
            let locationTimer = self.detectInterval
            if interval >= locationTimer {
                needsToDetect = true
            }
        }
        
        if let gateway = self.gateway where gateway.coordinate == nil && needsToDetect {
            if let previousCoordinate = self.previousCoordinate, lastLocationCoordinate = self.lastLocation?.coordinate {
                //had previous coordinate. check if moved, if not, send to server
                let distance = CLLocation.distance(previousCoordinate, to: lastLocationCoordinate)
                if distance >= self.movingGatewayDistanceLimit {
                    needsToDetect = true
                }
                else {
                    needsToDetect = false
                }
            }
            else {
                //dont have previous coordinate. send right now
                needsToDetect = true
            }
        }
        
        if needsToDetect {
            self.detectAndSendToServer()
        }
        else {
            self.listenedBeacons.removeAll()
        }
    }
    
    private func checkForHeartBeat() {
        var heartbeatTimeStamp:NSDate? = nil
        if self.lastHeartbeatTimeStamp != nil {
            heartbeatTimeStamp = self.lastHeartbeatTimeStamp
        }
        
        if heartbeatTimeStamp == nil {
            self.sendHeartbeat()
        }
        else {
            
            let interval:Double = NSDate().timeIntervalSinceDate(heartbeatTimeStamp!)
            
            let locationTimer:Double = 3600
            if interval >= locationTimer {
                self.sendHeartbeat()
            }
        }
    }
    
    private func detectAndSendToServer() {
        self.isPreparingDetection = true
        self.listenedBeacons.removeAll(keepCapacity: false)
        self.lastDetectTimeStamp = NSDate()
        self.delegate?.willDetectLineables()
        NSTimer.scheduledTimerWithTimeInterval(kListeningTime, target: self, selector: Selector("sendLineablesToServer"), userInfo: nil, repeats: false)
    }
    
    func sendHeartbeat() {
        self.lastHeartbeatTimeStamp = NSDate()
        self.sendHeartbeat(self.lastLocation)
    }
    
    func sendLineablesToServer() {
        if self.listenedBeacons.count == 0 {
            self.isPreparingDetection = false
            self.delegate?.didFailDetectingLineables(.NoLineableDetected)
            return
        }
        
        var connectedLineables = [[String:String]]()
        if let hasConnectedLineables = self.lineableDetectorProtocol?.connectedLineables() {
            connectedLineables = hasConnectedLineables
        }
        
        self.sendDetectedBeacons(self.listenedBeacons, connectedLineables: connectedLineables, completion: { (result,missingLineable) in
            self.isPreparingDetection = false
            
            let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.0 * Double(NSEC_PER_SEC)))
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                if result == 200 {
                    self.missingLineable = missingLineable
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate?.didDetectLineables(self.listenedBeacons.count, missingLineable:missingLineable)
                        self.listenedBeacons.removeAll()
                    }
                }
                else if result == -1001 {
                    self.listenedBeacons.removeAll()
                    self.delegate?.didFailDetectingLineables(.ConnectionTimeout)
                }
                else {
                    self.listenedBeacons.removeAll()
                    self.delegate?.didFailDetectingLineables(.ConnectionFailed)
                }
            })
        })
        
    }
    
    private func allRegionsListened() -> Bool {
        
        var allListened = true
        for uuid in self.regionsListened.keys {
            
            if self.regionsListened[uuid] == false {
                allListened = false
                break
            }
        }
        
        if allListened {
            //Reset Listening Regions
            for uuid in self.regionsListened.keys {
                self.regionsListened[uuid] = false
            }
        }
        
        return allListened
    }

    public func sendDetectedBeacons(beacons:[CLBeacon],connectedLineables:[[String:String]], completion:(result:Int,missingLineable:MissingLineable?)->()) {
        
        var beaconsDicArray = [Dictionary<String,String>]()
        for beacon in beacons {
            
            let major = String(format: "%05d", beacon.major.integerValue);
            let minor = String(format: "%05d", beacon.minor.integerValue);
            
            let serial = "\(beacon.proximityUUID.UUIDString)-\(major)-\(minor)"
            let rssi = "\(beacon.rssi)"
            
            let beaconDic = ["serial":serial, "rssi":rssi]
            beaconsDicArray.append(beaconDic)
        }
        
        for lineableDic in connectedLineables {
            beaconsDicArray.append(lineableDic)
        }
        
        var accu = 0.0
        var loc = CLLocation(latitude: 0, longitude: 0)
        if let location = self.lastLocation {
            loc = location
            accu = location.horizontalAccuracy
        }
        
        var geoInfo = [String:Double]()
        
        var param:Dictionary<String,AnyObject> = ["beacons":beaconsDicArray, "api_key":self.apiKey]
        
        if let gateway = self.gateway {
            if let coordinate = gateway.coordinate {
                loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                accu = 0.0
            }
            
            param["name"] = gateway.name
        }
        else {
            if self.user != nil {
                param["user_seq"] = "\(self.user!.seq)"
                param["name"] = self.user!.name
            }
        }
        
        geoInfo = ["latitude":loc.coordinate.latitude, "longitude":loc.coordinate.longitude, "accuracy":accu]
        param["geo_info"] = geoInfo
        
        self.sendData("POST", url: "\(kDETECTURL)/detect", encoding:.JSON, params: param, completion: {(result,infoarray) in
            
            let info = infoarray as? [[String:AnyObject]]
            if info != nil {
                let missingLineable:[String:AnyObject]? = info?.count == 0 ? nil : info?[0]
                
                if let lineableDic = missingLineable {
                    let lineable = MissingLineable(withDic: lineableDic)
                    completion(result: result, missingLineable: lineable)
                }
                else {
                    completion(result: result, missingLineable: nil)
                }
            }
            else {
                completion(result: result, missingLineable: nil)
            }
            
        })
    }
    
    func sendHeartbeat(location:CLLocation?) {
        
        guard let deviceUUID = UIDevice.currentDevice().identifierForVendor?.UUIDString else {
            return
        }
        var accu = 0.0
        var loc = CLLocation(latitude: 0, longitude: 0)
        if location != nil {
            loc = location!
        }
        let accuracy = location?.horizontalAccuracy
        if accuracy != nil {
            accu = accuracy!
        }
        
        let geoInfo = ["latitude":loc.coordinate.latitude, "longitude":loc.coordinate.longitude, "accuracy":accu]
        
        let param:Dictionary<String,AnyObject> = ["type":"1", "id":deviceUUID, "geo_info":geoInfo]
        
        self.sendData("POST", url: "\(kDETECTURL)/heartbeat",encoding:.JSON, params: param, completion: {(result,info) in
            
        })
    }
}

struct Gateway {
    var name:String
    var id:String {
        get {
            return "iOS_Gateway_" + UIDevice.currentDevice().identifierForVendor!.UUIDString
        }
    }
    //0:Mobile
    //1:Stationary
    var coordinate:CLLocationCoordinate2D?
    
    var isStationary:Bool {
        get {
            
            if self.coordinate == nil {
                return false
            }
            
            return true
        }
    }
    
    init(name:String, coordinate:CLLocationCoordinate2D?) {
        self.name = name
        self.coordinate = coordinate
    }
}

struct LineableRegions {
    
    let uuidstrs:Array<String>
    let regions:Array<CLBeaconRegion>
    var isRangingForRegion = [String:Bool]()
    
    init () {
        
        var regions = [CLBeaconRegion]()
        
        #if DEBUG
            uuidstrs = ["6C4CB629-C88E-4C3E-94D1-F551181F1D18"]
        #else
            uuidstrs = ["C800AD13-745E-4F45-B2A6-E4AE774C4143",
                "91FE354D-A86B-4C5A-A156-B6C20707B204",
                "74278BDA-B644-4520-8F0C-720EAF059935",
                "D64DD386-53D6-4705-B33A-9B54266F6019",
                "9188CC84-45C1-4948-8121-52F93C7C62F0"
            ]
        #endif
        for uuidstr in uuidstrs {
            let uuid = NSUUID(UUIDString: uuidstr)
            let region = CLBeaconRegion(proximityUUID: uuid!, identifier: uuidstr)
            region.notifyEntryStateOnDisplay = true
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            regions.append(region)
            isRangingForRegion[uuidstr] = false
        }
        
        self.regions = regions
    }
    
}