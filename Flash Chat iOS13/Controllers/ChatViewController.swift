//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = K.titleText
        navigationItem.hidesBackButton = true
        
        tableView.dataSource = self;
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        //loadMessages()
        addListener()

        
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField: messageSender,
                                                                      K.FStore.bodyField: messageBody,
                                                                      K.FStore.dateField: Date().timeIntervalSince1970]) { (error) in
                if let e = error {
                    print("There was an issue: \(e)")
                } else {
                    print("Data has been succesfully saved!")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                
                }
            }
            
        }
        
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
    func addListener() {
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { querySnapshot, error in
            self.messages = []
            if let e = error {
                print("Error fetching document: \(e)")
                return
            }
            
            if let documents = querySnapshot?.documents {
                for document in documents {
                    let data = document.data()
                    if let sender = data[K.FStore.senderField] as? String, let body = data[K.FStore.bodyField] as? String {
                        let message = Message(sender: sender, body: body)
                        self.messages.append(message)
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
            
        }
    }
    
}

//MARK: - UITableViewSource Extension
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        if let currentUser = Auth.auth().currentUser?.email {
            
            if currentUser == message.sender {
                cell.leftImageVIew.isHidden = true;
                cell.rightImageView.isHidden = false;
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
                cell.messageLabel.textColor = UIColor(named: K.BrandColors.purple)
            } else {
                cell.rightImageView.isHidden = true;
                cell.leftImageVIew.isHidden = false;
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
                cell.messageLabel.textColor = UIColor(named: K.BrandColors.lightPurple)
            }
            cell.messageLabel.text = message.body
        }
        
        cell.messageLabel.text = message.body
        return cell
    }
}
