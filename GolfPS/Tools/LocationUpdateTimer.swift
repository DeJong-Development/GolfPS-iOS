//
//  LocationUpdateTimer.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/8/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation

protocol LocationUpdateTimerDelegate: class {
    func updateLocationsNow();
}

class LocationUpdateTimer {
    var timer:Timer!
    
    var delegate:LocationUpdateTimerDelegate?
    
    init() {
    }
    
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
        delegate = nil;
        timer?.invalidate();
    }
}
