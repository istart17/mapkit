//
//  ViewController.swift
//  LabTest
//

import UIKit
import MapKit
import CoreLocation

var totalKm = 0.0

var shortestKm = 0.0
var longestKm = 0.0
var shortestStart:CLLocationCoordinate2D    = CLLocationCoordinate2D()
var shortestEnd:CLLocationCoordinate2D      = CLLocationCoordinate2D()
var longestStart:CLLocationCoordinate2D     = CLLocationCoordinate2D()
var longestEnd:CLLocationCoordinate2D       = CLLocationCoordinate2D()


protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    var option = 2
    let optionLimits = [4, 6, 8]
    
    @IBOutlet weak var mapView: MKMapView!
    
    private var currentRoute: MKRoute?
    private let locationManager = CLLocationManager()
    let regionInMeters: Double = 2000
    
    var placesData:[Place] = []
    
    var selectedPin: MKPlacemark?
    var resultSearchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locationSearchTable = storyboard!.instantiateViewController(identifier: "LocationSearchTVC") as! LocationSearchTVC
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        
        resultSearchController!.searchBar.placeholder = "Search for places"
        navigationItem.searchController = resultSearchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        mapView.delegate = self
        locationManager.delegate = self
        checkLocationAuthorization()
        
        placesData = []
        
        title = "Cities: \(optionLimits[option])"
    }
    
    fileprivate func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            setupLocationManager()
            break
        case .authorizedAlways:
            setupLocationManager()
            break
        case .denied, .notDetermined, .restricted:
            locationManager.requestWhenInUseAuthorization()
            break
        default:
            break
        }
    }
    
    fileprivate func setupLocationManager(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        setupLongTapGestureOnMap()
    }
    
    // MARK: - Part 2
    fileprivate func setupLongTapGestureOnMap() {
        mapView.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(longTapGesture)
    }
    
    @objc func mapTapped(sender: UIGestureRecognizer) {
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let coordinateOfLocation = mapView.convert(locationInView, toCoordinateFrom: mapView)
            
            var cityName = ""
            Utils.shared.getAddressFromCoordinate(coordinate: coordinateOfLocation) { (address) in
                cityName = address
                let newPlace = Place(title: cityName, subtitle: "city", coordinate: coordinateOfLocation)
                self.placesData.append(newPlace)
                
                if self.placesData.count < self.optionLimits[self.option] {
                    self.setPlaces()
                    if self.placesData.count > 1 {
                        self.setPolylines()
                    }
                } else if self.placesData.count == self.optionLimits[self.option] {
                    self.displayCities()
                } else {
                    let tmp = self.placesData.prefix(self.optionLimits[self.option])
                    self.placesData = Array(tmp)
                    self.displayCities()
                }
            }
        }
    }
    
    // MARK: - display polyline and polygon
    func displayCities() {
        setPolylines()
        setPlaces()
        setDistance()
        setTotalDistance()
        setPolygon()
        
        setLongest()
        setShortest()
    }
    
    fileprivate func setPlaces() {
        removeAnnotation()
        mapView.addAnnotations(placesData)
    }
    
    fileprivate func setPolylines() {
        removeOverlay()
        if placesData.count == optionLimits[option] {
            placesData = Utils.shared.sortPlacesClockwise(places: placesData)
        }
        
        var locations = placesData.map { $0.coordinate }
        if placesData.count == optionLimits[option] {
            locations.append(placesData[0].coordinate)
        }
        let polyline = MKPolyline(coordinates: &locations, count: locations.count)
        
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
    
    fileprivate func setPolygon() {
        var locations = placesData.map { $0.coordinate }
        let polygon = MKPolygon(coordinates: &locations, count: locations.count)
        mapView.addOverlay(polygon)
        mapView.setVisibleMapRect(polygon.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
    
    fileprivate func setDistance() {
        switch placesData.count {
        case 1:
            break
        case 2:
            let kmMark = MKPointAnnotation()
            kmMark.title = Utils.shared.getDistance(from: placesData[0].coordinate, to: placesData[1].coordinate)
            kmMark.subtitle = ""
            kmMark.coordinate = Utils.shared.middlePointOfListMarkers(listCoords: [placesData[0].coordinate, placesData[1].coordinate])
            mapView.addAnnotation(kmMark)
        default: // 3 or more
            var tmp = placesData
            tmp.append(placesData[0])
            
            for index in 0 ..< tmp.count-1 {
                let kmMark = MKPointAnnotation()
                kmMark.title = Utils.shared.getDistance(from: tmp[index].coordinate, to: tmp[index+1].coordinate)
                kmMark.subtitle = ""
                kmMark.coordinate = Utils.shared.middlePointOfListMarkers(listCoords: [tmp[index].coordinate, tmp[index+1].coordinate])
                mapView.addAnnotation(kmMark)
            }
        }
    }
    
    fileprivate func setTotalDistance() {
        let kmMark = MKPointAnnotation()
        kmMark.title = "\(String(format: "%.1f", totalKm))Km"
        kmMark.subtitle = ""
        let locations = placesData.map { $0.coordinate }
        kmMark.coordinate = Utils.shared.middlePointOfListMarkers(listCoords: locations)
        mapView.addAnnotation(kmMark)
    }
    
    fileprivate func setShortest() {
        /*
        var short:[Place] = []
        short.append(Place(title: "ShortStart", subtitle: "city", coordinate: shortestStart))
        short.append(Place(title: "ShortEnd", subtitle: "city", coordinate: shortestEnd))
        
        var locations = short.map { $0.coordinate }
        
        let line = CustomePolyline(coordinates: &locations, count: locations.count)
        line.color = .red
        mapView.addOverlay(line)
        */
        let kmMark = MKPointAnnotation()
        kmMark.title = "Shortest:\(String(format: "%.1f", shortestKm))Km"
        kmMark.subtitle = ""
        kmMark.coordinate = Utils.shared.middlePointOfListMarkers(listCoords: [shortestStart, shortestEnd])
        mapView.addAnnotation(kmMark)
    }
    
    fileprivate func setLongest() {
        /*
        var longest:[Place] = []
        longest.append(Place(title: "LongStart", subtitle: "city", coordinate: longestStart))
        longest.append(Place(title: "LongEnd", subtitle: "city", coordinate: longestEnd))
        
        var locations = longest.map { $0.coordinate }
        let line = CustomePolyline(coordinates: &locations, count: locations.count)
        line.color = .green
        mapView.addOverlay(line)
        */
        let kmMark = MKPointAnnotation()
        kmMark.title = "Longest:\(String(format: "%.1f", longestKm))Km"
        kmMark.subtitle = ""
        kmMark.coordinate = Utils.shared.middlePointOfListMarkers(listCoords: [longestStart, longestEnd])
        mapView.addAnnotation(kmMark)
    }
    
    func removeOverlay(){
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    func removeAnnotation(){
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove )
    }
}

// MARK: - MapKit Delegate
extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? CustomePolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: polyline)
            polylineRenderer.strokeColor = polyline.color
            polylineRenderer.lineWidth = 3
            return polylineRenderer
        }
        
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        } else {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            if self.option == 0 {
                renderer.fillColor = UIColor.green.withAlphaComponent(0.3)
            } else {
                renderer.fillColor = UIColor.green.withAlphaComponent(0.4)
            }
            return renderer
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let annotationIdentifier = "MyCustomAnnotation"

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) ?? CustomAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        
        if case let annotationView as CustomAnnotationView = annotationView {
            annotationView.isEnabled = true
            annotationView.canShowCallout = false
            annotationView.annotation = annotation
            annotationView.label = UILabel(frame: CGRect(x: -5.5, y: 8.0, width: 100.0, height: 30.0))
            
            if let title = annotation.title, let label = annotationView.label {
                label.text = title
                label.textAlignment = .center
                label.textColor = .white
                label.backgroundColor = .black
                label.adjustsFontSizeToFitWidth = true
                annotationView.addSubview(label)
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        for index in 0 ..< placesData.count-1 {
            if placesData[index].title == view.annotation?.title {
                placesData.remove(at: index)
                mapView.removeAnnotation(view.annotation!)
            }
        }
        
        displayCities()
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
    }
}

// MARK: - Location Manager Delegate
extension MapVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

class CustomAnnotationView: MKAnnotationView {
    var label: UILabel?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
      super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }
}

extension MapVC: HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark){
        
        let newPlace = Place(title: "\(placemark.locality ?? "Place \(placesData.count+1)")", subtitle: "city", coordinate: placemark.coordinate)
        placesData.append(newPlace)
        
        if placesData.count < optionLimits[option] {
            setPlaces()
            if self.placesData.count > 1 {
                setPolylines()
            }
        } else if placesData.count == optionLimits[option] {
            displayCities()
        } else {
            let tmp = placesData.prefix(optionLimits[option])
            placesData = Array(tmp)
            displayCities()
        }
    }
}

class CustomePolyline: MKPolyline {
    var color: UIColor?
}
