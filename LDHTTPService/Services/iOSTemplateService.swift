//
//  iOSTemplateService.swift
//
//  Created by Lazar on 12/16/16.
//  Copyright © 2017 Lazar. All rights reserved.
//

import Foundation
import UIKit

class iOSTemplateService {

    private var ldService : LDService! = nil
    
    static let shared: iOSTemplateService = {
        
        let instance = iOSTemplateService()
        
        instance.ldService = LDService.shared

        return instance
    }()
    
    // MARK: - Authorisation
    
    /// Set Authorisation Token
    ///
    /// - Parameter token: Authorisation Token.
    func setAuthorisationToken(_ token: String)
    {
        ldService.token = token
    }
}
