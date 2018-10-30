//
//  HeatMapFiltersVC.swift
//  berkeleyMobileiOS
//
//  Created by Jia Rui Shan on 2018/10/27.
//  Copyright © 2018 org.berkeleyMobile. All rights reserved.
//

import UIKit

class HeatMapFiltersVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var filterTable: UITableView!
    
    var filters = [LibraryAttributes]() {
        didSet {
            parentVC?.filters = filters
        }
    }
    var parentVC: HeatMapVC?
    
    var enableFilters = false {
        didSet {
            parentVC?.enableFilters = enableFilters
            if let t = filterTable {
                t.reloadData()
            }
        }
    }
    
    private let labels = ["Food", "Nap", "Noise", "Room", "Utilities"]
    static let utilities = ["Laptops", "Desktops", "Projectors", "Printers", "Photocopiers"]

    override func viewDidLoad() {
        super.viewDidLoad()

        filterTable.allowsSelection = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section >= 1 && section <= 4 {
            return 1
        } else {
            return HeatMapFiltersVC.utilities.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Enable / disable filters:"
        case 1:
            return "Whether food is allowed at some places inside the library building:"
        case 2:
            return "Whether there are places to nap:"
        case 3:
            return "Whether there is a noise floor / place for discussions & group work:"
        case 4:
            return "Whether rooms can be reserved:"
        case 5:
            return "The various utilities that the library offers:"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let filters_as_string = filters.map {$0.description}
        
        let accessorySwitch = UISwitch()
        if indexPath.section == 0 {
            cell.textLabel?.text = "Enable Filters"
            accessorySwitch.isOn = self.enableFilters
            accessorySwitch.addTarget(self, action: #selector(toggleFilter(_:)), for: .valueChanged)
        } else if indexPath.section >= 1 && indexPath.section <= 4 {
            let filterName = labels[indexPath.section - 1]
            cell.textLabel?.text = filterName
            accessorySwitch.isOn = filters_as_string.contains(filterName.lowercased())
            accessorySwitch.isEnabled = enableFilters
        } else {
            let filterName = HeatMapFiltersVC.utilities[indexPath.row]
            cell.textLabel?.text = filterName
            accessorySwitch.isOn = filters_as_string.contains {
                $0.contains(filterName.lowercased())
            }
            accessorySwitch.isEnabled = enableFilters
        }
        accessorySwitch.accessibilityIdentifier = cell.textLabel?.text
        accessorySwitch.addTarget(self,
                                  action: #selector(updateFilter(_:)),
                                  for: .valueChanged)
        cell.accessoryView = accessorySwitch
        return cell
    }
    
    @objc func toggleFilter(_ sender: UISwitch) {
        enableFilters = sender.isOn
    }
    
    @objc func updateFilter(_ sender: UISwitch) {
        if sender.isOn {
            if labels.contains(sender.accessibilityIdentifier!) {
                switch sender.accessibilityIdentifier! {
                case "Food":
                    filters.append(.food(""))
                case "Nap":
                    filters.append(.nap(""))
                case "Noise":
                    filters.append(.noise(""))
                case "Room":
                    filters.append(.room(""))
                default:
                    break;
                }
            } else if HeatMapFiltersVC.utilities.contains(sender.accessibilityIdentifier!) {
                filters.append(.utility(sender.accessibilityIdentifier!.lowercased()))
            }
        } else {
            filters = filters.filter({ (attribute) -> Bool in
                return !attribute.description.contains(sender.accessibilityIdentifier!.lowercased())
            })
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
