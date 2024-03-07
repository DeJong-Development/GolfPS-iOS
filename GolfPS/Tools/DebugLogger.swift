//
//  DebugLogger.swift
//

import os
import Foundation
import FirebaseCrashlytics
import FirebaseFirestore

class DebugLogger {
    
    static func log(message: String) {
        #if DEBUG
        os_log("LOG: %@", message)
        #endif
        Crashlytics.crashlytics().log(message)
    }
    
    static func report(error: Error?, message: String? = nil) {
        guard let error = error else {
            return
        }
        self.report(error: error, message: message)
    }
        
    static func report(error: Error, message: String? = nil, isFatal: Bool = false) {
        let errorDescription = "\(message ?? "Error"): \(error.localizedDescription)"
        #if DEBUG
        os_log("ERROR: %@", type: .error, errorDescription)
        #endif
        
        if let optionalMessage = message {
            Crashlytics.crashlytics().log(optionalMessage)
        }
        Crashlytics.crashlytics().record(error: error)
        
        if let error = error as NSError?, error.domain == FirestoreErrorDomain {
            if let code = FirestoreErrorCode.Code(rawValue: error.code)?.rawValue {
                os_log("FIRESTORE ERROR CODE: %@", type: .error, "\(code)")
            }
        }
        
        if isFatal {
            fatalError(errorDescription)
        }
    }
}
