//
//  GroceryLystViewController.swift
//  GrocLyst
//
//  Created by Stephen Casazza on 11/28/17.
//  Copyright © 2017 Casazza. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class GroceryLystViewController: UIViewController {
    
    //MARK:- Variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sortSegmentedControl: UISegmentedControl!
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    @IBOutlet weak var signOutBarButton: UIBarButtonItem!
    var groceryItem = [GroceryItem]()
    var authUI: FUIAuth!
    var db: Firestore!

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    //MARK:- Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        authUI = FUIAuth.defaultAuthUI()
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        authUI?.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        checkForUpdates()
        checkForRepeats(array: groceryItem)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        signIn()
    }
    //MARK:- Functions
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func checkForRepeats(array: [GroceryItem]) {
        if array.count > 1 {
            for index in 0..<array.count-1 {
                if array[index].name == array[array.count-1].name {
                    showAlert(title: "Two Identical Items Added", message: "\(array[index].name) has been added twice.")
                }
            }
        }
    }
    
    func signIn() {
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth()
            ]
        if authUI.auth?.currentUser == nil {
            self.authUI?.providers = providers
            present(authUI.authViewController(), animated: true, completion: nil)
        }
    }
    
    func checkForUpdates() {
        db.collection("groceryItem").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("Error adding snapshot listener \(error!.localizedDescription)")
                return
            }
            self.loadData()
        }
    }
    
    func loadData() {
        db.collection("groceryItem").getDocuments { (querySnapshot, error) in
            guard error == nil else {
                print("ERROR: reading documents \(error!.localizedDescription)")
                return
            }
            self.groceryItem = []
            for document in querySnapshot!.documents {
                let groceryData = GroceryItem(dictionary: document.data())
                groceryData.groceryItemID = document.documentID
                self.groceryItem.append(groceryData)
            }
            if self.sortSegmentedControl.selectedSegmentIndex != 0 {
                self.sortBasedOnSegmentPressed()
            }
            self.tableView.reloadData()
        }
    }
    
    func saveData(groceryItem: GroceryItem) {
        if let postingUserID = (authUI.auth?.currentUser?.displayName) {
            groceryItem.postingUserID = postingUserID
        } else {
            groceryItem.postingUserID = "unknown user"
        }
         let dataToSave: [String: Any] = groceryItem.dictionary

        if groceryItem.groceryItemID != "" {
            let ref = db.collection("groceryItem").document(groceryItem.groceryItemID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("error updating document \(error.localizedDescription)")
                } else {
                    self.sortBasedOnSegmentPressed()
                    print("Doc updated with string ID \(ref.documentID)")
                }
            }
        } else { //No doc ID, create ref ID and save new file
            var ref: DocumentReference? = nil //Firestore will create new reference
            ref = db.collection("groceryItem").addDocument(data: dataToSave) { (error) in
                if let error = error {
                    print("error adding doc \(error.localizedDescription)")
                } else {
                    print("Document added with reference ID \(ref!.documentID)")
                    groceryItem.groceryItemID = "\(ref!.documentID)"
                    self.sortBasedOnSegmentPressed()
                }
            }
        }
    }
    
    func deleteData(index: Int) {
       let ref = db.collection("groceryItem").document(groceryItem[index].groceryItemID)
        ref.delete()
    }
    
    func sortBasedOnSegmentPressed() {
        switch sortSegmentedControl.selectedSegmentIndex {
        case 0: // unsorted
            loadData()
        case 1: // A-Z
            let sortedArray = groceryItem.sorted(by: {$0.name < $1.name})
            groceryItem = sortedArray
            tableView.reloadData()
        default:
            print("ERROR: You should never have gotten here!")
        }
    }
    
    //MARK:- Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let destination = segue.destination as! DetailViewController
            let selectedRow = tableView.indexPathForSelectedRow!.row
            destination.grocerys = groceryItem[selectedRow]
        } else {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
    }
    
    //MARK:- IBActions
    @IBAction func unwindFromDetail(segue: UIStoryboardSegue) {
        let source = segue.source as! DetailViewController
        if tableView.indexPathForSelectedRow != nil {
            let indexOfMatch = groceryItem.index(where: {$0.groceryItemID == source.grocerys?.groceryItemID})!
            groceryItem[indexOfMatch] = (source.grocerys)!
            saveData(groceryItem: groceryItem[indexOfMatch])
        } else {
            let newIndexPath = IndexPath(row: groceryItem.count, section: 0)
            groceryItem.append((source.grocerys)!)
            saveData(groceryItem: (source.grocerys)!)
        }
}
    @IBAction func sortSegmentPressed(_ sender: UISegmentedControl) {
    sortBasedOnSegmentPressed()
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIBarButtonItem) {
        do {
            try authUI.signOut()
            print("Successfully signed out")
            signIn()
        } catch {
            print("Couldn't sign out")
        }
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            addBarButton.isEnabled = true
            editBarButton.title = "Edit"
            signOutBarButton.isEnabled = true
        } else {
            tableView.setEditing(true, animated: true)
            addBarButton.isEnabled = false
            editBarButton.title = "Done"
            signOutBarButton.isEnabled = false
        }
    }
    
    
}
//MARK:- Table view extension
extension GroceryLystViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groceryItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = groceryItem[indexPath.row].name + " - " + groceryItem[indexPath.row].quantity
        cell.detailTextLabel?.text = groceryItem[indexPath.row].postingUserID
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteData(index: indexPath.row)
            groceryItem.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = groceryItem[sourceIndexPath.row]
        groceryItem.remove(at: sourceIndexPath.row)
        groceryItem.insert(itemToMove, at: destinationIndexPath.row)

    }
}

//MARK:- Auth extension
extension GroceryLystViewController: FUIAuthDelegate {
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        return false
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if let user = user {
            print("*** Succesfully logged in with user = \(user.email!)")
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        let loginViewController = FUIAuthPickerViewController(authUI: authUI)
        loginViewController.view.backgroundColor = UIColor.white
        let marginInset: CGFloat = 16
        let imageY = self.view.center.y - 225
        let logoFrame = CGRect(x: self.view.frame.origin.x + marginInset, y: imageY, width: self.view.frame.width - (marginInset * 2), height: 225)
        let logoImageView = UIImageView(frame: logoFrame)
        logoImageView.image = UIImage(named: "image")
        logoImageView.contentMode = .scaleAspectFit
        loginViewController.view.addSubview(logoImageView)
        return loginViewController
    }
}
