//
//  MapTools.swift
//  GolfPS
//
//  Created by Greg DeJong on 4/20/18.
//  Copyright © 2018 DeJong Development. All rights reserved.
//

import Foundation
import FirebaseFirestore
import GoogleMaps

class MapTools {
    
    public func getBoundsCenter(_ bounds:GMSCoordinateBounds) -> CLLocationCoordinate2D {
        let ne = bounds.northEast;
        let sw = bounds.southWest;
        
        let latCenter = (ne.latitude + sw.latitude) / 2;
        let longCenter = (ne.longitude + sw.longitude) / 2;
        
        return CLLocationCoordinate2D(latitude: latCenter, longitude: longCenter)
    }
    public func getBoundsZoomLevel(bounds:GMSCoordinateBounds, screenSize:CGRect) -> Float {
        let WORLD_DIM:(width:Double, height:Double) = (width: 256, height: 256)
        let ZOOM_MAX:Float = 20
    
        func latRad(lat:Double) -> Double {
            let sinRad = sin(lat * .pi / 180)
            let radX2 = log((1 + sinRad) / (1 - sinRad)) / 2
            return max(min(radX2, .pi), -.pi) / 2
        }
        
        func zoom(mapPx:Double, worldPx:Double, fraction:Double) -> Float {
            return Float(log(mapPx / worldPx / fraction) / log(2))
        }
        
        let ne = bounds.northEast
        let sw = bounds.southWest
        
        let latFraction = (latRad(lat: ne.latitude) - latRad(lat: sw.latitude)) / .pi
        
        let lngDiff = ne.longitude - sw.longitude
        let lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360
        
        let latZoom = zoom(mapPx: Double(screenSize.height), worldPx: WORLD_DIM.height, fraction: latFraction)
        let lngZoom = zoom(mapPx: Double(screenSize.width), worldPx: WORLD_DIM.width, fraction: lngFraction)
        
        return min(latZoom, lngZoom, ZOOM_MAX)
    }
    
    public func getCircularFitZoomLevel(holeLength: Double, holeWidth: Double, screenSize:CGRect) -> Float {
        let WORLD_DIM:(width:Double, height:Double) = (width: 256, height: 256)
        let ZOOM_MAX:Float = 20
        
        func zoom(mapPx:Double, worldPx:Double, fraction:Double) -> Float {
            return Float(log(mapPx / worldPx / fraction) / log(2))
        }
        
        //convert required distance to a zoom level - tuned to a value that works
        let verticalZoom = zoom(mapPx: Double(screenSize.height), worldPx: WORLD_DIM.height, fraction: holeLength / 30000000)
        let horizontalZoom = zoom(mapPx: Double(screenSize.width), worldPx: WORLD_DIM.width, fraction: holeWidth / 30000000)
        
        return min(verticalZoom, horizontalZoom, ZOOM_MAX)
    }
    
    public func coordinates(startingCoordinates: CLLocationCoordinate2D, atDistance: Double, atAngle: Double) -> CLLocationCoordinate2D {
        let earthsRadiusInYards:Double = 6371 * 1093.6133;
        let earthsRadiusInMeters:Double = 6371 * 1000;
        
        var angularDistance:Double = 0
        if (AppSingleton.shared.metric) {
            angularDistance = atDistance / earthsRadiusInMeters;
        } else {
            angularDistance = atDistance / earthsRadiusInYards;
        }
        
        let bearingRadians = self.degreesToRadians(degrees: atAngle)
        let fromLatRadians = self.degreesToRadians(degrees: startingCoordinates.latitude)
        let fromLonRadians = self.degreesToRadians(degrees: startingCoordinates.longitude)
        
        let toLatRadians = asin(sin(fromLatRadians) * cos(angularDistance) + cos(fromLatRadians) * sin(angularDistance) * cos(bearingRadians))
        var toLonRadians = fromLonRadians + atan2(sin(bearingRadians) * sin(angularDistance) * cos(fromLatRadians), cos(angularDistance) - sin(fromLatRadians) * sin(toLatRadians));
        
        toLonRadians = fmod((toLonRadians + 3 * .pi), (2 * .pi)) - .pi
        
        let lat = self.radiansToDegrees(radians: toLatRadians)
        let lon = self.radiansToDegrees(radians: toLonRadians)
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    public func calcBearing(start: GeoPoint, finish: GeoPoint) -> Double {
        let latRad1:Double = degreesToRadians(degrees: start.latitude)
        let latRad2:Double = degreesToRadians(degrees: finish.latitude)
        let longDiff:Double = degreesToRadians(degrees: finish.longitude-start.longitude)
        let y:Double = sin(longDiff) * cos(latRad2)
        let x:Double = cos(latRad1) * sin(latRad2) - sin(latRad1) * cos(latRad2) * cos(longDiff)
        
        let calcBearing:Double = (radiansToDegrees(radians: atan2(y, x)) + 360).truncatingRemainder(dividingBy: 360)
        return calcBearing
    }
    
    public func degreesToRadians(degrees:Double) -> Double {
        return degrees * .pi / 180
    }
    public func radiansToDegrees(radians:Double) -> Double {
        return radians * 180 / .pi
    }
    
    public func distanceFrom(first:GeoPoint, second:GeoPoint) -> Int {
        let earthRadiusKm:Double = 6371
        
        var lat1:Double = first.latitude
        let lon1:Double = first.longitude
        var lat2:Double = second.latitude
        let lon2:Double = second.longitude
        
        let dLat:Double = Double(degreesToRadians(degrees: lat2-lat1))
        let dLon:Double = Double(degreesToRadians(degrees: lon2-lon1))
        
        lat1 = Double(degreesToRadians(degrees: lat1))
        lat2 = Double(degreesToRadians(degrees: lat2))
        
        let a:Double = sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
        let c:Double = 2 * atan2(sqrt(a), sqrt(1-a))
        
        if (AppSingleton.shared.metric) {
            return Int(earthRadiusKm * c * 1000) //convert km to meters
        } else {
            return Int(earthRadiusKm * c * 1000).toYards() //convert km to yards
        }
    }
    public func distanceFrom(first:CLLocationCoordinate2D, second:CLLocationCoordinate2D) -> Int {
        return distanceFrom(first: first.geopoint, second: second.geopoint)
    }
    public func distanceFrom(first:CLLocation, second:CLLocation) -> Int {
        return distanceFrom(first: first.geopoint, second: second.geopoint)
    }
}
