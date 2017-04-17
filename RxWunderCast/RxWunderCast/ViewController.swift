//
//  ViewController.swift
//  RxWunderCast
//
//  Created by Jean-Marc Kampol Mieville on 4/16/2560 BE.
//  Copyright © 2560 Jean-Marc Kampol Mieville. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let disposeBag = DisposeBag()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        
        
        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").characters.count > 0 }
        
        let textSearch = searchInput.flatMap { text in
            return ApiController.shared.currentWeather(city: text ?? "Error")
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        mapButton.rx.tap
            .subscribe(onNext: {
                self.mapView.isHidden = !self.mapView.isHidden
            })
        .addDisposableTo(disposeBag)
        
        let currentLocation = locationManager.rx.didUpdateLocations
            .map { locations in
                return locations[0]
            }
            .filter { location in
                return location.horizontalAccuracy < kCLLocationAccuracyHundredMeters
        }
        
        let geoInput = geoLocationButton.rx.tap.asObservable()
            .do(onNext: {
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
        let geoLocation = geoInput.flatMap {
            return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation.flatMap { location in
            return ApiController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        let mapInput = mapView.rx.regionDidChangeAnimated
        .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        
        let mapSearch = mapInput.flatMap { coordinate in
            return ApiController.shared.currentWeather(lat: coordinate.latitude, lon: coordinate.longitude)
            .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        let search = Observable.from([geoSearch, textSearch, mapSearch])
            .merge()
            .asDriver(onErrorJustReturn: ApiController.Weather.dummy)
        
        let running = Observable.from([
            searchInput.map { _ in true },
            geoInput.map { _ in true },
            mapInput.map { _ in true },
            search.map { _ in false }.asObservable()
            ])
            .merge()
            .startWith(true)
            .asDriver(onErrorJustReturn: false)
        running
            .skip(1)
            .drive(activityIndicator.rx.isAnimating)
            .addDisposableTo(disposeBag)
        
        running
            .drive(tempLabel.rx.isHidden)
            .addDisposableTo(disposeBag)
        running
            .drive(iconLabel.rx.isHidden)
            .addDisposableTo(disposeBag)
        running
            .drive(humidityLabel.rx.isHidden)
            .addDisposableTo(disposeBag)
        running
            .drive(cityNameLabel.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        search.map { w in
            if self.tempSwitch.isOn {
                return "\(Int(Double(w.temperature) * 1.8 + 32))° F"
            }
                return "\(w.temperature)° C"
            }
            .drive(tempLabel.rx.text)
            .addDisposableTo(disposeBag)
        search.map { $0.icon }
            .drive(iconLabel.rx.text)
            .addDisposableTo(disposeBag)
        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .addDisposableTo(disposeBag)
        search.map { $0.cityName }
            .drive(cityNameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        mapView.rx.setDelegate(self)
        .addDisposableTo(disposeBag)
        
        search.map { [$0.overlay()] }
            .drive(mapView.rx.overlays)
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) ->
        MKOverlayRenderer {
            if let overlay = overlay as? ApiController.Weather.Overlay {
                let overlayView = ApiController.Weather.OverlayView(overlay:
                    overlay, overlayIcon: overlay.icon)
                return overlayView
            }
            return MKOverlayRenderer()
    }
}

