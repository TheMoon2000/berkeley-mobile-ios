//
//  AcademicViewController.swift
//  berkeleyMobileiOS
//
//  Created by Marisa Wong on 3/1/18.
//  Copyright © 2018 org.berkeleyMobile. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

fileprivate let kColorRed = UIColor.red
fileprivate let kColorGray = UIColor(white: 189/255.0, alpha: 1)
fileprivate let kColorNavy = UIColor(red: 0, green: 51/255.0, blue: 102/255.0, alpha: 1)
fileprivate let kColorGreen = UIColor(red: 16/255.0, green: 161/255.0, blue: 0, alpha:1)

class AcademicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var banner: UIImageView!

    @IBOutlet weak var libButton: UIButton!
    @IBOutlet weak var resourceButton: UIButton!
    
    @IBAction func libModeSelected(_ sender: Any) {
        isLibrary=true
        libButton.titleLabel?.textColor = UIColor(hex: "005581")
        libButton.alpha = 1.0
        resourceButton.titleLabel?.textColor = UIColor(hex: "005581")
        resourceButton.alpha = 0.5
        resourceTableView.reloadData()
    }
    
    @IBAction func resourceModeSelected(_ sender: Any) {
        isLibrary = false
        libButton.titleLabel?.textColor = UIColor(hex: "005581")
        libButton.alpha = 0.5
        resourceButton.titleLabel?.textColor = UIColor(hex: "005581")
        resourceButton.alpha = 1.0
        resourceTableView.reloadData()
        Analytics.logEvent("opened_resource_screen", parameters: nil)
    }

    @IBAction func unwindToAcademic(segue: UIStoryboardSegue) {
    }
    
    @IBAction func libraryUnwind(segue: UIStoryboardSegue) {
    }
    
    
    @IBOutlet weak var resourceTableView: UITableView!
    var already_loaded = false

    var isLibrary = true
    
    var libraries = [Library]()

    var campusResources = [CampusResource]()
    var favLib = [Library]()
    var nonFavLib = [Library]()
    
    let spinner = RPCircularProgress() // Loading animation
    var occupancies = [String : (load: Int, capacity: Int)]() // Percentages
    
    private let refreshControl = UIRefreshControl()
    
    let popularityDateFormatter = { () -> DateFormatter in
        let d = DateFormatter()
        d.locale = Locale(identifier: "en_US")
        d.dateFormat = "y-MM-dd"
        return d
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func refreshLibraries() {
        Library.dataSource?.fetchResources
            { list in
                
                guard let nonEmptyList = list else
                {
                    // Error
                    return print("no didnt work")
                }
                
                self.libraries = (nonEmptyList as! [Library]).sorted(by: {$0.0.name < $0.1.name}) // Libraries should be sorted in alphabetical order
                if let t = self.resourceTableView {
                    if self.occupancies.count > 0 {
                        self.spinner.isHidden = true
                        t.reloadData()
                    }
                }
        }
        
        CampusResource.dataSource?.fetchResources
            { list in
                
                guard let nonEmptyList = list else
                {
                    // Error
                    return print("no didnt work")
                }
                
                self.campusResources = nonEmptyList as! [CampusResource]
                if let t = self.resourceTableView {
                    if self.occupancies.count > 0 {
                        self.spinner.isHidden = true
                        t.reloadData()
                    }
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshLibraries()
        
        // Check to see if user setting for favoriting exists
        let defaults = UserDefaults.standard
        if (UserDefaults.standard.object(forKey: "favoritedLibraries") == nil) {
            // No favoriting enabled (first time opening libraries) - no favorites
            defaults.set(favLib, forKey:"favoritedLibraries")
        } else {
            favLib = defaults.object(forKey: "favoritedLibraries") as! [Library]
            for lib in self.libraries {
                for favL in favLib {
                    if (lib.name != favL.name) {
                        nonFavLib.append(lib)
                    }
                }
            }
        }
        
        self.libraries = favLib + nonFavLib

        
        // Setup the fancy animation while libraries are loading
        spinner.indeterminateDuration = 0.9
        spinner.trackTintColor = UIColor(white: 0.9, alpha: 1)
        spinner.progressTintColor = bmThemeColor
        spinner.indeterminateProgress = 0.35
        spinner.thicknessRatio = 0.1
        spinner.roundedCorners = true
        spinner.enableIndeterminate()
        
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        // Let's apply a few constraints!
        
        NSLayoutConstraint.activate([
            spinner.heightAnchor.constraint(equalToConstant: 55),
            spinner.widthAnchor.constraint(equalToConstant: 55),
            spinner.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: self.resourceTableView.centerYAnchor)
        ])
        
        // Setup refresh control
        resourceTableView.refreshControl = refreshControl
        print(refreshControl.frame.origin.y)
        refreshControl.addTarget(self, action: #selector(refreshOccupancyData(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSMutableAttributedString(string: "Fetching Library Data...", attributes: [NSForegroundColorAttributeName: bmThemeColor])
        refreshControl.isEnabled = false
        refreshOccupancyData(self)
    }
    
    @objc func refreshOccupancyData(_ sender: Any) {
        
        self.occupancies.removeAll()
        
        refreshLibraries()
        
        let hourFormatter = DateFormatter()
        hourFormatter.locale = Locale(identifier: "en_US")
        hourFormatter.dateFormat = "H" // 24-hour format
        let currentHour = hourFormatter.string(from: Date())
        
        var request = URLRequest(url: URL(string: kSensorDataEndpoint)!)
        request.httpMethod = "POST"
        let post_string = "date=\(popularityDateFormatter.string(from: Date()))&hour=\(currentHour)"
        request.httpBody = post_string.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil || data == nil {
                print(error!)
                return
            }
            let json = JSON(data: data!)
            if let libs = json.dictionary {
                self.occupancies = libs.mapValues({ (j) -> (Int, Int) in
                    (j.array![0].int!, j.array![1].int!)
                })
            } else {
            }
            DispatchQueue.main.async {
                self.spinner.isHidden = true
                self.refreshControl.isEnabled = true
                self.refreshControl.endRefreshing()
                self.resourceTableView.reloadData()
            }
        }
        task.resume()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        self.pageTabBarController?.pageTabBar.height = 60
        
        let nib = UINib(nibName: "HeatMapCell", bundle: Bundle.main)
        resourceTableView.register(nib, forCellReuseIdentifier: "heat map")
        
        libButton.titleLabel?.textColor = UIColor(hex: "005581")
        resourceButton.titleLabel?.textColor = UIColor(hex: "005581")
        if isLibrary {
            resourceButton.alpha = 0.5
        } else {
            libButton.alpha = 0.5
        }
        if libraries.count == 0 {
            self.resourceTableView.isHidden = true
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        resourceTableView.reloadData()
        //banner.backgroundColor = UIColor(hex: "1A5679")
//        banner.backgroundColor = UIColor(red: 0, green: 51/255.0, blue: 102/255.0, alpha: 1)
        Analytics.logEvent("opened_library_screen", parameters: nil)
    }
    
    //Plots the location of libraries on map view
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Table View Methods
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row - 1

        if (isLibrary == true) {
            
            if indexPath.row == 0 {
                let cell = resourceTableView.dequeueReusableCell(withIdentifier: "heat map") as! HeatMapCell
                return cell
            }
            
            let cell = resourceTableView.dequeueReusableCell(withIdentifier: "resource") as! ResourceTableViewCell
            // Populate cells with library information
            let library = libraries[row]
            cell.resourceName.text = library.name
            cell.resourceImage.load(resource: library)
            
            // Load information
            if !occupancies.isEmpty, let code = libraryCodes[library.name] {
                cell.resourceLoad.load = occupancies[code]?.load ?? 1
                cell.resourceLoad.isHidden = false
                cell.resourceLoad.capacity = occupancies[code]?.capacity ?? 300
            } else {
                cell.resourceLoad.isHidden = true
                cell.resourceLoad.capacity = 500
            }
            
            /*
            var status = "OPEN"
            if library.isOpen == false {
                status = "CLOSED"
            }
            cell.resourceStatus.text = status
 */

//            if (status == "OPEN") {
//                cell.resourceStatus.textColor = UIColor(hex: "18A408")
//            } else {
//                cell.resourceStatus.textColor = UIColor(hex: "FF2828")
//            }
            
            let hours = AcademicViewController.getLibraryHours(library: library)
            cell.resourceHours.text = hours
            cell.resourceHours.textColor = UIColor(hex: "585858")
            
            if AcademicViewController.libraryIsOpen(timeInterval: hours) {
                cell.resourceStatus.textColor = UIColor(hex: "18A408")
                cell.resourceStatus.text = "OPEN"
            } else {
                cell.resourceStatus.textColor = UIColor(hex: "FF2828")
                cell.resourceStatus.text = "CLOSED"
            }
            
            return cell
        } else {
            let cell = resourceTableView.dequeueReusableCell(withIdentifier: "campus_resource") as! CampusResourceTableViewCell

            // Populate cells with campus resource information
            let resource = campusResources[indexPath.row]
            cell.main_image.load(resource: resource)
            cell.resource_name.text = resource.name
            cell.category_name.text = resource.category
            
//            cell.resourceHours.text = resource.hours
            return cell
        }
    }
    
    func heightForLabel(title: String) -> CGFloat {
        let sampleCell = resourceTableView.dequeueReusableCell(withIdentifier: "resource") as! ResourceTableViewCell
        sampleCell.resourceName.text = title
        sampleCell.resourceName.sizeToFit()
//        print(sampleCell.frame, title, sampleCell.resourceName.frame)
        return sampleCell.resourceName.frame.height
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (isLibrary == true) {
            
            if indexPath.row == 0 {return 50} // Heat map
            
            let currentLibrary = libraries[indexPath.row - 1].name
            let barHeight: CGFloat = libraryCodes.keys.contains(currentLibrary) && !occupancies.isEmpty ? 13 : 0
            return 62 + barHeight + heightForLabel(title: currentLibrary)
        } else {
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isLibrary == true) {
            tableView.isHidden = libraries.count == 0
            return libraries.count > 0 ? libraries.count + 1 : 0
        } else {
            return campusResources.count
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (isLibrary == true) {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "toHeatMap", sender: self)
                self.resourceTableView.deselectRow(at: indexPath, animated: true)
            } else {
                self.performSegue(withIdentifier: "toLibraryDetail", sender: indexPath.row - 1)
                self.resourceTableView.deselectRow(at: indexPath, animated: true)
            }
        } else {
            self.performSegue(withIdentifier: "toCampusResourceDetail", sender: indexPath.row)
            self.resourceTableView.deselectRow(at: indexPath, animated: true)
        }

    }
    
    static func libraryIsOpen(timeInterval: String) -> Bool {
        var splitStr = timeInterval.components(separatedBy: " to ")
        
        if splitStr.count == 2 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "h:mm a"
            
            let openingTime = formatter.date(from: splitStr[0])!
            let closingTime = formatter.date(from: splitStr[1])!
            let dateTime = formatter.date(from: formatter.string(from: Date()))!
            
            if dateTime.timeIntervalSince(openingTime) > 0 && dateTime.timeIntervalSince(closingTime) < 0 || splitStr.count == 2 && splitStr[0] == splitStr[1] {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    /*
    func getLibraryStatus(library: Library) -> String {
        
        //Determining Status of library
        let todayDate = NSDate()
        
        if (library.weeklyClosingTimes[0] == nil) {
            return "Closed"
        }
        
        var status = "OPEN"
        if (library.weeklyClosingTimes[0]!.compare(todayDate as Date) == .orderedAscending) {
            status = "Closed"
        }
        
        return status
    }*/
    
    public static func getLibraryHours(library: Library) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        let dow = Calendar.current.component(.weekday, from: Date())
        let translateddow = 0
        var localOpeningTime = ""
        var localClosingTime = ""
        if let t = (library.weeklyOpeningTimes[translateddow]) {
            localOpeningTime = dateFormatter.string(from:t)
        }
        if let t = (library.weeklyClosingTimes[translateddow]) {
            localClosingTime = dateFormatter.string(from:t)
        }
        
        var timeRange:String = localOpeningTime + " to " + localClosingTime
        
        
        if (localOpeningTime == "" && localClosingTime == "") {
            timeRange = "Closed Today"
        }
        return timeRange
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                
        if (segue.identifier == "toLibraryDetail") {
            let selectedIndex = sender as! Int
            let selectedLibrary = self.libraries[selectedIndex]

            let libraryDetailVC = segue.destination as! LibraryViewController

            libraryDetailVC.library = selectedLibrary
            
            if let code = libraryCodes[selectedLibrary.name] {
                libraryDetailVC.capacity = occupancies[code]?.capacity ?? 0
            }

        }
        if (segue.identifier == "toCampusResourceDetail") {
            let selectedIndex = sender as! Int
            let selectedCampRes = self.campusResources[selectedIndex]

            let campusResourceDetailVC = segue.destination as! CampusResourceViewController
            
            campusResourceDetailVC.campusResource = selectedCampRes
        }
        if (segue.identifier == "toHeatMap") {
            let vc = segue.destination as! HeatMapVC
            vc.libraries = self.libraries.filter({!buildingExceptionList.contains($0.name)})
            vc.occupancies = self.occupancies
        }

    }
}
