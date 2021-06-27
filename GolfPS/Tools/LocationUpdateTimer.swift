//
//  LocationUpdateTimer.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/8/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation

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
