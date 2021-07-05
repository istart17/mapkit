//
//  Utils.swift
//  LabTest
//
//  Created by iStart17 on 6/21/20.
//  Copyright © 2020 iStart17. All rights reserved.
//

import Foundation
import MapKit

struct PlaceAtan {
    var place: Place
    var atan: CGFloat
    
    init(p: Place, atan: CGFloat) {
        self.place = p
        self.atan  = atan
    }
}

class Utils {
    static let shared = Utils()
    
    func getAddressFromCoordinate(coordinate: CLLocationCoordinate2D, completion: @escaping (_ address: String) -> Void) {
        var addressString : String = ""
        let ceo: CLGeocoder = CLGeocoder()
        let loc: CLLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    
        ceo.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) in
            if (error != nil) {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            
            let pm = placemarks! as [CLPlacemark]

            if pm.count > 0 {
                let pm = placemarks![0]
                /*
                if pm.subLocality != nil {
                    addressString = addressString + pm.subLocality! + ", "
                }
                if pm.thoroughfare != nil {
                    addressString = addressString + pm.thoroughfare! + ", "
                }*/
                if pm.locality != nil {
                    addressString = addressString + pm.locality! // + ", "
                }
                /*
                if pm.country != nil {
                    addressString = addressString + pm.country! + ", "
                }
                if pm.postalCode != nil {
                    addressString = addressString + pm.postalCode! + " "
                }*/
                print("=================")
                print("address", addressString)
                completion(addressString)
            }
        })
    }
    
//    https://gamedev.stackexchange.com/questions/13229/sorting-array-of-points-in-clockwise-order
    func sortPlacesClockwise(places: [Place]) -> [Place] {
        var result:[Place] = []
        var atanArr:[PlaceAtan] = []
        // find the center place of all locations
        let locations = places.map { $0.coordinate }
        let centerLocation = middlePointOfListMarkers(listCoords: locations)
        let centerPlace = Place(title: "CENTER", subtitle: "", coordinate: centerLocation)
        let clatRad:CGFloat = degreeToRadian(angle: centerPlace.coordinate.latitude)
        let clonRad:CGFloat = degreeToRadian(angle: centerPlace.coordinate.longitude)
        
        let centerX: CGFloat = cos(clatRad) * cos(clonRad)
        let centerY: CGFloat = cos(clatRad) * sin(clonRad)
        
        // sort location points
        for onePlace in places {
            let latRadian:CGFloat = degreeToRadian(angle: onePlace.coordinate.latitude)
            let lonRadian:CGFloat = degreeToRadian(angle: onePlace.coordinate.longitude)
            let placeX: CGFloat = cos(latRadian) * cos(lonRadian)
            let placeY: CGFloat = cos(latRadian) * sin(lonRadian)
            
            let y = placeY - centerY
            let x = placeX - centerX
            let a = atan2(y, x)
            
            let one = PlaceAtan(p: onePlace, atan: a)
            atanArr.append(one)
        }
        
        atanArr.sort(by: { $0.atan > $1.atan })
        for item in atanArr {
            print(item.place.title ?? "")
            let p = item.place
            result.append(p)
        }
        
        return result
    }
    
    func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> String {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation   = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distance = fromLocation.distance(from: toLocation)
        
        let distanceInKm = distance / 1000
        getShortestLongest(distanceInKm: distanceInKm, from: from, to: to)
        totalKm += distanceInKm
        
        if distance < 1000 {
            return "\(String(format: "%.1f", distance))m"
        } else {
            let distanceInKm = distance  / 1000
            return "\(String(format: "%.2f", distanceInKm))Km"
        }
    }
    
    fileprivate func getShortestLongest(distanceInKm: Double, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        if shortestKm == 0.0 {
            shortestKm = distanceInKm
        }
        
        if distanceInKm < shortestKm {
            shortestKm = distanceInKm
            shortestStart = from
            shortestEnd = to
        }
        
        if distanceInKm > longestKm {
            longestKm = distanceInKm
            longestStart = from
            longestEnd = to
        }
    }
    
    // MARK: - to get the middle point between two coordinates
    func middlePointOfListMarkers(listCoords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
    
        var x = 0.0 as CGFloat
        var y = 0.0 as CGFloat
        var z = 0.0 as CGFloat
    
        for coordinate in listCoords {
            let lat:CGFloat = degreeToRadian(angle: coordinate.latitude)
            let lon:CGFloat = degreeToRadian(angle: coordinate.longitude)
            x = x + cos(lat) * cos(lon)
            y = y + cos(lat) * sin(lon)
            z = z + sin(lat)
        }
    
        x = x/CGFloat(listCoords.count)
        y = y/CGFloat(listCoords.count)
        z = z/CGFloat(listCoords.count)
    
        let resultLon: CGFloat = atan2(y, x)
        let resultHyp: CGFloat = sqrt(x*x+y*y)
        let resultLat:CGFloat = atan2(z, resultHyp)
    
        let newLat = radianToDegree(radian: resultLat)
        let newLon = radianToDegree(radian: resultLon)
        let result:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
    
        return result
    }
    
    func degreeToRadian(angle:CLLocationDegrees) -> CGFloat {
        return (  (CGFloat(angle)) / 180.0 * .pi  )
    }
    
    func radianToDegree(radian:CGFloat) -> CLLocationDegrees {
        return CLLocationDegrees(  radian * CGFloat(180.0 / .pi)  )
    }
    
    
}
