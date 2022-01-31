//
//  ViewController.swift
//  Scannect
//
//  Created by user206736 on 10/25/21.
//

import UIKit
import PassKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    @IBOutlet weak var firstName: UITextField!
    
    @IBOutlet weak var lastName: UITextField!
    
    @IBOutlet weak var phoneNum: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var inputStackView: UIStackView!
    
    @IBOutlet weak var QRCodeImage: UIImageView!
    
    @IBOutlet weak var userButton: UIButton!
    
    @IBOutlet weak var addPhotoButton: UIButton!
    
    var user : [NSManagedObject] = []
    
    var QRString : String = ""
    
    var QRImage : UIImage!
    
    var didInitialLoad : Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        view.addGestureRecognizer(tap)
        
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
        
        if (user.isEmpty) {
            QRCodeImage.isHidden = true
            inputStackView.isHidden = false
            userButton.isHidden = true
            addPhotoButton.isHidden = true
            mainScrollView.isScrollEnabled = true
        } else {
            QRString = user[0].value(forKey: "qrString") as! String
            displayQRCode(isUpdatedQR: false)
            mainScrollView.isScrollEnabled = false
        }
        
        didInitialLoad = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (user.isEmpty || didInitialLoad) {
            didInitialLoad = false
            return
        }
        
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
        
        QRString = user[0].value(forKey: "qrString") as! String
        displayQRCode(isUpdatedQR: true)
        
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
    
    @IBAction func onFinishPress(_ sender: Any) {
        if (firstName.text == "") {
            displayAlert(title: "First Name Required", message: "Please enter your first name into the field")
            return
        }
        
        let fn = firstName.text
        let ln = lastName.text!
        let pn = phoneNum.text!
        let em = email.text!
        
        QRString = QRCodeString(fn: fn!, ln: ln, pn: pn, em: em)

        save(fname: fn!, lname: ln, pnum: pn, email: em, qrString: QRString)
    
        displayQRCode(isUpdatedQR: false)
        
        userButton.isHidden = false
        addPhotoButton.isHidden = false
        mainScrollView.isScrollEnabled = false
       
    }
    
    @IBAction func onAddPhotoPress(_ sender: Any) {
        UIGraphicsBeginImageContext(QRCodeImage.frame.size)
        QRCodeImage.layer.render(in: UIGraphicsGetCurrentContext()!)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(output!, nil, nil, nil)
        displayAlert(title:"QR Code Added", message: "Your QR code has been added into your camera roll")
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle:UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func displayQRCode(isUpdatedQR: Bool) {
        
        QRImage = generateQRCode()
        
        QRCodeImage.image = QRImage
        QRCodeImage.layer.magnificationFilter = CALayerContentsFilter.nearest
        
        if (!isUpdatedQR) {
            //createWalletButton() - Implemented in Version 2.0
            QRCodeImage.isHidden = false
            inputStackView.isHidden = true
        
        }
    }
    
    func createWalletButton() {
        let passButton = PKAddPassButton(addPassButtonStyle: PKAddPassButtonStyle.black)
        passButton.frame = CGRect(x:((UIScreen.main.bounds.width-200)/2), y: (QRCodeImage.center.y + QRCodeImage.bounds.width/2 + 50), width: 200, height: 50)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        
        view.addSubview(passButton)
    }
    
    func QRCodeString(fn : String, ln : String, pn : String, em : String) -> String {
        let email = em != "" ? "\nEMAIL;TYPE=INTERNET;TYPE=HOME:\(em)" : ""
        let phoneNum = pn != "" ? "\nTEL;TYPE=CELL:\(pn)" : ""
        
        return "BEGIN:VCARD\nVERSION:3.0\nN: \(ln);\(fn);;;\(email)\(phoneNum)\nEND:VCARD"
    }
    
    @objc func passButtonAction() -> Selector {
        
        if (PKAddPassesViewController.canAddPasses()) {
            if let path = Bundle.main.path(forResource: "CCPass", ofType:"pkpass") {
                // use path
                let data : Data? = loadData(from: path)
                let pass : PKPass? = try? PKPass(data: data!)
                
                self.present(PKAddPassesViewController(pass: pass!)!, animated: true)
                
            }
        }
        
        return Selector(("touchUpInside"))
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func loadData(from path: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }
    
    func generateQRCode() -> UIImage? {
        let data = QRString.data(using: String.Encoding.ascii)
        if let QRFilter = CIFilter(name: "CIQRCodeGenerator") {
            QRFilter.setValue(data, forKey: "inputMessage")
            guard let QRImage = QRFilter.outputImage else {return nil}
            
            let transformScale = CGAffineTransform(scaleX: 5.0, y: 5.0)
            let scaledQRImage = QRImage.transformed(by: transformScale)
            
            return UIImage(ciImage: scaledQRImage)
        }
        return nil
    }
    

}

