//
//  InfoViewController.swift
//  Sqanned
//
//  Created by user206736 on 11/4/21.
//

import UIKit
import CoreData

class InfoViewController: UIViewController {
    
    @IBOutlet weak var firstNameLabel: UILabel!
    
    @IBOutlet weak var lastNameLabel: UILabel!
    
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var editButton: UIButton!

    @IBOutlet weak var closeButton: UIButton!
    
    var user : [NSManagedObject] = []
    
    var person : NSManagedObject!
    
    var editModeOn = false
    
    var newFirstName : String = ""
    
    var newLastName : String = ""
    
    var newPhone : String = ""
    
    var newEmail : String = ""

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
        
        isEditMode(isEdit: false)
        
        guard let appDelegate =
        UIApplication.shared.delegate as? AppDelegate else {
            return
        }
          
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
          
        do {
            user = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        if (!user.isEmpty) {
            person = user[0]
            
            let fn = person.value(forKey: "firstName") as? String
            let ln = person.value(forKey: "lastName") as? String
            let pn = person.value(forKey: "phoneNum") as? String
            let em = person.value(forKey: "email") as? String
            
            changeLabels(fn: fn!, ln: ln!, pn: pn!, em: em!)
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClosePress(_ sender: Any) {
        self.dismiss(animated:true, completion: nil)
    }
    
    
    @IBAction func onEditPress(_ sender: Any) {
        
        if (editModeOn) {
            if (firstNameTextField.text == "") {
                displayAlert(title: "First Name Required", message: "Please include a first name")
            } else {
                isEditMode(isEdit: false)
                makeInfoChanges()
                dismissKeyboard()
            }
        } else {
            isEditMode(isEdit: true)
        }
        
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func isEditMode(isEdit : Bool) {
        editModeOn = isEdit
        
        closeButton.isHidden = isEdit
        
        firstNameTextField.isHidden = !isEdit
        lastNameTextField.isHidden = !isEdit
        phoneTextField.isHidden = !isEdit
        emailTextField.isHidden = !isEdit
        
        if (isEdit) {
            firstNameTextField.text = firstNameLabel.text == "No Info" ? "" : firstNameLabel.text
            lastNameTextField.text = lastNameLabel.text == "No Info" ? "" : lastNameLabel.text
            phoneTextField.text = phoneLabel.text == "No Info" ? "" : phoneLabel.text
            emailTextField.text = emailLabel.text == "No Info" ? "" : emailLabel.text
            
            editButton.setTitle("Done", for: .normal)
        } else {
            editButton.setTitle("Edit", for: .normal)
        }
        
        firstNameLabel.isHidden = isEdit
        lastNameLabel.isHidden = isEdit
        phoneLabel.isHidden = isEdit
        emailLabel.isHidden = isEdit
    }
    
    func makeInfoChanges() {
        
        deleteUser(user: person)
        
        newFirstName = firstNameTextField.text!
        newLastName  = lastNameTextField.text!
        newPhone     = phoneTextField.text!
        newEmail     = emailTextField.text!
        
        save(fname: newFirstName,
             lname: newLastName,
             pnum: newPhone,
             email: newEmail,
             qrString: QRCodeString(fn: newFirstName, ln: newLastName, pn: newPhone, em: newEmail))
        
        changeLabels(fn: newFirstName, ln: newLastName, pn: newPhone, em: newEmail)
  
    }
    
    func changeLabels(fn: String, ln: String, pn: String, em: String) {
        let na = "No Info"
        
        firstNameLabel.text = fn == "" ? na : fn
        lastNameLabel.text  = ln == "" ? na : ln
        phoneLabel.text     = pn == "" ? na : pn
        emailLabel.text     = em == "" ? na : em
    }
    
    func QRCodeString(fn : String, ln : String, pn : String, em : String) -> String {
        let email = em != "" ? "\nEMAIL;TYPE=INTERNET;TYPE=HOME:\(em)" : ""
        let phoneNum = pn != "" ? "\nTEL;TYPE=CELL:\(pn)" : ""
        
        return "BEGIN:VCARD\nVERSION:3.0\nN: \(ln);\(fn);;;\(email)\(phoneNum)\nEND:VCARD"
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle:UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func save(fname: String, lname: String, pnum: String, email: String, qrString : String) {
      
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "User",
                                                in: managedContext)!
        let person = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
      
        person.setValue(fname, forKeyPath: "firstName")
        person.setValue(lname, forKeyPath: "lastName")
        person.setValue(pnum, forKeyPath: "phoneNum")
        person.setValue(email, forKeyPath: "email")
        person.setValue(qrString, forKeyPath: "qrString")

        do {
            try managedContext.save()
            user.append(person)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func deleteUser(user: NSManagedObject) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        
        if let result = try? managedContext.fetch(fetchRequest) {
            for object in result {
                managedContext.delete(object)
            }
        }
     
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
