//
//  Form.swift
//  YQueue
//
//  Created by Toshio on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class Form: NSObject, UITextFieldDelegate {
    
    private var views: Array<FormView> = []
    private var submitButton: UIButton?
    
    public func wrapper(for view: UIView) -> FormView? {
        for formView in views {
            if formView.view.isEqual(view) {
                return formView
            }
        }
        
        return nil
    }
    
    // Add views consecutively, and next/go button will be set up properly
    public func add(_ textField: UITextField, formatting: Formatting?,
                    validator: Signal<Bool, NoError>) {
        textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.go
        if views.count > 0 {
            for formView in views.reversed() {
                if formView.view.isKind(of: UITextField.self) {
                    (formView.view as! UITextField).returnKeyType = UIReturnKeyType.next
                }
            }
        }
        
        if formatting != nil {
            textField.reactive.continuousTextValues
                .take(during: textField.reactive.lifetime)
                .observe { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.format(textField, text: $0.value!!, withFormatting: formatting!)
                }
        }
        
        views.append(FormView(textField, formatting, validator))
    }
    
    public func add(_ textField: UITextField, validator: Signal<Bool, NoError>) {
        add(textField, formatting: nil, validator: validator)
    }
    
    public func add(_ textField: UITextField, formatting: Formatting?,
                    validation: Validation) {
        let textSignal = textField.reactive.continuousTextValues
        let validator: Signal<Bool, NoError> = textSignal.map { [weak self] in
            guard let `self` = self else {
                return false
            }
            
            return self.validate($0!, validation: validation)
        }
        
        add(textField, validator: validator)
    }
    
    public func add(_ textField: UITextField, validation: Validation) {
        add(textField, formatting: nil, validation: validation)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var index = NSNotFound
        var found = false
        for (i, formView) in views.enumerated() {
            print("form index \(i) has text \((formView.view as! UITextField).text)")
            if formView.view == textField {
                print("found")
                found = true
            } else if found && formView.view.isKind(of: UIResponder.self) {
                index = i
                print("next responder")
                break
            }
        }
        
        if index != NSNotFound {
            (views[index].view as UIResponder).becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            
            if let submit = submitButton {
                submit.sendActions(for: UIControlEvents.touchUpInside)
            }
        }
        
        return true
    }
    
    var invalidSignal: Signal<UITextField, NoError>?
    private var invalidObserver: Observer<UITextField, NoError>?
    public func onSubmit(with submitButton: UIButton) -> Signal<Array<String>, NoError> {
        self.submitButton = submitButton
        
        var initialFormValid = false
        for formView in views {
            initialFormValid = initialFormValid && formView.valid.value
        }
        
        let formValid = MutableProperty(initialFormValid)
        formValid <~ makeValidSignal()
        
        let (invalidSignal, invalidObserver) = Signal<UITextField, NoError>.pipe()
        submitButton.reactive.trigger(for: .touchUpInside)
            .take(during: submitButton.reactive.lifetime)
            .filter { !formValid.value }
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                for formView in self.views {
                    if let textField: UITextField = formView.view as? UITextField,
                        formView.invalid.value {
                        self.invalidObserver?.send(value: textField)
                        return
                    }
                }
            }
        
        self.invalidSignal = invalidSignal
        self.invalidObserver = invalidObserver
        
        return submitButton.reactive.trigger(for: .touchUpInside)
            .take(during: submitButton.reactive.lifetime)
            .filter { formValid.value }
            .map { [weak self] in
                guard let `self` = self else {
                    return []
                }
                
                var texts: Array<String> = []
                for formView in self.views {
                    if formView.view.isKind(of: UITextField.self) {
                        texts.append((formView.view as! UITextField).text!)
                    }
                }
                
                return texts
        }
    }
    
    private func makeValidSignal() -> Signal<Bool, NoError> {
        var signal: Signal<Bool, NoError>? = nil
        for view in views {
            if signal == nil {
                signal = view.validator
            } else {
                signal = signal?
                    .combineLatest(with: view.validator)
                    .map { print("\($0), \($1)"); return $0 && $1 }
            }
        }
        
        return signal!
    }
    
    public class FormView: NSObject {
        let view: UIView
        let formatting: Formatting?
        let validator: Signal<Bool, NoError>
        let valid = MutableProperty(false)
        let invalid = MutableProperty(true)
        
        init(_ view: UIView, _ formatting: Formatting?, _ validator: Signal<Bool, NoError>) {
            self.view = view
            self.formatting = formatting
            self.validator = validator
            self.valid <~ self.validator
            self.invalid <~ self.validator.map { !$0 }
        }
    }
}

extension Form {
    
    public class Validator {
        static func equal(_ textField: UITextField, to: UITextField) -> Signal<Bool, NoError> {
            return Signal
                .combineLatest(textField.reactive.continuousTextValues,
                               to.reactive.continuousTextValues)
                .map {
                print("equal '\($0)' to '\($1)'")
                return $0 == $1
            }
        }
        
        static func callback(textField: UITextField,
                             callback: @escaping (String?) -> Bool) -> Signal<Bool, NoError> {
            return textField.reactive.continuousTextValues.map(callback)
        }
    }
    
    public enum Validation {
        case none, empty, email, emailOptional, length(value: Int), equal(value: String), minMax(min: Int, max: Int)
    }
    
    func validate(_ string: String, validation: Validation) -> Bool {
        switch validation {
        case .none:
            return true
        case .empty:
            return string.characters.count > 0
        case .email:
            return string.characters.count > 0 && string.isValidEmail
        case .emailOptional:
            return string.characters.count > 0 ? string.isValidEmail : true
        case let .length(value):
            return string.characters.count >= value
        case let .equal(value):
            return string == value
        case let .minMax(min, max):
            if let value: Int = Int(string) {
                print("text field value = \(value) , min = \(min), max = \(max)")
                return value >= min && value <= max
            }
            return false
        }
    }
}

extension Form {
    
    public enum Formatting {
        case uppercase, leadingZeros(length: Int)
    }
    
    func format(_ textField: UITextField, text: String, withFormatting formatting: Formatting) {
        var newText = text

        switch formatting {
        case .uppercase:
            newText = text.uppercased()
            break
        case let .leadingZeros(length):
            while newText.characters.count < length {
                newText = "0\(newText)"
            }
            break
        }
        
        if newText != text {
            textField.text = newText
        }
    }
}
