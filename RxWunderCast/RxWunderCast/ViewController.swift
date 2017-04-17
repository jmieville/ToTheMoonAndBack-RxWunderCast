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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let textSearch = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
        
        style()
        //        ApiController.shared.currentWeather(city: "RxSwift")
        //            .observeOn(MainScheduler.instance)
        //            .subscribe(onNext: { data in
        //                self.tempLabel.text = "\(data.temperature)° C"
        //                self.iconLabel.text = data.icon
        //                self.humidityLabel.text = "\(data.humidity)%"
        //                self.cityNameLabel.text = data.cityName
        //            })
        //            .addDisposableTo(disposeBag)
        
        let search = Observable.from([textSearch, temperature])
            .merge()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").characters.count > 0 }
            .flatMap { text in
                return ApiController.shared.currentWeather(city: text ?? "Error")
                    .catchErrorJustReturn(ApiController.Weather.empty)
            }
            .asDriver(onErrorJustReturn: ApiController.Weather.empty)
        
        
        search.map { w in
            if self.tempSwitch.isOn {
                return "\(Int(Double(w.temperature) * 1.8 + 32))° F"
            } else {
                return "\(w.temperature)° C"
            }
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

