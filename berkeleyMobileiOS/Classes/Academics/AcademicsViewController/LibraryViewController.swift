//
//  LibraryViewController.swift
//  
//
//  Created by Marisa Wong on 3/5/18.
//

import UIKit
import GoogleMaps
import Material
import Firebase
fileprivate let kColorGreen = UIColor(red: 16/255.0, green: 161/255.0, blue: 0, alpha:1)
fileprivate let kColorRed = UIColor.red

let kSensorDataEndpoint = sensorDataSource + "/data.php"

class LibraryViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    var library: Library!
    var locationManager = CLLocationManager()
    var iconImages = [UIImage]()
    var libInfo = [String]()
    var weeklyTimes = [String]()
    var daysOfWeek = [String]()
    var expandRow: Bool!
    var distribution: (Date, [Int])?
    var failureType: CampusResourceDataSource.FailureType?
    
    let popularityDateFormatter = { () -> DateFormatter in
        let d = DateFormatter()
        d.locale = Locale(identifier: "en_US")
        d.dateFormat = "y-MM-dd"
        return d
    }()
    
    let weekFormatter = { () -> DateFormatter in
        let d = DateFormatter()
        d.locale = Locale(identifier: "en_US")
        d.dateFormat = "EEEE"
        return d
    }()
    
    @IBOutlet weak var libTitle: UILabel!
    @IBOutlet weak var libraryImage: UIImageView!
    @IBOutlet weak var libTableView: UITableView!
    @IBOutlet weak var libMap: GMSMapView!
    override func viewDidAppear(_ animated: Bool) {
        Analytics.logEvent("opened_library", parameters: ["name" : library.name])
    }
    override func viewDidLoad() {
//        setUpMap()

        libTitle.bringSubview(toFront: libraryImage)
        
        self.pageTabBarController?.pageTabBar.height = 0
        
        libTitle.text = library.name
        libTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        libTitle.numberOfLines = 0
        
        libTableView.separatorStyle = .none
        
        libraryImage.load(resource: library)
        iconImages.append(#imageLiteral(resourceName: "hours_2.0"))
        iconImages.append(#imageLiteral(resourceName: "phone_2.0"))
        iconImages.append(#imageLiteral(resourceName: "location_2.0"))
        
        libInfo.append(getLibraryStatusHours())
        libInfo.append(getLibraryPhoneNumber())
        libInfo.append(getLibraryLoc())
        
        libTableView.delegate = self
        libTableView.dataSource = self

        expandRow = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        var localOpeningTime = ""
        var localClosingTime = ""
        var timeArr = [String]()
        for i in 0...6 {
            if let t = (self.library?.weeklyOpeningTimes[i]) {
                localOpeningTime = dateFormatter.string(from:t)
            }
            if let t = (self.library?.weeklyClosingTimes[i]) {
                localClosingTime = dateFormatter.string(from:t)
            }
            
            var timeRange:String = localOpeningTime + " : " + localClosingTime
            
            if (localOpeningTime == "" && localClosingTime == "") {
                timeRange = "CLOSED ALL DAY"
            }

            weeklyTimes.append(timeRange)
            
        }
        
        var dateComponent = DateComponents()
        dateComponent.day = 1
        let calendar = Calendar.current
        var currDate = Date()
        for _ in 0...6 {
            let currDateString = calendar.component(.weekday, from: currDate)

            let nextDate = calendar.date(byAdding: .day, value: 1, to: currDate)
            
            switch currDateString {
            case 1:
                daysOfWeek.append("Sunday")
            case 2:
                daysOfWeek.append("Monday")
            case 3:
                daysOfWeek.append("Tuesday")
            case 4:
                daysOfWeek.append("Wednesday")
            case 5:
                daysOfWeek.append("Thursday")
            case 6:
                daysOfWeek.append("Friday")
            case 7:
                daysOfWeek.append("Saturday")
            default:
                daysOfWeek.append("")
            }
        
            currDate = nextDate!
        }
        
        // Added table view cell for the library load distribution
        
        let chartNib = UINib(nibName: "BarChartCell", bundle: Bundle.main)
        libTableView.register(chartNib, forCellReuseIdentifier: "barchart")
        
        // Find the last weekday that matches the current weekday
        
        var dateToLookup = Date()
        let today = weekFormatter.string(from: Date())
        
        while weekFormatter.string(from: dateToLookup) != today {
            dateToLookup.addTimeInterval(-24 * 3600) // Back by one day
        }
        
        let lookupDateName = popularityDateFormatter.string(from: dateToLookup)
        
//        library.name
        if let lookupName = libraryCodes[library.name] {
            self.distribution = nil
            loadDistribution(lookupName, lookupDateName) { (date, list) in
                self.distribution = (date, list)
                self.updateBarChartCell()
            }
        } else {
            self.failureType = CampusResourceDataSource.FailureType.unavailable
            self.updateBarChartCell()
        }
    
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func updateBarChartCell() {
        
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.libTableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .fade)
        }
    }
    
    // Return an array with the load distribution for a given date
    // Date string should have format of YYYY-MM-DD
    func loadDistribution(_ library: String, _ date: String, handler: @escaping (Date, [Int]) -> Void) {
        
        // Update the appearance of the barchart cell
        distribution = nil; failureType = nil
        
        var request = URLRequest(url: URL(string: kSensorDataEndpoint)!)
        request.httpMethod = "POST"
        let post_string = "date=\(date)&library=\(library)"
        request.httpBody = post_string.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print(error!)
                self.failureType = CampusResourceDataSource.FailureType.connectionError
                self.updateBarChartCell()
                return
            } else if let dist = String(data: data!, encoding: .utf8) {
                if dist == "failed to read" {
//                    self.failureType = CampusResourceDataSource.FailureType.unavailable
//                    self.updateBarChartCell()
                    let newDate = self.popularityDateFormatter.date(from: date)!.addingTimeInterval(-7 * 24 * 3600)
                    self.loadDistribution(library,
                                          self.popularityDateFormatter.string(from: newDate), handler: handler)
                } else {
                    let array = dist.components(separatedBy: " ").map {Int($0) ?? 0}
                    handler(self.popularityDateFormatter.date(from: date)!, array)
                    self.failureType = nil
                }
            } else {
                self.failureType = CampusResourceDataSource.FailureType.customMessage("UNEXPECTED: no data was loaded :(")
                return
            }
        }
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func setUpMap() {
//        //Setting up map view
//        libMap.delegate = self
//        libMap.isMyLocationEnabled = true
//        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
//        self.libMap.camera = camera
//        self.libMap.frame = self.view.frame
//        self.libMap.isMyLocationEnabled = true
//        self.libMap.delegate = self
//        self.libMap.isUserInteractionEnabled = false
//        self.locationManager.startUpdatingLocation()
//
//        let kMapStyle =
//            "[" +
//                "{ \"featureType\": \"administrative\", \"elementType\": \"geometry\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
//                "{ \"featureType\": \"poi\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
//                "{ \"featureType\": \"road\", \"elementType\": \"labels.icon\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
//                "{ \"featureType\": \"transit\", \"stylers\": [ {  \"visibility\": \"off\" } ] } " +
//        "]"
//
//        do {
//            // Set the map style by passing a valid JSON string.
//            self.libMap.mapStyle = try GMSMapStyle(jsonString: kMapStyle)
//        } catch {
//            NSLog("The style definition could not be loaded: \(error)")
//        }
//
//        var lat = 37.0
//        var lon = -37.0
//        if let la = library?.latitude {
//            lat = la
//        }
//        if let lo = library?.longitude {
//            lon = lo
//        }
//        let marker = GMSMarker()
//
//        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//        marker.title = library?.name
//
//        let status = library?.isOpen;
//        if status! {
//            marker.icon = #imageLiteral(resourceName: "blueStop")
//            marker.snippet = "Open"
//        } else {
//            marker.icon = #imageLiteral(resourceName: "blueStop")
//            marker.snippet = "Closed"
//
//        }
//        marker.map = self.libMap
//
//    }
    
    func getLibraryStatusHours() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        var trivialDayStringsORDINAL = ["", "SUN","MON","TUE","WED","THU","FRI","SAT"]
        let dow = Calendar.current.component(.weekday, from: Date())
        let translateddow = 0
        var localOpeningTime = ""
        var localClosingTime = ""
        if let t = (self.library?.weeklyOpeningTimes[translateddow]) {
        localOpeningTime = dateFormatter.string(from:t)
        }
        if let t = (self.library?.weeklyClosingTimes[translateddow]) {
        localClosingTime = dateFormatter.string(from:t)
        }
        
        var timeRange:String = localOpeningTime + " to " + localClosingTime
        var status = "Closed"
        
        if (localOpeningTime == "" && localClosingTime == "") {
        timeRange = "Closed Today"
        } else {
            if library.isOpen {
                status = "Open"
            }
        }
        
        var timeInfo = status + "    " + timeRange
        if (timeRange == "Closed Today") {
        timeInfo = timeRange
        }
        return timeInfo
    }
    
    func getLibraryPhoneNumber() -> String {
        return (self.library?.phoneNumber)!
    }
    
    func getLibraryWebsite() -> String {
        //        return library.
        return "marisawong.comlmao"
        
    }
    
    
    func getLibraryLoc() -> String {
        if let loc = library.campusLocation {
            return loc
        } else {
            return "UC Berkeley"
        }
    }
}



extension LibraryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandRow == true && indexPath.row == 0  {
            return 220
        } else if indexPath.row == 3 {
            return 250
        } else if (indexPath.row == 4) {
            return 400
        } else {
            return UITableViewAutomaticDimension
        }
    }

    func setUpMap(_ campResMap: GMSMapView) {
        //Setting up map view
        campResMap.delegate = self
        campResMap.isMyLocationEnabled = true
        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        campResMap.camera = camera
        campResMap.frame = self.view.frame
        campResMap.isMyLocationEnabled = true
        campResMap.isUserInteractionEnabled = false
        campResMap.delegate = self
        self.locationManager.startUpdatingLocation()
        
        let kMapStyle =
            "[" +
                "{ \"featureType\": \"administrative\", \"elementType\": \"geometry\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"poi\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"road\", \"elementType\": \"labels.icon\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"transit\", \"stylers\": [ {  \"visibility\": \"off\" } ] } " +
        "]"
        
        do {
            // Set the map style by passing a valid JSON string.
            campResMap.mapStyle = try GMSMapStyle(jsonString: kMapStyle)
        } catch {
            NSLog("The style definition could not be loaded: \(error)")
            //            print(error)
        }
        
        let lat = library.latitude!
        let lon = library.longitude!
        let marker = GMSMarker()
        marker.icon = #imageLiteral(resourceName: "blueStop")
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        marker.title = library?.name
        marker.map = campResMap
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = libTableView.dequeueReusableCell(withIdentifier: "dropdown", for: indexPath) as! WeeklyTimesTableViewCell
            cell.icon.image = iconImages[indexPath.row]
            if self.library.isOpen {
                cell.day.text = "Open"
                cell.day.textColor = kColorGreen
            } else {
                cell.day.text = "Closed"
                cell.day.textColor = kColorRed
            }
            cell.time.text = weeklyTimes[0]
            cell.days = daysOfWeek
            cell.times = weeklyTimes
            if expandRow == true {
                cell.expandButton.setBackgroundImage(#imageLiteral(resourceName: "collapse"), for: .normal)
            } else {
                cell.expandButton.setBackgroundImage(#imageLiteral(resourceName: "expand"), for: .normal)
            }
            return cell
        case 3:
            let cell = libTableView.dequeueReusableCell(withIdentifier: "barchart") as! BarChartCell
            
            // Loading animation
            if self.distribution == nil && failureType == nil {
                
                // Adjust the content of the view
                cell.loading.isHidden = false
                cell.barChart.isHidden = true
                cell.errorImage.isHidden = true
                cell.errorMessage.isHidden = true
                cell.caption.text = ""
                
                cell.loading.indeterminateDuration = 0.9 // Period
                cell.loading.trackTintColor = UIColor(white: 0.9, alpha: 1)
                cell.loading.progressTintColor = bmThemeColor
                cell.loading.indeterminateProgress = 0.35
                cell.loading.enableIndeterminate()
            } else if let dist = self.distribution {
                
                // Adjust the content of the view
                cell.barChart.isHidden = false
                cell.loading.isHidden = true
                cell.errorImage.isHidden = true
                cell.errorMessage.isHidden = true
                
                cell.barChart.titleFormat = "Predicted occupancy distribution for today:"
                cell.barChart.frameStyle = .bottom(1)
                cell.barChart.backgroundColor = UIColor.white
                cell.barChart.chartTheme = bmThemeColor
                cell.barChart.maxCapacity = 300 // Temporary solution
                cell.barChart.data = dist.1
                cell.barChart.gradient = true
                let dayOfWeek = weekFormatter.string(from: dist.0)
                cell.caption.text = "We've fetched the data for the most recent \(dayOfWeek)."
            } else {
                
                // Adjust the content of the view
                cell.errorImage.isHidden = false
                cell.errorMessage.isHidden = false
                cell.barChart.isHidden = true
                cell.loading.isHidden = true
                cell.caption.text = ""
                
                switch failureType! {
                case .connectionError:
                    cell.errorImage.image = UIImage(named: "connection-error")
                    cell.errorMessage.text = "Sorry, we couldn't connect to our server. Tap to retry!"
                case .unavailable:
                    cell.errorImage.image = UIImage(named: "unavailable")
                    cell.errorMessage.text = "Sorry, sensor data is not yet available for this building!"
                case .customMessage(let message):
                    cell.errorImage.image = UIImage(named: "connection-error")
                    cell.errorMessage.text = message
                }
            }
            
            return cell
        case 4:
            let campResInfoCell = tableView.dequeueReusableCell(withIdentifier: "librarymapTable", for: indexPath) as! LibraryMapTableViewCell
            setUpMap(campResInfoCell.mapView)
            return campResInfoCell
        default:
            let libraryInfoCell = libTableView.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath) as! LibraryDetailCell
            
            libraryInfoCell.libraryIconImage.image = iconImages[indexPath.row]
            libraryInfoCell.libraryIconInfo.text = libInfo[indexPath.row]
            libraryInfoCell.libraryIconInfo.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
            return libraryInfoCell
        }
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let cell = tableView.cellForRow(at: indexPath) as! WeeklyTimesTableViewCell
            expandRow = !expandRow
            tableView.reloadData()
        case 3:
            if failureType != nil {
                tableView.deselectRow(at: indexPath, animated: true)
                loadDistribution(libraryCodes[library.name]!, popularityDateFormatter.string(from: Date())) { (date, list) in
                    self.distribution = (date, list)
                    self.updateBarChartCell()
                }
            } else if distribution != nil {
                self.performSegue(withIdentifier: "historical load", sender: self)
            }
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? HistoricalLoad {
            vc.library = self.library
            vc.mostRecentDate = self.distribution?.0
        }
    }
    
}
