//
//  PostsController.swift
//  beefboard
//
//  Created by Oliver on 02/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import AwaitKit
import Kingfisher

class PostCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
}

class PostsController: UITableViewController {
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    var posts: [Post] = []
    var pinnedPosts: [Post] = []
    var auth: User?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadAuth()
        self.loadPosts()
    }
    
    func presentView(of viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func showLogin() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let view = storyBoard.instantiateViewController(withIdentifier: "loginView") as! LoginController
        self.presentView(of: view)
    }
    
    @objc func showProfile() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let view = storyBoard.instantiateViewController(withIdentifier: "profileView") as! ProfileController
        view.details = self.auth
        view.isMe = true
        self.presentView(of: view)
    }
    
    func loadPosts() {
        async {
            var allPosts: [Post] = []
            do {
                allPosts = try await(BeefboardApi.getPosts())
            } catch (let error as ApiError) {
                print(error)
                return
            }
            
            self.pinnedPosts = []
            self.posts = []
            
            for post in allPosts {
                if post.pinned {
                    self.pinnedPosts.append(post)
                } else {
                    self.posts.append(post)
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func loadAuth() {
        if !BeefboardApi.hasToken() {
            self.showLoginAction()
            return
        }
        
        self.showBusyAction()
        print("Starting async")
        async {
            print("Getting auth")
            do {
                self.auth = try await(BeefboardApi.getAuth())
            } catch (let error as ApiError) {
                print("wtf")
                if error == ApiError.invalidCredentials {
                    BeefboardApi.clearToken()
                    self.auth = nil
                } else {
                    print(error)
                }
            }
            
            print("Got auth")
            
            DispatchQueue.main.async {
                if self.auth == nil {
                    print("Showing login button")
                    self.showLoginAction()
                } else {
                    self.showProfileAction()
                }
            }
        }
    }
    
    func showBusyAction() {
        let uiBusy = UIActivityIndicatorView(style: .white)
        uiBusy.hidesWhenStopped = true
        uiBusy.startAnimating()
        self.navigationBar.rightBarButtonItem = UIBarButtonItem(customView: uiBusy)
    }
    
    func showLoginAction() {
        let loginAction = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(self.showLogin))
        self.navigationBar.rightBarButtonItem = loginAction
    }
    
    func showProfileAction() {
        let profileAction = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(self.showProfile))
        self.navigationBar.rightBarButtonItem = profileAction
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Sort By"
        default:
            return "Filter"
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0:
            return self.pinnedPosts.count
        default:
            return self.posts.count
        }
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PostCell
        
        print("Populating: \(indexPath.row)")
        
        var post: Post? = nil
        switch(indexPath.section) {
        case 0:
            post = self.pinnedPosts[indexPath.row]
        default:
            post = self.posts[indexPath.row]
        }
        
        print(post!.title)
        
        cell.titleLabel?.text = post!.title
        cell.contentLabel?.text = post!.content
        cell.authorLabel?.text = post!.author
        print(post!.numImages)
        if post!.numImages > 0 {
            cell.mainImage.kf.indicatorType = .activity
            cell.mainImage.kf.setImage(with: URL(string: "https://api.beefboard.mooo.com/v1/posts/\(post!.id)/images/0"))
        }
        
        // Configure the cell...

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
