//
//  Extensions.swift
//  RxWunderCast
//
//  Created by Jean-Marc Kampol Mieville on 4/17/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import Foundation
import MapKit
import RxSwift
import RxCocoa

class RxMKMapViewDelegateProxy: DelegateProxy, DelegateProxyType, MKMapViewDelegate {
    class func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let mapView: MKMapView = (object as? MKMapView)!
        return mapView.delegate
    }
    class func setCurrentDelegate(_ delegate: AnyObject?, toObject object:
        AnyObject) {
        let mapView: MKMapView = (object as? MKMapView)!
        mapView.delegate = delegate as? MKMapViewDelegate
    }
}

extension Reactive where Base: MKMapView {
    public var delegate: DelegateProxy {
        return RxMKMapViewDelegateProxy.proxyForObject(base)
    }
    
    public func setDelegate(_ delegate: MKMapViewDelegate) -> Disposable {
        return RxMKMapViewDelegateProxy.installForwardDelegate(
            delegate,
            retainDelegate: false,
            onProxyForObject: self.base
        ) }
    var overlays: UIBindingObserver<Base, [MKOverlay]> {
        return UIBindingObserver(UIElement: self.base) { mapView, overlays in
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlays(overlays)
        }
    }
    public var regionDidChangeAnimated: ControlEvent<Bool> {
        let source = delegate
            .methodInvoked(#selector(MKMapViewDelegate.mapView(_:regionDidChangeAnimated:)))
            .map { parameters in
                return (parameters[1] as? Bool) ?? false
        }
        return ControlEvent(events: source)
    }
}
