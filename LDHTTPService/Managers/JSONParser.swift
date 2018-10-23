//
//  JSONParser.swift
//
//  Created by Lazar on 12/19/16.
//  Copyright © 2017 Lazar. All rights reserved.
//

import Foundation
import SwiftyJSON

open class JSONParser {

    // MARK: - ERROR
    public static func parseError(JSONData: Data?)
    {
        do
        {
            if let JSONData = JSONData
            {
                let json = try JSON(data: JSONData)
                print(json)
            }
        }
        catch let error
        {
            print(error.localizedDescription)
        }
    }
    
    public static func parseError(JSONString: String?)
    {
        if let dataFromString = JSONString!.data(using: .utf8, allowLossyConversion: false) {
            
            let json:JSON = {
                do {
                    return try JSON(data: dataFromString)
                }
                catch let error
                {
                    print(error.localizedDescription)
                    return JSON()
                }
            }()
            
            print(json)
        }
    }
    
    public static func getJSONFromData(_ JSONData: Data?) -> JSON {
        let json:JSON = {
            do {
                if let jsonData = JSONData
                {
                    return try JSON(data: jsonData)
                }
                return JSON()
            }
            catch let error
            {
                print(error.localizedDescription)
                return JSON()
            }
        }()
        return json
    }
    
    public static func printResponse(JSONData: Data?)
    {
        let json:JSON = getJSONFromData(JSONData)
        print(json)
    }
}
