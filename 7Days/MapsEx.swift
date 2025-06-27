//
//  MapsEx.swift
//  7Days
//
//  Created by Roderick Presswood on 6/27/25.
//

import UIKit
import SwiftUI
import MapKit
import CoreLocation


class GPSMapViewController: UIViewController, CLLocationManagerDelegate {
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        mapView.frame = view.bounds
        
        // Request location permission
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Show user location on the map
        mapView.showsUserLocation = true
    }
    
    // Delegate method: Location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        // Center the map on the user's location
        let region = MKCoordinateRegion(center: userLocation.coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
}


struct MapView: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.774929, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow))
            .ignoresSafeArea()
    }
}


//struct mapView_Previews: PreviewProvider {
//    static var previews: some View {
//        mapView()
//    }
//}
#Preview { MapView() }
