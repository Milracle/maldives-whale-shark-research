//
//  EncountersTableViewController.swift
//  MaldivesWhaleSharkResearch
//
//  Created by mac on 4/29/17.
//  Copyright © 2017 dooddevelopments. All rights reserved.
//

import UIKit
import BWWalkthrough
import BTNavigationDropdownMenu
import FirebaseDatabase
import SDWebImage
import Fusuma
import Firebase

typealias EncounterCallback = ([String]) -> Void

class EncountersTableViewController: UITableViewController, BWWalkthroughViewControllerDelegate, FusumaDelegate  {
    
    // MARK: - Properties
    var encounters : [Encounter] = []
    var uploadWalkthrough:BWWalkthroughViewController!
    var selectedImage: UIImage!
    var likedEncounters = [String]()
    var menuIndex = 0

    // MARK: - View Did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make back bar title blank after segue
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.getEncounterIds(index:1, onCompletion: { (ids) in
            self.likedEncounters = ids
            self.getEncountersWith(ids: ids)
        })

        // Create the menuview
        let items = ["All Encounters", "Liked Encounters", "My Encounters"]
        let menuView = BTNavigationDropdownMenu(title: items[0], items: items as [AnyObject])
        menuView.navigationBarTitleFont = UIFont(name: "MuseoSans-500", size: 19)
        menuView.cellHeight = 65
        menuView.cellBackgroundColor = UIColor(red: 66.0/255.0, green: 66.0/255.0, blue: 66.0/255.0, alpha: 1.0)
        menuView.cellSelectionColor = UIColor(red: 66.0/255.0, green:66.0/255.0, blue:66.0/255.0, alpha: 1.0)
        menuView.cellTextLabelColor = UIColor.white
        menuView.cellTextLabelFont = UIFont(name: "MuseoSans-500", size: 16)
        menuView.cellSeparatorColor = UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
        menuView.cellTextLabelAlignment = .center // .center // .right // .left
        menuView.selectedCellTextLabelColor = UIColor.white
        menuView.arrowPadding = 15
        menuView.animationDuration = 0.5
        menuView.maskBackgroundColor = UIColor.black
        menuView.maskBackgroundOpacity = 0.3
        menuView.didSelectItemAtIndexHandler = {(menuPath: Int) -> () in
            print("Did select item at index: \(menuPath)")
            self.menuIndex = menuPath
            self.fetchEncounters()
        }
        self.navigationItem.titleView = menuView
        
        // Create the Report Encounter VC and Present
        if selectedImage != nil {
            let stb = UIStoryboard(name: "UploadPicture", bundle: nil)
            let photoInfo = stb.instantiateViewController(withIdentifier: "photoInfo") as! PhotoInformationViewController
            self.present(photoInfo, animated: true, completion: nil)
        }
    }
    
    // MARK: - View Did Appear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: "walkthroughPresented") {
            
            showWalkthrough()
            
            userDefaults.set(true, forKey: "walkthroughPresented")
            userDefaults.synchronize()
        }
    }
    
    // MARK: - IBActions
    @IBAction func uploadImageButtonPressed(_ sender: UIBarButtonItem) {
        
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: "uploadInstructions") {
            
            showInstructions()
            
            userDefaults.set(true, forKey: "uploadInstructions")
            userDefaults.synchronize()
        } else {
            showUploadPicture()
        }
        
    }
    
    // MARK: - Functions
    func showWalkthrough() {
        let stb = UIStoryboard(name: "Walkthrough", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "container") as! BWWalkthroughViewController
        
        // Get view controllers and build the walkthrough
        let page_one = stb.instantiateViewController(withIdentifier: "page_1")
        let page_two = stb.instantiateViewController(withIdentifier: "page_2")
        let page_three = stb.instantiateViewController(withIdentifier: "page_3")
        
        // Attach the pages to the master
        walkthrough.delegate = self
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func showUploadPicture() {
        let fusuma = FusumaViewController()
        
        //        fusumaCropImage = false
        fusuma.delegate = self
        fusuma.cropHeightRatio = 1
        fusuma.hasVideo = false
        fusumaTintColor = UIColor(red: 80.0/255.0, green: 191.0/255.0, blue: 195.0/255.0, alpha: 1)
        fusumaBackgroundColor = UIColor(red: 66.0/255.0, green: 66.0/255.0, blue: 66.0/255.0, alpha: 1)
        self.present(fusuma, animated: true, completion: nil)
    }
    
    func showInstructions() {
        let stb = UIStoryboard(name: "UploadWalkthrough", bundle: nil)
        uploadWalkthrough = stb.instantiateViewController(withIdentifier: "container") as! BWWalkthroughViewController
        
        // Get view controllers and build the walkthrough
        let page_one = stb.instantiateViewController(withIdentifier: "page_1")
        let page_two = stb.instantiateViewController(withIdentifier: "page_2")
        let page_three = stb.instantiateViewController(withIdentifier: "page_3")
        let page_four = stb.instantiateViewController(withIdentifier: "page_4")
        
        // Attach the pages to the master
        uploadWalkthrough.delegate = self
        uploadWalkthrough.add(viewController:page_one)
        uploadWalkthrough.add(viewController:page_two)
        uploadWalkthrough.add(viewController:page_three)
        uploadWalkthrough.add(viewController:page_four)
        
        self.present(uploadWalkthrough, animated: true, completion: nil)
    }
    
    // Convert date from date string and subtract from current date
    func convertDate(encounterDate: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = dateFormatter.date(from: encounterDate)
        
        let currentDate = Date()
        let calendar = NSCalendar.current
        let dayOfEncounter = calendar.startOfDay(for: date!)
        let today = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: dayOfEncounter, to: today)
        
        return String(describing: components.day!)
    }
    
    
    // MARK: - Name
    var tabResults = [AnyObject]()
    
    // MARK: - Encounter filters
    func fetchEncounters() {
        self.getEncounterIds(index:menuIndex, onCompletion: { (ids) in
            if self.menuIndex == 1 {
                self.likedEncounters = ids
            }
            self.getEncountersWith(ids: ids)
        })
    }
    
    func getEncounterIds(index:Int, onCompletion: @escaping EncounterCallback){
        var type = ""
        
        if index == 0{
            onCompletion([])
            return
        }else if index == 1 {
            type = "liked_encounters"
        }else if index == 2 {
            type = "my_encounters"
        }
        
        Database.database().reference().child("users").child(Auth.auth().currentUser!.providerID).child(type).observeSingleEvent(of: .value, with: { (snapshot) in
            var myEncounters = [String]()
            if let db = snapshot.value as? [String: Any]{
                for rest in db {
                    myEncounters.append(rest.key)
                }
            }
            onCompletion(myEncounters)
        })
    }
    
    func getEncountersWith(ids:[String]){
        // Firebase tableview data
        Database.database().reference().child("encounters").observeSingleEvent(of: .value, with: { (snapshot) in
            self.encounters = []
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                guard let restDict = rest.value as? [String: Any] else { continue }
                let enID = restDict["id"] as! String
                
                if (ids.contains(enID) || self.menuIndex == 0){
                    let encounter = Encounter()
                    encounter.ID = (restDict["id"] as? String)!
                    encounter.sharkName = (restDict["shark_name"] as? String)!
                    encounter.date = (restDict["trip_date"] as? String)!
                    encounter.length = (restDict["length_est"] as? String)!
                    encounter.locationName = (restDict["location_name"] as? String)!
                    encounter.contributorName = (restDict["contributor"] as? String)!
                    encounter.contributorImage = (restDict["contributor_image"] as? String)!
                    
                    let mediaDict = restDict["media"] as! [[String:Any]]
                    encounter.images = mediaDict.flatMap { $0["thumb_url"] as? String }
                    
                    self.encounters.append(encounter)
                }
                self.tableView.reloadData()
            }
        })
    }
    
    func showLikedEncounters() {
        self.tableView.reloadData()
    }
    
    func showMyEncounters() {
        self.tableView.reloadData()
    }
    
    // MARK: - Walkthrough delegate -
    func walkthroughPageDidChange(_ pageNumber: Int) {
        print("Current Page \(pageNumber)")
        if (self.uploadWalkthrough != nil){
        if (self.uploadWalkthrough.numberOfPages - 1) == pageNumber {
            self.uploadWalkthrough.closeButton?.isHidden = false
        } else {
            self.uploadWalkthrough.closeButton?.isHidden = true
        }
        }
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: FusumaDelegate Protocol
    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        
        self.selectedImage = image
        
        let stb = UIStoryboard(name: "UploadPicture", bundle: nil)
        let photoInfo = stb.instantiateViewController(withIdentifier: "photoInfo") as! PhotoInformationViewController
        self.dismiss(animated: true, completion: nil)
        self.present(photoInfo, animated: true, completion: nil)
        
        print(image)
        print("Image selected")
    }
    
    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(image: UIImage) {
        
        print("Called just after FusumaViewController is dismissed.")
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        
        print("Called just after a video has been selected.")
    }
    
    // When camera roll is not authorized, this method is called.
    func fusumaCameraRollUnauthorized() {
        
        print("Camera roll unauthorized")
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return encounters.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "encounterCell", for: indexPath) as! EncounterTableViewCell
        let encounter = encounters[indexPath.row]
        cell.sharkNameLabel.text = encounter.sharkName
        cell.dateSeenLabel.text = "Spotted " + convertDate(encounterDate: encounter.date) + " days ago"
        cell.sharkImageView.sd_setImage(with: URL(string: encounter.images.first!))
        cell.contributorImageView.sd_setImage(with: URL(string: encounter.contributorImage))
        cell.likeButton.tag = indexPath.row
        cell.likeButton.isSelected = self.likedEncounters.contains(encounter.ID)
        cell.likeButton.addTarget(self, action: #selector(likeButtonPressed(_:)), for: .touchUpInside)
        
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToEncounterCard" {
            let destination = segue.destination as! EncounterDetailViewController
            if let indexPath = self.tableView.indexPathForSelectedRow {
                destination.selectedEncounter = self.encounters[indexPath.row]
            }
        }
    }

    
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let encounter = encounters[sender.tag]
        Database.database().reference().child("users").child(Auth.auth().currentUser!.providerID).child("liked_encounters").observeSingleEvent(of: .value, with: { (snapshot) in
            var isExist = false
            var i = 0
            self.likedEncounters = [String]()
            var likes = [String:Bool]()
            
            if let db = snapshot.value as? [String: Any]{
                for rest in db {
                    if rest.key == encounter.ID{
                        isExist = true
                    }else{
                        likes[rest.key] = true
                    }
                    if !self.likedEncounters.contains(rest.key){
                        self.likedEncounters.append(rest.key)
                    }
                    i += 1
                }
            }
            if isExist == false{
                likes[encounter.ID] = true
            }else{
                if let index = self.likedEncounters.index(of: encounter.ID) {
                    self.likedEncounters.remove(at: index)
                }
            }
            
            Database.database().reference().child("users").child(Auth.auth().currentUser!.providerID).child("liked_encounters").setValue(likes, withCompletionBlock: { (error, db) in
                if let error = error {
                    print("Like error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Like Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.tableView.reloadData()
                }
            })
        })
    }
}
