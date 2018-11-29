//
//  CountriesPickerView.swift
//  troovy-ios
//
//  Created by Daniil on 17.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

protocol CountriesPickerDelegate: class {
    func pickerView(view: CountriesPickerView, didSelectCountry country: CountryModel, atIndexPath indexPath: IndexPath)
}

class CountriesPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: Public Properties
    
    weak var countriesDelegate: CountriesPickerDelegate?
    
    // MARK: Private Properties
    
    private var countryListDataService: CountryListDataService!
    
    private var numberInSection: [Int] = []
    private var firstLetter: [String] = []
    
    private var selectedCountryName: String?
    private var selectedRegionCode: String?
    private var selectedIndexPath: IndexPath?
    
    // MARK: Init Methods & Superclass Overriders
    
    init(frame: CGRect, countryListDataService: CountryListDataService) {
        super.init(frame: frame)
        
        self.delegate = self
        self.dataSource = self
        
        self.countryListDataService = countryListDataService
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reloadAllComponents()
    }
    
    // MARK: Public Methods
    
    /// Configures and prepares picker for work.
    func configure() {
        self.numberInSection = self.countryListDataService.numberInSection
        self.firstLetter = self.countryListDataService.firstLetters
        
        self.reloadAllComponents()
        
        if self.selectedRegionCode != nil && self.selectedCountryName != nil {
            self.selectedIndexPath = nil
            self.checkSelectedCountry()
        }
    }
    
    /// Selects picker row with countryName and regionCode or at indexPath if exists.
    ///
    /// - parameter countryName: Name of the country.
    /// - parameter regionCode: Region code of the country.
    /// - parameter indexPath: Index path of the country.
    ///
    func select(countryWithCountryName countryName: String?, regionCode: String?, indexPath: IndexPath?) {
        self.selectedCountryName = countryName
        self.selectedRegionCode = regionCode
        self.selectedIndexPath = indexPath
        
        self.checkSelectedCountry()
    }
    
    // MARK: Private Methods
    
    private func checkSelectedCountry() {
        if self.selectedIndexPath == nil && self.selectedRegionCode != nil && self.selectedCountryName != nil {
            let firstCharacterIndex = self.selectedCountryName!.startIndex
            let firstLetter = String(self.selectedCountryName!.prefix(upTo: self.selectedCountryName!.index(firstCharacterIndex, offsetBy: 1)))
            if let section = self.firstLetter.index(of: firstLetter) {
                let rows = self.numberInSection[section]
                for index in 0..<rows {
                    let countryName = self.countryListDataService.countryName(forIndex: self.countryIndex(inSection: section) + index)
                    if countryName != nil && countryName == self.selectedCountryName {
                        self.selectedIndexPath = IndexPath(row: index, section: section)
                        break
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            if self.selectedIndexPath != nil && self.numberOfRows(inComponent: 0) > self.selectedIndexPath!.section && self.numberOfRows(inComponent: 1) > self.selectedIndexPath!.row {
                self.selectRow(self.selectedIndexPath!.section, inComponent: 0, animated: false)
                self.selectRow(self.selectedIndexPath!.row, inComponent: 1, animated: false)
            }
        }
    }
    
    private func countryIndex(inSection section: Int) -> Int {
        var result = 0
        for index in 0..<section {
            result += self.numberInSection[index]
        }
        return result
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UIPickerViewDelegate & UIPickerViewDataSource
    
    internal func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let width = pickerView.bounds.width
        
        if component == 0 {
            return width / 5.0
        } else {
            return width / 5.0 * 4.0
        }
    }
    
    internal func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44.0
    }
    
    internal func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    internal func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return self.firstLetter.count
        } else {
            let selectedSection = self.selectedRow(inComponent: 0)
            return self.numberInSection[selectedSection]
        }
    }
    
    internal func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            let letter = self.firstLetter[row]
            return letter
        } else {
            let selectedSection = self.selectedRow(inComponent: 0)
            
            guard let countryName = self.countryListDataService.countryName(forIndex: self.countryIndex(inSection: selectedSection) + row), let callingCode = self.countryListDataService.countryCode(forCountryName: countryName) else {
                return "undefined"
            }
            
            return countryName + " " + callingCode
        }
    }
    
    internal func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            self.reloadComponent(1)
        }
        
        let selectedSection = self.selectedRow(inComponent: 0)
        let selectedRow = self.selectedRow(inComponent: 1)
        
        guard let countryName = self.countryListDataService.countryName(forIndex: self.countryIndex(inSection: selectedSection) + selectedRow), let callingCode = self.countryListDataService.countryCode(forCountryName: countryName), let regionCode = self.countryListDataService.countryRegionCode(forCountryName: countryName) else {
            return
        }
        
        let indexPath = IndexPath(row: selectedRow, section: selectedSection)
        let countryModel = CountryModel(withCountryName: countryName, callingCode: callingCode, regionCode: regionCode)
        
        self.countriesDelegate?.pickerView(view: self, didSelectCountry: countryModel, atIndexPath: indexPath)
    }

}
