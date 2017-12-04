//
//  File.swift
//  GrocLyst
//
//  Created by Stephen Casazza on 11/28/17.
//  Copyright © 2017 Casazza. All rights reserved.
//

import Foundation

class GroceryItem {
    var name: String = ""
    var quantity: String = ""
    var notes: String = ""
    var groceryItemID: String = ""
    var postingUserID: String = ""
    
    var dictionary: [String: Any] {
        return ["name": name, "quantity": quantity, "notes": notes, "postingUserID": postingUserID] }
    
    init(name: String, quantity: String, notes: String, groceryItemID: String, postingUserID: String) {
        self.name = name
        self.quantity = quantity
        self.notes = notes
        self.groceryItemID = groceryItemID
        self.postingUserID = postingUserID
    }
    
    convenience init(dictionary: [String: Any]) {
        let name = dictionary["name"] as! String? ?? ""
        let quantity = dictionary["quantity"] as! String? ?? ""
        let postingUserID = dictionary["postingUserID"] as! String? ?? ""
        let notes = dictionary["notes"] as! String? ?? ""
        self.init(name: name, quantity: quantity, notes: notes, groceryItemID: "", postingUserID: postingUserID)
    }
}
