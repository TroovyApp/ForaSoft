//
//  StepDateTableViewCell.swift
//  troovy-ios
//
//  Created by Daniil on 19.12.2017.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

class StepDateTableViewCell: StepInfoTableViewCell, UITextViewDelegate {
    
    // MARK: Properties Overriders
    
    override var frame: CGRect {
        didSet {
            self.contentTextView?.layoutSubviews()
            self.contentTextViewLight?.layoutSubviews()
        }
    }
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var contentTextView: PlaceholderTextView!
    @IBOutlet weak var contentTextViewLight: PlaceholderTextView!
    
    // MARK: Private Properties
    
    private var dateFormatter: DateFormatter!
    
    // MARK: Init Methods & Superclass Overriders
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupDateFormatter()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func isStepFilled() -> Bool {
        return (self.stepSelected || (self.contentTextView.text != nil && !self.contentTextView.text!.isEmpty))
    }
    
    override func makeAdditionalTransforms(filled: Bool, scaled: Bool) {
        self.contentContainer.transform = (scaled ? CGAffineTransform.identity : CGAffineTransform.identity.scaledBy(x: 0.85, y: 0.85).translatedBy(x: 0.0 - self.contentTextViewLight.bounds.width * 0.09, y: 0.0 - self.fullSizeHeight * 0.01))
        
        self.contentTextView.alpha = (scaled ? 1.0 : 0.0)
        self.contentTextViewLight.alpha = (scaled ? 0.0 : 1.0)
        
        self.contentContainer.bringSubview(toFront: (scaled ? self.contentTextView : self.contentTextViewLight))
    }
    
    override func configureInterface(animated: Bool) {
        if !self.stepSelected && self.contentTextView.isFirstResponder {
            self.contentTextView.resignFirstResponder()
        }
        
        self.configureInterface()
        
        super.configureInterface(animated: animated)
    }
    
    // MARK: Private Methods
    
    private func setupDateFormatter() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.dateFormat = "MMM dd, yyyy     hh:mm a"
    }
    
    private func configureInterface() {
        self.contentTextView.inputView = self.dateInputView()
        self.contentTextView.placeholder = self.step.placeholder
        self.contentTextView.text = self.dateString()
        self.contentTextView.isScrollEnabled = false
        
        self.contentTextViewLight.placeholder = self.step.placeholder
        self.contentTextViewLight.textContainer.maximumNumberOfLines = 2
        self.contentTextViewLight.textContainer.lineBreakMode = .byTruncatingTail
        self.contentTextViewLight.text = self.dateString()
        self.contentTextViewLight.tintColor = .clear
        self.contentTextViewLight.isScrollEnabled = false
    }
    
    private func dateString() -> String? {
        if let date = self.step.date {
            let dateString = self.dateFormatter.string(from: date)
            return dateString
        }
        
        return nil
    }
    
    private func dateInputView() -> UIView {
        let date = (self.step.date ?? (Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()))
        var currentDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        currentDateComponents.second = 0
        if let minute = currentDateComponents.minute, let hour = currentDateComponents.hour {
            if minute > 45 {
                currentDateComponents.minute = 0
                currentDateComponents.hour = hour + 1
            } else if minute > 30 {
                currentDateComponents.minute = 45
            } else if minute > 15 {
                currentDateComponents.minute = 30
            } else {
                currentDateComponents.minute = 15
            }
        } else {
            currentDateComponents.minute = 45
        }
        
        let dateInputView = UIDatePicker()
        dateInputView.datePickerMode = .dateAndTime
        dateInputView.minuteInterval = 15
        dateInputView.date = (Calendar.current.date(from: currentDateComponents) ?? Date())
        dateInputView.locale = Locale(identifier: "en_US_POSIX")
        dateInputView.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        
        self.changeDateLimits(datePicker: dateInputView)
        
        return dateInputView
    }
    
    private func changeDateLimits(datePicker: UIDatePicker?) {
        guard let datePickerView = datePicker else {
            return
        }
        
        let pickerDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: datePickerView.date)
        let currentDate = Date()
        var currentDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)
        currentDateComponents.second = 0
        
        if pickerDateComponents.year == currentDateComponents.year && pickerDateComponents.month == currentDateComponents.month && pickerDateComponents.day == currentDateComponents.day {
            if let minute = currentDateComponents.minute, let hour = currentDateComponents.hour {
                if minute > 45 {
                    currentDateComponents.minute = 0
                    currentDateComponents.hour = hour + 1
                } else if minute > 30 {
                    currentDateComponents.minute = 45
                } else if minute > 15 {
                    currentDateComponents.minute = 30
                } else {
                    currentDateComponents.minute = 15
                }
            } else {
                currentDateComponents.minute = 45
            }
            datePickerView.minimumDate = (Calendar.current.date(from: currentDateComponents) ?? currentDate).addingTimeInterval(900)
        } else {
            currentDateComponents.hour = 0
            currentDateComponents.minute = 0
            datePickerView.minimumDate = Calendar.current.date(from: currentDateComponents)
        }
        
        datePickerView.maximumDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
    }
    
    // MARK: Controls Actions
    
    @objc private func datePickerChanged(_ sender: UIDatePicker) {
        self.step.changeDate(date: sender.date)
        self.changeDateLimits(datePicker: sender)
        self.step.changeDate(date: sender.date)
        self.contentTextView.text = self.dateString()
        self.step.changeText(text: self.contentTextView.text)
        self.delegate?.cell(self, didChangeStep: self.step, order: self.stepOrder)
    }
    
    // MARK: Protocols Implementation
    
    // MARK: UITextViewDelegate
    
    internal func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.contentTextView.tintColor = .clear
        if textView == self.contentTextViewLight {
            if !self.stepSelected {
                DispatchQueue.main.async {
                    self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
                }
            }
            
            return false
        }
        
        return true
    }
    
    internal func textViewDidBeginEditing(_ textView: UITextView) {
        self.contentTextView.tintColor = .clear
        self.setContentLabel(visible: true, animated: true)
        
        if !self.stepSelected {
            self.delegate?.cell(self, didBecomeFirstResponderWithOrder: self.stepOrder)
        }
        
        if let datePickerView = self.contentTextView.inputView as? UIDatePicker {
            self.step.changeDate(date: datePickerView.date)
            self.changeDateLimits(datePicker: datePickerView)
            self.step.changeDate(date: datePickerView.date)
            self.contentTextView.text = self.dateString()
            self.step.changeText(text: textView.text)
            self.delegate?.cell(self, didChangeStep: self.step, order: self.stepOrder)
        }
    }
    
    internal func textViewDidEndEditing(_ textView: UITextView) {
        self.setContentLabel(visible: false, animated: true)
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        self.checkCellFilled(animated: true)
    }
    
}
