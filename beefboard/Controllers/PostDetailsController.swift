//
//  PostDetailsController.swift
//  beefboard
//
//  Created by Oliver on 02/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import ImageSlideshow
import Kingfisher
import SwiftMoment

/**
 * View controller for PostDetails
 */
class PostDetailsController: UIViewController {
    // The details of the post we are going to display
    var post: Post?
    private var auth: User?
    
    // Is this a new post
    var isNew = false
    
    // Can we delete, approve or pin post
    let authModel = AuthModel()
    let profilesModel = ProfilesModel()
    let postsDataModel = PostsDataModel()
    
    // Bind to view
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var slideshowHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var contentLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var imageSlideshow: ImageSlideshow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationItem.largeTitleDisplayMode = .never
        
        self.profilesModel.delegate = self
        self.authModel.delegate = self
        self.postsDataModel.delegate = self
        
        // Get our current auth details, to see
        // if we are able to delete or pin posts
        self.authModel.retrieveAuth()
        
        // Make a close button if this is a view
        // showing a "new" post
        if self.isNew {
            let closeButton = self.generateButton(
                title: NSLocalizedString("Close", comment: "")
            )
            closeButton.addTarget(
                self,
                action: #selector(self.closeAction),
                for: .touchUpInside
            )
      
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
            self.title = NSLocalizedString("Awaiting approval", comment: "")
        }
        
        self.fillDetails()
    }
    
    @objc
    func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func openProfileAction() {
        self.profilesModel.retrieveDetails(username: self.post!.author)
    }
    
    @objc
    func handleDeleteAction() {
        let alert = UIAlertController(
            title: NSLocalizedString("Delete?", comment: ""),
            message: NSLocalizedString("Are you sure you want to delete this post?", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Yes", comment: ""),
                style: .destructive,
                handler: { (UIAlertAction) in
                    self.postsDataModel.deletePost(id: self.post!.id)
            }
            )
        )
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    func handlePinAction() {
        // Set the post to the opposite of the current pin
        self.postsDataModel.setPostPinned(id: self.post!.id, pinned: !self.post!.pinned)
    }
    
    private func generateButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        return button
    }
    
    /**
     * Fill in the details of the provided post
     */
    func fillDetails() {
        // Unwrap
        if let postDetails = self.post {
            self.titleLabel.text = postDetails.title
            self.dateLabel.text = moment(postDetails.date).format("MMMM dd YYYY, hh:mm:ss")
            self.contentLabel.text = postDetails.content
            
            // Use KingFisher and ImageSlideshow
            // to create a slideshow of all images
            if postDetails.numImages > 0 {
                var imageSources = [KingfisherSource]()
                
                // Generate the urls for all the images based
                // on the number of images which the post has
                // uploaded
                for i in 0..<postDetails.numImages {
                    if let source = KingfisherSource(
                            urlString: BeefboardApi.getImageUrl(
                                forPost: postDetails.id,
                                forImage: i
                        )) {
                        imageSources.append(source)
                    }
                }
                
                self.imageSlideshow.setImageInputs(imageSources)
            } else {
                // If no images, don't show slideshow on page
                self.slideshowHeight.constant = 0
            }
            
            // Create a profile button to link to users profile
            let profileButton = self.generateButton(title: "\(postDetails.author)'s profile")
            profileButton.addTarget(
                self,
                action: #selector(self.openProfileAction),
                for: .touchUpInside
            )
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: profileButton)
            
            // Fix scrolling
            DispatchQueue.main.async {
                self.resizeView()
            }
        }
    }
    
    /**
     * Resize view in scrollview
     */
    func resizeView() {
        self.contentLabel.sizeToFit()
        var height = self.slideshowHeight.constant;
        height += self.titleLabel.frame.height + 16
        height += self.dateLabel.frame.height + 16
        height += self.contentLabel.frame.height + 16
        
        self.contentLabelHeight.constant = self.contentLabel.frame.height + 16
        
        let size = CGSize(width: self.contentView.frame.width, height: height)
        self.contentView.frame.size = size
        self.scrollView.contentSize = size
    }
    
    func updateToolbar() {
        // Show the toolbar only if the current
        // user is an admin or is the post owner
        if let authDetails = self.auth {
            if let postDetails = self.post {
                if !authDetails.admin && authDetails.username != postDetails.author {
                    self.navigationController?.setToolbarHidden(true, animated: false)
                } else {
                    self.navigationController?.setToolbarHidden(false, animated: false)
                }
                
                var toolbarItems: [UIBarButtonItem] = []
                
                // Allow delete if owner or admin
                if authDetails.admin || authDetails.username == postDetails.author {
                    toolbarItems.append(UIBarButtonItem(
                        barButtonSystemItem: .trash,
                        target: self,
                        action:  #selector(self.handleDeleteAction)
                    ))
                }
                
                if authDetails.admin {
                    var pinText = "Pin"
                    if postDetails.pinned {
                        pinText = "Unpin"
                    }
                    
                    toolbarItems.append(UIBarButtonItem(
                        title: pinText,
                        style: .plain,
                        target: self,
                        action: #selector(self.handlePinAction))
                    )
                }
                
                self.setToolbarItems(toolbarItems, animated: false)
            }
        }
    }
}

/**
 * Extension to handle viewing a users profile
 */
extension PostDetailsController: ProfilesModelDelegate {
    
    private func showError(description: String) {
        let alert = UIAlertController(
            title: "Profile retrieval error",
            message: description,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func didReceiveProfileDetails(user: User?) {
        // Open the users profile if we got their details
        if let userDetails = user {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyBoard.instantiateViewController(withIdentifier: "profileView") as! ProfileController
            
            view.details = userDetails
            view.isMe = false
            
            let navController = UINavigationController(rootViewController: view)
            self.present(navController, animated: true, completion: nil)
        } else {
            // Handle error
        }
    }
    
    func didReceiveProfileDetailsError(error: ApiError) {
        // Handle error
    }
}

extension PostDetailsController: AuthModelDelegate {
    func didReceiveAuth(auth: User?) {
        self.auth = auth
        self.updateToolbar()
    }
    
    func didReceiveAuthError(error: ApiError) {}
}

extension PostDetailsController: PostsDataModelDelegate {
    func didRecievePosts(posts: [Post], pinnedPosts: [Post]) {}
    func didFailReceive(with error: ApiError) {}
    func didCreatePost(post: Post) {}
    func didCreatePostProgress(progress: Double) {}
    func didFailCreatePost(with error: ApiError) {}
    
    func didPinPost(pinned: Bool) {
        self.post!.pinned = pinned
        self.updateToolbar()
    }
    
    func didFailPinPost(with error: ApiError) {
        print(error)
    }
    
    /**
     * When a post is deleted, go back to home
     */
    func didDeletePost() {
        if !self.isNew {
            self.navigationController?.navigationController?.popViewController(animated: true)
        } else {
            self.closeAction()
        }
    }
    
    func didFailDeletePost(with error: ApiError) {
        print(error)
    }
}
