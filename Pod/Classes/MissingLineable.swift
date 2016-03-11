//
//  MissingLineable.swift
//  Lineable
//
//  Created by Berrymelon on 3/8/16.
//  Copyright © 2016 Lineable. All rights reserved.
//

import Foundation

public protocol LineableProtocol {
    var seq:Int { get }
    var name:String { get set }
    var lineableDescription:String? { get set }
    var photoUrls:[String] { get set }
    var reporterName:String? { get set }
    var reporterPhoneNumber:String? { get set }
    var reportedDate:NSDate? { get set }
}

public class MissingLineable: NSObject, LineableProtocol {
    
    public var seq:Int
    public var name:String
    public var lineableDescription:String?
    public var photoUrls:[String]
    public var reporterName:String?
    public var reporterPhoneNumber:String?
    public var reportedDate:NSDate?
    
    init(withDic dic: [String : AnyObject]) {
        
        let childDic = dic["child"] as! [String:AnyObject]
        
        self.seq = childDic["seq"] as! Int
        
        self.name = childDic["firstName"] as! String
        self.lineableDescription = childDic["description"] as? String
        
        var photoUrls = [String]()
        let mainPhoto = childDic["photoUrl"] as! String
        photoUrls.append(mainPhoto)
        if let detailPhotoUrl1 = childDic["detailPhotoUrl1"] as? String {
            photoUrls.append(detailPhotoUrl1)
        }
        if let detailPhotoUrl2 = childDic["detailPhotoUrl2"] as? String {
            photoUrls.append(detailPhotoUrl2)
        }
        self.photoUrls = photoUrls
        
        self.reporterName = childDic["reporterName"] as? String
        self.reporterPhoneNumber = childDic["reporterPhoneNumber"] as? String
        if let dateStr = childDic["reportedDate"] as? String {
            self.reportedDate = NSDate.dateByString(dateStr)
        }
        else {
            self.reportedDate = nil
        }
    }

    
}