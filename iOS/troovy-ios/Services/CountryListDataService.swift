//
//  CountryListDataService.swift
//  troovy-ios
//
//  Created by Daniil on 14.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class CountryListDataService: TroovyService {
    
    // MARK: Public Properties
    
    /// Stores sorted array of first letters of the countries.
    private(set) var firstLetters: [String] = []
    
    /// Stores number of the countries per section.
    private(set) var numberInSection: [Int] = []
    
    // MARK: Private Properties
    
    private(set) var countriesList: [[String:String]] = [[:]]
    private(set) var sortedCountryNames: [String] = []
    private(set) var countryCodesForCountryName: [String:String] = [:]
    private(set) var regionCodesForCountryName: [String:String] = [:]
    
    // MARK: Init Methods & Superclass Overriders
    
    override init() {
        super.init()
        
        self.setupCountriesList()
        self.setupCountryCodesAndCountryRegionCodes()
        self.setupContriesNames()
        self.setupCountriesForSections()
    }
    
    // MARK: Public Methods
    
    /// Asks for number of countries parsed from "countries.json".
    ///
    /// - returns: Number of countries.
    ///
    func numberOfCountries() -> Int {
        return self.sortedCountryNames.count
    }
    
    /// Asks for country name at index.
    ///
    /// - parameter index: Index of the country.
    ///
    /// - returns: Name of the country or nil.
    ///
    func countryName(forIndex index: Int) -> String? {
        if index >= self.sortedCountryNames.count {
            return nil
        }
        
        return self.sortedCountryNames[index]
    }
    
    /// Asks for country name for region code.
    ///
    /// - parameter regionCode: Code of the region.
    ///
    /// - returns: Name of the country or nil.
    ///
    func countryName(forRegionCode regionCode: String?) -> String? {
        if regionCode == nil {
            return nil
        }
        
        for (key, value) in self.regionCodesForCountryName {
            if value == regionCode {
                return key
            }
        }
        
        return nil
    }
    
    /// Asks for country region code for country code.
    ///
    /// - parameter countryCode: Code of the country.
    ///
    /// - returns: Country region code or nil.
    ///
    func countryRegionCode(forCountryCode countryCode: String?) -> String? {
        if countryCode == nil {
            return nil
        }

        var countryName: String?
        for (key, value) in self.countryCodesForCountryName {
            if value == countryCode {
                countryName = key
                break
            }
        }
        
        return self.countryRegionCode(forCountryName: countryName)
    }
    
    /// Asks for country code for country name.
    ///
    /// - parameter countryName: Name of the country.
    ///
    /// - returns: Country code or nil.
    ///
    func countryCode(forCountryName countryName: String?) -> String? {
        if countryName == nil {
            return nil
        }
        
        return self.countryCodesForCountryName[countryName!]
    }
    
    /// Asks for region code for country name.
    ///
    /// - parameter countryName: Name of the country.
    ///
    /// - returns: Country code from "countries.json" or current locale region code or nil.
    ///
    func countryRegionCode(forCountryName countryName: String?) -> String? {
        if countryName == nil {
            return nil
        }
        
        if let regionCode = self.regionCodesForCountryName[countryName!] {
            return regionCode
        }
        
        return Locale.current.regionCode
    }
    
    // MARK: Private Methods
    
    private func setupCountriesList() {
        guard let filePath = Bundle.main.path(forResource: "countries", ofType: "json") else {
            fatalError("countries.json not found")
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let parsedData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            self.countriesList = parsedData as! [[String:String]]
        } catch {
            fatalError("Error parsing countries \(error)")
        }
    }
    
    private func setupCountryCodesAndCountryRegionCodes() {
        var countryCodes: [String:String] = [:]
        var countryRegionCodes: [String:String] = [:]
        
        for country in self.countriesList {
            let countryCode = String.init(format: "%@", country["code"] ?? "")
            let callingCode = String.init(format: "%@", country["dial_code"] ?? "")
            let countryName = String.init(format: "%@", country["name"] ?? "")
            
            if countryCode.isEmpty || callingCode.isEmpty || countryName.isEmpty {
                continue
            }
            
            countryCodes[countryName] = callingCode
            countryRegionCodes[countryName] = countryCode
        }
        
        self.countryCodesForCountryName = countryCodes
        self.regionCodesForCountryName = countryRegionCodes
    }
    
    private func setupContriesNames() {
        let countries = self.countryCodesForCountryName.keys
        self.sortedCountryNames = countries.sorted(by: { (firstArgument, secondArgument) -> Bool in
            return firstArgument.localizedStandardCompare(secondArgument) == ComparisonResult.orderedAscending
        })
    }
    
    private func setupCountriesForSections() {
        var letters: [String] = []
        
        for index in 0..<self.sortedCountryNames.count {
            let country = self.sortedCountryNames[index]
            let firstLetter = String(country.prefix(upTo: country.index(country.startIndex, offsetBy: 1)))
            
            if !letters.contains(firstLetter) {
                letters.append(firstLetter)
                
                let predicate = NSPredicate(format: "SELF beginswith[c] %@", argumentArray: [firstLetter])
                let filteredCountries = self.sortedCountryNames.filter {
                    predicate.evaluate(with: $0)
                }
                
                self.numberInSection.append(filteredCountries.count)
            }
        }
        
        self.firstLetters = letters
    }

}
