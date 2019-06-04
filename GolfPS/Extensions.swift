//
//  Extensions.swift
//  GolfPS
//
//  Created by Greg DeJong on 1/12/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import UIKit

extension UIImage {
    
    func toNewSize(_ newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension Date {
    //    "2016-06-18T05:18:27.935Z"
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    var iso8601: String {
        return Date.iso8601Formatter.string(from: self)
    }
    //    Thu Jan 26 19:36:56 2017 UTC
    //    Thu, 26 Jan 2017 14:16:05 -0500
    static let standardFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE dd MMM HH:mm:ss yyyy 'UTC'"
        return formatter
    }()
    var standard: String {
        return Date.standardFormatter.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Date.iso8601Formatter.date(from: self)
    }
    
    var qrCode: UIImage? {
        let data = self.data(using: .ascii)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("L", forKey: "inputCorrectionLevel") //error resiliancy "L" low, "H" high, "M" medium, "Q" quality
        
        var finalImage:UIImage? = nil
        let transform = CGAffineTransform(scaleX: 10.0, y: 10.0)
        
        if let filter = filter, let output = filter.outputImage {
            
            let outputScaled = output.transformed(by: transform)
            let context:CIContext = CIContext.init(options: nil)
            let cgImage:CGImage = context.createCGImage(outputScaled, from: outputScaled.extent)!
            finalImage = UIImage.init(cgImage: cgImage)
        }
        return finalImage
    }
    var aztecCode: UIImage? {
        let data = self.data(using: .ascii)
        let filter = CIFilter(name: "CIAztecCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        
        var finalImage:UIImage? = nil
        let transform = CGAffineTransform(scaleX: 10.0, y: 10.0)
        
        if let filter = filter, let output = filter.outputImage {
            
            let outputScaled = output.transformed(by: transform)
            let context:CIContext = CIContext.init(options: nil)
            let cgImage:CGImage = context.createCGImage(outputScaled, from: outputScaled.extent)!
            finalImage = UIImage.init(cgImage: cgImage)
        }
        return finalImage
    }
}
