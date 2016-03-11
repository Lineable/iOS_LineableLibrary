//
//  LineableHelpers.swift
//  LineableExample
//
//  Created by Berrymelon on 2/17/16.
//  Copyright © 2016 Lineable. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

public protocol UserProtocol {
    var id:String { get }
    var password:String { get set }
    var seq:Int { get }
    var countryCode:String? { get set }
    var name:String? { get set }
    var isAuth:Bool? { get set }
    var phoneModel:String? { get set }
    var phoneNumber:String? { get set }
    var phoneType:Int? { get set }
    var photoUrl:String? { get set }
    var token:String { get set }
    
    func httpHeaders() -> [String:String]
}

func ==(lhs: CLBeacon, rhs: CLBeacon) -> Bool {
    let lhsBeacon = lhs
    let rhsBeacon = rhs
    
    var shiftedSelfMinor = lhsBeacon.minor.intValue >> 8
    shiftedSelfMinor = shiftedSelfMinor << 8
    
    var shiftedBeaconMinor = rhsBeacon.minor.intValue >> 8
    shiftedBeaconMinor = shiftedBeaconMinor << 8
    
    if lhsBeacon.proximityUUID.UUIDString == rhsBeacon.proximityUUID.UUIDString && lhsBeacon.major == rhsBeacon.major && shiftedSelfMinor == shiftedBeaconMinor {
        return true
    }
    else {
        return false
    }
    
}

extension NSDate {
    
    public class func dateByString(dateString:String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        if let date:NSDate = dateFormatter.dateFromString(dateString) {
            return date
        }
        else {
            return NSDate()
        }
    }
    
    // or an extension function to format your date
    public func formattedWith(format:String)-> String {
        let formatter = NSDateFormatter()
        //formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)  // you can set GMT time
        formatter.timeZone = NSTimeZone.localTimeZone()        // or as local time
        formatter.dateFormat = format
        return formatter.stringFromDate(self)
    }
}

extension CLLocation {
    // In meteres
    class func distance(from: CLLocationCoordinate2D, to:CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distanceFromLocation(to)
    }
}

private let DeviceList = [
    /* iPod 5 */          "iPod5,1": "iPod Touch 5",
    /* iPhone 4 */        "iPhone3,1":  "iPhone 4", "iPhone3,2": "iPhone 4", "iPhone3,3": "iPhone 4",
    /* iPhone 4S */       "iPhone4,1": "iPhone 4S",
    /* iPhone 5 */        "iPhone5,1": "iPhone 5", "iPhone5,2": "iPhone 5",
    /* iPhone 5C */       "iPhone5,3": "iPhone 5C", "iPhone5,4": "iPhone 5C",
    /* iPhone 5S */       "iPhone6,1": "iPhone 5S", "iPhone6,2": "iPhone 5S",
    /* iPhone 6 */        "iPhone7,2": "iPhone 6",
    /* iPhone 6 Plus */   "iPhone7,1": "iPhone 6 Plus",
    /* iPhone 6S */       "iPhone8,2": "iPhone 6S",
    /* iPhone 6S Plus */  "iPhone8,1": "iPhone 6S Plus",
    /* iPad 2 */          "iPad2,1": "iPad 2", "iPad2,2": "iPad 2", "iPad2,3": "iPad 2", "iPad2,4": "iPad 2",
    /* iPad 3 */          "iPad3,1": "iPad 3", "iPad3,2": "iPad 3", "iPad3,3": "iPad 3",
    /* iPad 4 */          "iPad3,4": "iPad 4", "iPad3,5": "iPad 4", "iPad3,6": "iPad 4",
    /* iPad Air */        "iPad4,1": "iPad Air", "iPad4,2": "iPad Air", "iPad4,3": "iPad Air",
    /* iPad Air 2 */      "iPad5,1": "iPad Air 2", "iPad5,3": "iPad Air 2", "iPad5,4": "iPad Air 2",
    /* iPad Mini */       "iPad2,5": "iPad Mini", "iPad2,6": "iPad Mini", "iPad2,7": "iPad Mini",
    /* iPad Mini 2 */     "iPad4,4": "iPad Mini", "iPad4,5": "iPad Mini", "iPad4,6": "iPad Mini",
    /* iPad Mini 3 */     "iPad4,7": "iPad Mini", "iPad4,8": "iPad Mini", "iPad4,9": "iPad Mini",
    /* Simulator */       "x86_64": "Simulator", "i386": "Simulator"
]

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        //let mirror = reflect(machine)                // Swift 1.2
        let mirror = Mirror(reflecting: machine)  // Swift 2.0
        var identifier = ""
        
        // Swift 1.2 - if you use Swift 2.0 comment this loop out.
        //        for i in 0..<mirror.count {
        //            if let value = mirror[i].1.value as? Int8 where value != 0 {
        //                identifier.append(UnicodeScalar(UInt8(value)))
        //            }
        //        }
        
        // Swift 2.0 and later - if you use Swift 2.0 uncomment his loop
        for child in mirror.children where child.value as? Int8 != 0 {
            identifier.append(UnicodeScalar(UInt8(child.value as! Int8)))
        }
        
        return DeviceList[identifier] ?? identifier
    }
    
}