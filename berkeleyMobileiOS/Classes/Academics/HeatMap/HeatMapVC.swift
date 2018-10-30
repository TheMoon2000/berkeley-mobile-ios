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
    var enableFilters = false {
        didSet {
            if let fmv = filterMessageView, let fm = filterMessage {
                fmv.isHidden = !enableFilters
            }
        }
    }
    
    @IBOutlet weak var filterMessageView: UIVisualEffectView!
    @IBOutlet weak var filterMessage: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        if self.pageTabBarController?.pageTabBar.height == 60 {
            self.pageTabBarController?.pageTabBar.height = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.view.frame.size.height += 60
                
//                self.view.layoutSubviews()
            }
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        heatMap.camera = camera
        heatMap.isMyLocationEnabled = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filters"), style: .plain, target: self, action: #selector(openFilters))
        
        filters.append(contentsOf: [
            LibraryAttributes.food(""),
            LibraryAttributes.noise(""),
            LibraryAttributes.nap(""),
            LibraryAttributes.room(""),
        ])
        HeatMapFiltersVC.utilities.forEach {
            filters.append(.utility($0.lowercased()))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.pageTabBarController!.pageTabBar.height == 60 {
            self.pageTabBarController?.pageTabBar.height = 0
        }
        placeMarkers()
    }
    
    var filteredLibraries: [Library] {

        let filter_as_string = filters.map {$0.description}
        
        return libraries.filter { (lib) -> Bool in
            for attr in lib.attributes {
                let type = attr.description
                if !type.hasPrefix("utility") {
                    if filter_as_string.contains(type) {return true}
                } else {
                    if filter_as_string.contains(type) {return true}
                }
            }
            return false
        }
    }
    
    func placeMarkers() {
        
        heatMap.clear()
        if enableFilters {
            filterMessage.text = "\(filteredLibraries.count) of \(libraries.count) libraries displayed."
        }
        
        for lib in (enableFilters ? filteredLibraries : libraries) {
            let lat = lib.latitude!
            let lon = lib.longitude!
            let marker = GMSMarker()
            let code = libraryCodes[lib.name] ?? ""
            
            // Method borrowed from original source file
            
            let hours = AcademicViewController.getLibraryHours(library: lib)
            
            if !AcademicViewController.libraryIsOpen(timeInterval: hours) {
                marker.icon = UIImage(named: "heat_marker_gray")
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
            vc.enableFilters = self.enableFilters
        }
    }

}
