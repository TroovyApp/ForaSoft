//
//  CountryModel.swift
//  troovy-ios
//
//  Created by Daniil on 17.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import Foundation

struct CountryModel {
    
    // MARK: Properties
    
    /// Name of the country.
    private(set) var countryName: String!
    
    /// Calling code of the country.
    private(set) var callingCode: String!
    
    /// Region code of the country.
    private(set) var regionCode: String!
    
    // MARK: Methods
    
    /// Initializes structure with passed properties.
    ///
    /// - parameter countryName: Name of the country.
    /// - parameter callingCode: Calling code of the country.
    /// - parameter regionCode: Region code of the country.
    ///
    init(withCountryName countryName: String, callingCode: String, regionCode: String) {
        self.countryName = countryName
        self.callingCode = callingCode
        self.regionCode = regionCode
    }
    
}
