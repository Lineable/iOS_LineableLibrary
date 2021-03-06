# LineableLibrary

[![CI Status](http://img.shields.io/travis/Doheny Yoon/LineableLibrary.svg?style=flat)](https://travis-ci.org/Doheny Yoon/LineableLibrary)
[![Version](https://img.shields.io/cocoapods/v/LineableLibrary.svg?style=flat)](http://cocoapods.org/pods/LineableLibrary)
[![License](https://img.shields.io/cocoapods/l/LineableLibrary.svg?style=flat)](http://cocoapods.org/pods/LineableLibrary)
[![Platform](https://img.shields.io/cocoapods/p/LineableLibrary.svg?style=flat)](http://cocoapods.org/pods/LineableLibrary)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Features
### Initialization

```swift
import LineableLibrary

class YourClass:UIViewController, LineableDetectorDelegate {

    let lineableDetector = LineableDetector.sharedDetector
    
    func viewDidLoad() {
        /*
        *  Customize Detecting Options. If DetectInterval and BackgroundMode is nil, it sets to default values. Delegate and apikey is required.
        */
        self.lineableDetector.setup(delegate: self, apiKey: "YOUR_API_KEY_HERE", detectInterval: 10.0, backgroundModeEnabled: nil)

        /*
        * Starts Tracking
        */
        self.lineableDetector.startTracking()
    }

}


```

All you have to is add LineableDetectorDelegate and initialize. You can also setup the detecting time and whether or not detecting occurs when the application enters background.

Don't forget to implement the delegate methods.

### Delegate Callbacks

```swift
func didStartRangingLineables() // Callbacks when tracking starts
func didStopRangingLineables() // Callbacks when tracking stops

func willDetectLineables() // Callbacks just before the detector prepares to send data to server.
func didDetectLineables(numberOfLineablesDetected:Int, missingLineable:MissingLineable?) // Callbacks when the Library Detects nearby Lineables via bluetooth. MissingLineable will have a value when there is a reported Lineable nearby. See below for more details about MissingLineable.
func didFailDetectingLineables(error:LineableDetectorError) // Callbacks when an error occurs while detecting
```

### MissingLineable
```swift
var seq:Int { get } // Unique Identifier
var name:String { get set } // Name of the Missing Lineable
var lineableDescription:String? { get set } // Description of the Missing Lineable
var photoUrls:[String] { get set } // Photo URLs of the Missing Lineable. Always has atleast one value. There can be up to 3 values.
var reporterName:String? { get set } // The person who reported this Lineable Missing
var reporterPhoneNumber:String? { get set } // The phone number of the reporter. You can use this to call the protector when the Missing Lineable is found.
var reportedDate:NSDate? { get set } // The date when reported.
```

## Requirements

Works with iOS 8.1 or up. If you want to implement in Objective-C, checkout the Objective-C Example [here](https://github.com/Lineable/iOS_LineableLibraryObjCExample).

## Installation

LineableLibrary is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "LineableLibrary"
```

**If your app supports iOS9.0 or above, you need to add support for background location service in Xcode. And also, you need to add NSApptransportSecurity parameter in your Info.plist. **
```
<key>NSAppTransportSecurity</key>
<dict>
<key>NSAllowsArbitraryLoads</key>
<true/>
</dict>
```
for instructions, [check this awesome answer in stackoverflow](http://stackoverflow.com/a/31023941)

## Author

Doheny Yoon, berrymelon@lineable.net

## License

LineableLibrary is available under the MIT license. See the LICENSE file for more info.
