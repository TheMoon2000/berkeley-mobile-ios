//
//  HistoricalLoad.swift
//  berkeleyMobileiOS
//
//  Created by Jia Rui Shan on 2018/10/25.
//  Copyright © 2018 org.berkeleyMobile. All rights reserved.
//

import UIKit

let bmThemeColor = UIColor(red: 0.29, green: 0.4, blue: 0.65, alpha: 1)

class HistoricalLoad: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var loadTable: UITableView!
    @IBOutlet weak var loading: RPCircularProgress!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    var library: Library!
    var mostRecentDate: Date!
    var capacity = 200
    var distribution: [(date: Date, load: [Int])]?
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "BarChartCell", bundle: Bundle.main)
        loadTable.register(nib, forCellReuseIdentifier: "barchart")
        loadTable.contentInset.top += 10
        
        // Setup the fancy animation while libraries are loading
        loading.indeterminateDuration = 0.9
        loading.trackTintColor = UIColor(white: 0.9, alpha: 1)
        loading.progressTintColor = bmThemeColor
        loading.indeterminateProgress = 0.35
        loading.thicknessRatio = 0.1
        loading.roundedCorners = true
        loading.enableIndeterminate()
        
        if let codedName = libraryCodes[library.name] {
            loadDistributions(codedName,
                          fromDate: popularityDateFormatter.string(from: mostRecentDate.addingTimeInterval(-6 * 24 * 3600)),
                          toDate: popularityDateFormatter.string(from: mostRecentDate))
        }
        
    }
    
    func loadDistributions(_ library: String, fromDate: String, toDate: String) {
        
        // Begin
        loading.enableIndeterminate()
        loading.isHidden = false
        errorImage.isHidden = true
        errorMessage.isHidden = true
        loadTable.isHidden = true
        distribution = nil
        
        var request = URLRequest(url: URL(string: kSensorDataEndpoint)!)
        request.httpMethod = "POST"
        let post_string = "date=\(fromDate)&to=\(toDate)&library=\(library)"
        request.httpBody = post_string.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                // Stop
                self.loading.isHidden = true
            }
            if error != nil {
                DispatchQueue.main.async {
                    self.errorImage.isHidden = false
                    self.errorMessage.isHidden = false
                }
                return
            } else if let dist = String(data: data!, encoding: .utf8) {
                if dist == "failed to read" {
                    // Error handling
                } else {
                    self.capacity = Int(dist.components(separatedBy: ")")[0])!
                    let combined = dist.components(separatedBy: ")")[1].components(separatedBy: " | ")
                    let dist = combined.map({ (raw) -> (Date, [Int]) in
                        let parts = raw.components(separatedBy: ": ")
                        return (
                            self.popularityDateFormatter.date(from: parts[0])!,
                            parts[1].components(separatedBy: " ").map {Int($0) ?? 0}
                        )
                    })
                    DispatchQueue.main.async {
                        self.loadTable.isHidden = false
                        self.distribution = dist.reversed()
                        self.loadTable.reloadData()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage.text = "Unexpected error!"
                    self.errorMessage.isHidden = false
                    self.errorImage.isHidden = false
                }
                return
            }
        }
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.distribution == nil ? 0 : 7
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 260
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        let dateString = popularityDateFormatter.string(from: distribution![indexPath.row].0)
        let weekday = weekFormatter.string(from: self.distribution![row].0)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "barchart") as! BarChartCell
        cell.barChart.dateString = dateString
        cell.barChart.gradient = false
        switch row {
        case 0:
            cell.barChart.titleFormat = "Predicted occupancy distribution for today:"
            cell.barChart.gradient = true
        case 1:
            cell.barChart.titleFormat = "Occupancy distribution for yesterday:"
        default:
            cell.barChart.titleFormat = "Occupancy for last \(weekday), \(dateString):"
        }
        
        // Adjust the content of the view
        cell.barChart.isHidden = false
        cell.loading.isHidden = true
        cell.errorImage.isHidden = true
        cell.errorMessage.isHidden = true
        
        cell.barChart.frameStyle = .bottom(1)
        cell.barChart.backgroundColor = UIColor.white
        cell.barChart.chartTheme = UIColor(red: 0.29, green: 0.4, blue: 0.65, alpha: 1)
        cell.barChart.maxCapacity = CGFloat(capacity)
        cell.barChart.data = self.distribution![row].load
        let maxOccupancy = distribution![row].load.max() ?? 0
        let average = distribution![row].load.reduce(0, { x, y in
            x + y
        }) / distribution![row].load.count
        
        cell.caption.text = "Maximum occupancy = \(maxOccupancy); average = \(average)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row) // Yet to implement
        tableView.deselectRow(at: indexPath, animated: true)
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
