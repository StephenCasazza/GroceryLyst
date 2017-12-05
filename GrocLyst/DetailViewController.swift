//
//  DetailViewController.swift
//  GrocLyst
//
//  Created by Stephen Casazza on 11/28/17.
//  Copyright © 2017 Casazza. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    

    @IBOutlet weak var itemTextField: UITextField!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var stepperValue: UIStepper!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var grocerys: GroceryItem?
    var quantityValue: Int!
    var placeholderLabel: UILabel!

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        if let groceryItem = grocerys {
            itemTextField.text = groceryItem.name
            quantityLabel.text = groceryItem.quantity
            notesTextView.text = groceryItem.notes
            stepperValue.value = Double(groceryItem.quantity)!
        } else {
            grocerys = GroceryItem(name: "", quantity: "", notes: "", groceryItemID: "", postingUserID: "")
        }
        if stepperValue.value == 0 || itemTextField.text == "" {
            saveButton.isEnabled = false
        }
        itemTextField.becomeFirstResponder()
        if itemTextField.text == "" {
            navigationItem.title = "New Item"
        } else {
            navigationItem.title = "Edit Item"
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        grocerys?.name = itemTextField.text!
        grocerys?.quantity = quantityLabel.text!
        grocerys?.notes = notesTextView.text!
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func textFieldPresssed(_ sender: UITextField) {
        if itemTextField.text == "" || stepperValue.value == 0 {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func quantityStepper(_ sender: UIStepper) {
        if stepperValue.value == 0 || itemTextField.text == "" {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
         quantityLabel.text = String(Int(stepperValue.value))
    }
}
