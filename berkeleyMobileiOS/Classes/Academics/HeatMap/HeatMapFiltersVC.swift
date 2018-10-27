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
            print(filters)
        }
    }
    var parentVC: HeatMapVC?
    
    private let labels = ["Food", "Nap", "Noise", "Room", "Utilities"]
    private let utilities = ["Laptops", "Projectors", "Printers", "Photocopiers"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section <= 3 {
            return 1
        } else {
            return 4
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Whether food is allowed at some places inside the library building:"
        case 1:
            return "Whether there are places to nap:"
        case 2:
            return "Whether there is a noise floor / place for discussions & group work:"
        case 3:
            return "Whether rooms can be reserved:"
        case 4:
            return "The various utilities that the library offers:"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let filters_as_string = filters.map {$0.description}
        
        let accessorySwitch = UISwitch()
        
        if indexPath.section <= 3 {
            let filterName = labels[indexPath.section]
            cell.textLabel?.text = filterName
            accessorySwitch.isOn = filters_as_string.contains {
                $0.contains(filterName.lowercased())
            }
        } else {
            let filterName = utilities[indexPath.row]
            cell.textLabel?.text = filterName
            accessorySwitch.isOn = filters_as_string.contains {
                $0.contains(filterName.lowercased())
            }
        }
        accessorySwitch.accessibilityIdentifier = cell.textLabel?.text
        accessorySwitch.addTarget(self,
                                  action: #selector(updateFilter(_:)),
                                  for: .valueChanged)
        cell.accessoryView = accessorySwitch
        return cell
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
            } else if utilities.contains(sender.accessibilityIdentifier!) {
                filters.append(.utility(sender.accessibilityIdentifier!))
            }
        } else {
            filters = filters.filter({ (attribute) -> Bool in
                return !attribute.description.contains(sender.accessibilityIdentifier!.lowercased())
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        parentVC?.filters = self.filters
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
