//
//  LocationUpdateTimer.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/8/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseFirestore

protocol LocationUpdateTimerDelegate: AnyObject {
    func updateLocationsNow();
}

class LocationUpdateTimer {
    private var timer:Timer!
    
    weak var delegate:LocationUpdateTimerDelegate?
    
    internal func startNewTimer(interval: Double, triggerImmediately:Bool = true) {
        self.timer = Timer.scheduledTimer(timeInterval: interval,
                                          target: self,
                                          selector: #selector(self.timeUpdate),
                                          userInfo: nil,
                                          repeats: true);
        if (triggerImmediately) {
            delegate?.updateLocationsNow()
        }
    }
    
    @objc private func timeUpdate() {
        delegate?.updateLocationsNow()
    }
    
    internal func invalidate() {
        delegate = nil
        timer?.invalidate()
        timer = nil
    }
}

protocol PlayerLocationServiceDelegate: AnyObject {
    func playerLocationService(_ service: PlayerLocationService, didUpdate location: CLLocation)
    func playerLocationService(_ service: PlayerLocationService, didChangeAuthorization isAuthorized: Bool)
}

private final class WeakLocationServiceDelegate {
    weak var value: PlayerLocationServiceDelegate?
    
    init(value: PlayerLocationServiceDelegate) {
        self.value = value
    }
}

class PlayerLocationService: NSObject {
    static let shared = PlayerLocationService()
    
    private let locationManager = CLLocationManager()
    private var delegates: [WeakLocationServiceDelegate] = []
    private var pendingLocationCompletions: [(GeoPoint?) -> Void] = []
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    var currentGeoPoint: GeoPoint? {
        return AppSingleton.shared.me?.geoPoint
    }
    
    func addDelegate(_ delegate: PlayerLocationServiceDelegate) {
        pruneDelegates()
        let delegateID = ObjectIdentifier(delegate)
        guard !delegates.contains(where: { $0.value.map { ObjectIdentifier($0) == delegateID } ?? false }) else {
            return
        }
        delegates.append(WeakLocationServiceDelegate(value: delegate))
    }
    
    func removeDelegate(_ delegate: PlayerLocationServiceDelegate) {
        let delegateID = ObjectIdentifier(delegate)
        delegates.removeAll { wrapper in
            guard let value = wrapper.value else {
                return true
            }
            return ObjectIdentifier(value) == delegateID
        }
        
        if delegates.isEmpty && pendingLocationCompletions.isEmpty {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func requestLocation(completion: ((GeoPoint?) -> Void)? = nil) {
        if let currentGeoPoint {
            completion?(currentGeoPoint)
            return
        }
        
        if let completion {
            pendingLocationCompletions.append(completion)
        }
        
        startLocationUpdates()
    }
    
    func startLocationUpdates() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            AppSingleton.shared.me?.geoPoint = nil
            flushPendingCompletions(with: nil)
            notifyAuthorizationChanged(isAuthorized: false)
        @unknown default:
            flushPendingCompletions(with: nil)
        }
    }
    
    private func pruneDelegates() {
        delegates.removeAll { $0.value == nil }
    }
    
    private func notifyLocationUpdated(_ location: CLLocation) {
        pruneDelegates()
        for delegate in delegates {
            delegate.value?.playerLocationService(self, didUpdate: location)
        }
    }
    
    private func notifyAuthorizationChanged(isAuthorized: Bool) {
        pruneDelegates()
        for delegate in delegates {
            delegate.value?.playerLocationService(self, didChangeAuthorization: isAuthorized)
        }
    }
    
    private func flushPendingCompletions(with geoPoint: GeoPoint?) {
        let completions = pendingLocationCompletions
        pendingLocationCompletions.removeAll()
        for completion in completions {
            completion(geoPoint)
        }
        
        if delegates.isEmpty && pendingLocationCompletions.isEmpty {
            locationManager.stopUpdatingLocation()
        }
    }
}

extension PlayerLocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        notifyAuthorizationChanged(isAuthorized: isAuthorized)
        
        if isAuthorized {
            manager.startUpdatingLocation()
        } else {
            AppSingleton.shared.me?.geoPoint = nil
            flushPendingCompletions(with: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else {
            return
        }
        
        AppSingleton.shared.me?.geoPoint = currentLocation.geopoint
        notifyLocationUpdated(currentLocation)
        flushPendingCompletions(with: currentLocation.geopoint)
    }
}
