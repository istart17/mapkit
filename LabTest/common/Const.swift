//
//  Const.swift
//  LabTest
//

import UIKit
import MapKit

class Const {
    
    static let shared = Const()
    
    func getCityData() -> [Place] {
        var places:[Place] = []
        
        places.append(Place(title: "Toronto", subtitle: "city", coordinate: CLLocationCoordinate2D(latitude: 43.737507, longitude: -79.324506)))
        places.append(Place(title: "Ottawa", subtitle: "city", coordinate: CLLocationCoordinate2D(latitude: 45.305803, longitude: -75.636260)))
        places.append(Place(title: "Sudbury", subtitle: "city", coordinate: CLLocationCoordinate2D(latitude: 46.488165, longitude: -80.991903))) 
        
        return places
    }
}
