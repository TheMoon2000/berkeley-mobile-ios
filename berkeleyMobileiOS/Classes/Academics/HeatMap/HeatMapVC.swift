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
    var filters = [LibraryAttributes]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        heatMap.camera = camera
        heatMap.isMyLocationEnabled = true
        placeMarkers()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filters"), style: .plain, target: self, action: #selector(openFilters))
        
        filters.append(contentsOf: [
            LibraryAttributes.food(""),
            LibraryAttributes.noise(""),
            LibraryAttributes.nap(""),
            LibraryAttributes.room(""),
        ])
        ["laptops", "projectors", "printers", "photocopiers"].forEach {
            filters.append(.utility($0))
        }
    }
    
    func placeMarkers() {
        for lib in libraries {
            let lat = lib.latitude!
            let lon = lib.longitude!
            let marker = GMSMarker()
            let code = libraryCodes[lib.name] ?? ""
            
            // Method borrowed from original source file
            
            let hours = AcademicViewController.getLibraryHours(library: lib)
            var splitStr = hours.components(separatedBy: " to ")
            
            if !lib.isOpen && (splitStr.count == 2 && splitStr[0] != splitStr[1]) {
                marker.icon = UIImage(named: "heat_marker_gray")
                print(hours)
            } else if let libdata = occupancies[code] {
                let occupancy = Double(libdata.load) / Double(libdata.capacity)
                let markerIcon = heatIcon(percentage: occupancy)
                marker.icon = markerIcon
            } else {
                marker.icon = UIImage(named: "heat_marker_blue")
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
    
    @objc func openFilters() {
        self.performSegue(withIdentifier: "showFilters", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFilters" {
            let vc = segue.destination as! HeatMapFiltersVC
            vc.filters = self.filters
            vc.parentVC = self
        }
    }

}
