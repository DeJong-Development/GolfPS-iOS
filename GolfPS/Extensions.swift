//
//  Extensions.swift
//  GolfPS
//
//  Created by Greg DeJong on 1/12/19.
//  Copyright © 2019 DeJong Development. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseFirestore

extension CLLocationCoordinate2D {
    var geopoint: GeoPoint {
        return GeoPoint(latitude: self.latitude,
                        longitude: self.longitude)
    }
}

extension GeoPoint {
    var location: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude,
                                      longitude: self.longitude)
    }
}

extension CLLocation {
    var geopoint: GeoPoint {
        return GeoPoint(latitude: self.coordinate.latitude,
                        longitude: self.coordinate.longitude)
    }
}

extension UIImage {
    
    func toNewSize(_ newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect.init(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect.init(x: 0, y: 0, width: thickness, height: frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect.init(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        self.addSublayer(border)
    }
}

extension Date {
    //    "2016-06-18T05:18:27.935Z"
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.autoupdatingCurrent
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
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "EEE dd MMM HH:mm:ss yyyy 'UTC'"
        return formatter
    }()
    var standard: String {
        return Date.standardFormatter.string(from: self)
    }
}

extension String {
    
    //https://www.objc.io/blog/2020/08/18/fuzzy-search/
    func fuzzyMatch(_ query: String) -> Bool {
        if query.isEmpty { return true }
        var remainder = query[...]
        for char in self {
            if char == remainder[remainder.startIndex] {
                remainder.removeFirst()
                if remainder.isEmpty { return true }
            }
        }
        return false
    }
        
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

extension UIColor {
    static var grass:UIColor = UIColor(named: "Grass")!
    static var gold:UIColor = UIColor(named: "Gold")!
    static var text:UIColor = UIColor(named: "Text")!
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF
        )
    }
    
    func transparenter(by percentage: CGFloat = 15.0) -> UIColor? {
        return self.transparentAdjust(by: -1 * abs(percentage) )
    }
    func opaquer(by percentage: CGFloat = 15.0) -> UIColor? {
        return self.transparentAdjust(by: abs(percentage) )
    }
    
    private func transparentAdjust(by percentage: CGFloat = 15.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: red,
                           green: green,
                           blue: blue,
                           alpha: min(1.0, max(0, alpha + percentage/100)))
        } else {
            return nil
        }
    }
    
    func lighter(by percentage: CGFloat = 15.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage: CGFloat = 15.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    private func adjust(by percentage: CGFloat = 15.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: max(0, min(red + percentage/100, 1.0)),
                           green: max(0, min(green + percentage/100, 1.0)),
                           blue: max(0, min(blue + percentage/100, 1.0)),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
