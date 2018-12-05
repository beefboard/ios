//
//  PostsController.swift
//
// The "main" page of Beefboard, shows a list
// of posts in chronological order
//
//
//  Created by Oliver on 02/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import PromiseKit
import AwaitKit

class PostsController: UITableViewController {
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    private var postsDataSource = PostsDataModel()
    private var authSource = AuthModel()
    
    private var auth: User?
    
    private var pinnedPosts: [Post] = []
    private var posts: [Post] = []
    
    private var refresher: UIRefreshControl?
    private var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.postsDataSource.delegate = self
        self.authSource.delegate = self
        
        self.refreshControl?.addTarget(self, action: #selector(PostsController.refreshPosts(refreshControl:)), for: UIControl.Event.valueChanged)
        
        self.activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        self.activityIndicator.color = UIColor.darkGray
        self.activityIndicator.center = self.tableView.center
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.stopAnimating()
        self.navigationController?.view.addSubview(activityIndicator)
        
        self.showBarItemsBusy()
        self.postsDataSource.refreshPosts()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.authSource.retrieveAuth()
    }
    
    func presentView(of viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc func openCreate() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let view = storyBoard.instantiateViewController(withIdentifier: "newPost") as! NewPostController
        self.presentView(of: view)
    }
    
    @objc func openLogin() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let view = storyBoard.instantiateViewController(withIdentifier: "loginView") as! LoginController
        self.presentView(of: view)
    }
    
    @objc func openProfile() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let view = storyBoard.instantiateViewController(withIdentifier: "profileView") as! ProfileController
        view.details = self.auth
        view.isMe = true
        self.presentView(of: view)
    }
    
    @objc func refreshPosts(refreshControl: UIRefreshControl) {
        self.refresher = refreshControl
        self.postsDataSource.refreshPosts(excludingCache: true)
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: false, completion: nil)
    }
    
    func showBarItemsBusy() {
        let uiBusy = UIActivityIndicatorView(style: .white)
        uiBusy.hidesWhenStopped = true
        uiBusy.startAnimating()
        self.navigationBar.leftBarButtonItem = UIBarButtonItem(customView: uiBusy)
        self.navigationBar.rightBarButtonItem = nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        print("Getting header for \(section)")
        switch section {
        case 0:
            return "Pinned"
        default:
            return "Posts"
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
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as! PostCell
        
        var post: Post? = nil
        switch(indexPath.section) {
        case 0:
            post = self.pinnedPosts[indexPath.row]
        default:
            post = self.posts[indexPath.row]
        }
        
        cell.configureCell(with: post!)

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openPost" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let navigationController = segue.destination as? UINavigationController {
                    if let postDetailsController = navigationController.topViewController as? PostDetailsController {
                        let posts = indexPath.section == 0 ? self.pinnedPosts : self.posts
                        postDetailsController.post = posts[indexPath.row]
                    }
                }
            }
        }
    }

}


extension PostsController: PostsDataModelDelegate {
    
    func stopLoadingIcons() {
        self.activityIndicator.stopAnimating()
        // Stop the refresh icon, if it exists
        self.refresher?.endRefreshing()
        self.refresher = nil
    }
    
    func didRecievePosts(posts: [Post], pinnedPosts: [Post]) {
        self.stopLoadingIcons()
        
        self.posts = posts
        self.pinnedPosts = pinnedPosts
        self.tableView.reloadData()
    }
    
    func didFailReceiveWithError(error: ApiError) {
        self.stopLoadingIcons()
        
        switch (error) {
        case ApiError.connectionError:
            self.showError(title: "Could not load posts", message: "Connection error")
        default:
            self.showError(title: "Could not load posts", message: "Unknown error")
        }
    }
}

extension PostsController: AuthModelDelegate {
    func showLoginAction() {
        let loginAction = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(PostsController.openLogin))
        self.navigationBar.leftBarButtonItem = loginAction
        self.navigationBar.rightBarButtonItem = nil
    }
    
    func showProfileAction() {
        let profileAction = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(PostsController.openProfile))
        self.navigationBar.leftBarButtonItem = profileAction
    }
    
    func showAddAction() {
        let profileAction = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(PostsController.openCreate))
        self.navigationBar.rightBarButtonItem = profileAction
    }
    
    func didReceiveAuth(auth: User?) {
        self.auth = auth
        
        print("Recieived auth: \(auth)")
        
        if auth == nil {
            self.showLoginAction()
        } else {
            self.showProfileAction()
            self.showAddAction()
        }
    }
    
    func didReceiveAuthError(error: ApiError) {
        
        switch (error) {
        case ApiError.connectionError:
            return
        default:
            return
        }
    }
}
