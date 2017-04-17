//
//  CLLocationManager+Rx.swift
//  RxWunderCast
//
//  Created by Jean-Marc Kampol Mieville on 4/17/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

class RxCLLocationManagerDelegateProxy: DelegateProxy, CLLocationManagerDelegate, DelegateProxyType {
    class func setCurrentDelegate(_ delegate: AnyObject?, toObject object:
        AnyObject) {
        let locationManager: CLLocationManager = object as! CLLocationManager
        locationManager.delegate = delegate as? CLLocationManagerDelegate
    }
    class func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let locationManager: CLLocationManager = object as! CLLocationManager
        return locationManager.delegate
    }
}

extension Reactive where Base: CLLocationManager {
    var delegate: DelegateProxy {
        return RxCLLocationManagerDelegateProxy.proxyForObject(base)
    }
    var didUpdateLocations: Observable<[CLLocation]> {
        return
            delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
        .map { parameters in
            return parameters[1] as! [CLLocation]
        } }
}
