//
//  PlayerUpdateTimer.swift
//  GolfPS
//
//  Created by Greg DeJong on 6/10/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import Foundation

protocol PlayerUpdateTimerDelegate: AnyObject {
    func updatePlayersNow();
}

class PlayerUpdateTimer {
    private var timer:Timer!
    
    weak var delegate:PlayerUpdateTimerDelegate?
    
    internal func startNewTimer(interval: Double, triggerImmediately:Bool = false) {
        self.timer = Timer.scheduledTimer(timeInterval: interval,
                                          target: self,
                                          selector: #selector(self.timeUpdate),
                                          userInfo: nil,
                                          repeats: true);
        if (triggerImmediately) {
            delegate?.updatePlayersNow()
        }
    }
    
    @objc private func timeUpdate() {
        delegate?.updatePlayersNow()
    }
    
    internal func invalidate() {
        delegate = nil
        timer?.invalidate()
        timer = nil
    }
}
