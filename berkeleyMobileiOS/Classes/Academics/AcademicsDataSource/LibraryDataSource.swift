//
//  LibraryDataSource.swift
//  berkeleyMobileiOS
//
//  Created by Maya Reddy on 11/20/16.
//  Copyright © 2016 org.berkeleyMobile. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

fileprivate let kLibrariesEndpoint = sensorDataSource + "/libraries.php"

class LibraryDataSource: ResourceDataSource {
    
    typealias ResourceType = Library
    
    // Fetch the list of libraries and report back to the completionHandler.
    static func fetchResources(_ completion: @escaping ([Resource]?) -> Void) 
    {
        Alamofire.request(encode_url_no_cache(kLibrariesEndpoint)).response { response in

            if !response.error.isNil {
                print("Error")
            }
            
        }
        
        Alamofire.request(kLibrariesEndpoint).responseJSON
        { response in
            
            if response.result.isFailure {
                print("[Error @ LibraryDataSource.fetchLibraries()]: request failed")
                return
            }
            
            let libraries = JSON(data: response.data!)["libraries"].map { (_, child) in parseLibrary(child) }
            completion(libraries)
        }
    }
    
    static func parseResource(_ json: JSON) -> Resource {
        return parseLibrary(json)
    }
    
    // Return a Library object parsed from JSON.
    private static func parseLibrary(_ json: JSON) -> Library
    {
        let formatter = sharedDateFormatter()
        let weeklyOpeningTimes  = json["weekly_opening_times"].map { (_, child) in formatter.date(from: child.string ?? "") }
        let weeklyClosingTimes  = json["weekly_closing_times"].map { (_, child) in formatter.date(from: child.string ?? "") }
        let weeklyByAppointment = json["weekly_by_appointment"].map { (_, child) in child.bool ?? false }
        
        var utilities_to_add = [String]()
        
        var attributes = json["attributes"].map { (_, child) -> LibraryAttributes in
            let msg = child.string!.components(separatedBy: ": ").last!
            switch child.string! {
            case "food":
                return LibraryAttributes.food(msg)
            case "room":
                return LibraryAttributes.room(msg)
            case "nap":
                return LibraryAttributes.nap(msg)
            case "noise":
                return LibraryAttributes.noise(msg)
            default:
                utilities_to_add = child.string!.components(separatedBy: ": ")[1].components(separatedBy: ", ")
                return LibraryAttributes.utility(utilities_to_add.popLast()!)
            }
        }
        
        for util in utilities_to_add {
            attributes.append(.utility(util))
        }
        
        
        let library = Library(name: json["name"].stringValue, campusLocation: json["campus_location"].string, phoneNumber: json["phone_number"].string, weeklyOpeningTimes: weeklyOpeningTimes, weeklyClosingTimes: weeklyClosingTimes, weeklyByAppointment: weeklyByAppointment, imageLink: json["image_link"].string, latitude: json["latitude"].double, longitude: json["longitude"].double, attributes: attributes)
        
        FavoriteStore.shared.restoreState(for: library)
        
        return library
    }
    
    private static func sharedDateFormatter() -> DateFormatter
    {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }
    
}
