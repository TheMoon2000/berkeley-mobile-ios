//
//  HeatMapVC.swift
//  berkeleyMobileiOS
//
//  Created by Jia Rui Shan on 2018/10/26.
//  Copyright © 2018 org.berkeleyMobile. All rights reserved.
//

import UIKit
import GoogleMaps

class HeatMapVC: UIViewController {
    
    @IBOutlet weak var heatMap: GMSMapView!
    var libraries = [Library]()
    var occupancies = [String : (load: Int, capacity: Int)]() // Percentages
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        heatMap.camera = camera
        heatMap.isMyLocationEnabled = true
        placeMarkers()
    }
    
    func placeMarkers() {
        for lib in libraries {
            let lat = lib.latitude!
            let lon = lib.longitude!
            let marker = GMSMarker()
            marker.opacity = 0.6
            marker.isFlat = true
            let code = libraryCodes[lib.name] ?? ""
            if let libdata = occupancies[code] {
                let occupancy = Double(libdata.load) / Double(libdata.capacity)
                let markerIcon = heatIcon(percentage: occupancy)
                marker.icon = markerIcon
            } else if !lib.isOpen {
                marker.icon = UIImage(named: "heat_marker_gray")
            } else {
                marker.icon = GMSMarker.markerImage(with: bmThemeColor)
            }
            marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            marker.title = lib.name
            marker.map = heatMap
        }
    }
    
    func heatIcon(percentage: Double) -> UIImage {
        if percentage <= 0.5 {
            return UIImage(named: "heat_marker_green")!
        } else if percentage <= 0.75 {
            return UIImage(named: "heat_marker_yellow")!
        } else if percentage <= 0.9 {
            return UIImage(named: "heat_marker_orange")!
        } else {
            return UIImage(named: "heat_marker_red")!
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
