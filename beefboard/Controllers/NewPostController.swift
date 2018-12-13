//
//  NewPostController.swift
//  beefboard
//
//  Created by Oliver on 24/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit
import ImageSlideshow
import AVFoundation
import Photos
import OpalImagePicker
import BSImagePicker
import JGProgressHUD

class NewPostController: UIViewController {
    var images: [UIImage] = []
    var hud: JGProgressHUD? = nil
    var uploading = false
    
    let postsDataModel = PostsDataModel()
    
    var textViewPlaceholder = false

    @IBOutlet weak var imageSlideshow: ImageSlideshow!
    @IBOutlet weak var slideshowHeight: NSLayoutConstraint!
    
    @IBOutlet weak var postTitle: UITextField!
    @IBOutlet weak var postContent: UITextView!
    
    @IBOutlet weak var bottomBar: UIToolbar!
    
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    @IBAction func cancelAction(_ sender: Any) {
        self.showCancelDialog()
    }
    @IBAction func postAction(_ sender: Any) {
        self.createPost()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup callbacks
        self.postsDataModel.delegate = self
        self.postContent.delegate = self
        
        // Update the UI to the initial state
        self.handlePhotosUpdated()
        self.handleValidatePost()
        self.showContentPlaceholder()
        
        self.postTitle.addTarget(
            self,
            action: #selector(self.handleValidatePost),
            for: .editingChanged
        )
    }
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        // Convert an asset to a UIImage
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
    
    func createProgressHud() {
        // Create a HUD showing progress
        // of post upload
        self.hud = JGProgressHUD(style: .light)
        self.hud?.vibrancyEnabled = true
        if arc4random_uniform(2) == 0 {
            self.hud?.indicatorView = JGProgressHUDPieIndicatorView()
        }
        else {
            self.hud?.indicatorView = JGProgressHUDRingIndicatorView()
        }
        self.hud?.detailTextLabel.text = "0% Complete"
        self.hud?.textLabel.text = "Uploading"
        self.hud?.show(in: self.view)
    }
    
    func createPost() {
        self.uploading = true
        self.createProgressHud()
        self.postsDataModel.createPost(
            title: self.postTitle.text!,
            content: self.postContent.text!,
            images: self.images
        )
    }
    
    func showCancelDialog() {
        // Show a cancel dialog before allowing
        // user to leave
        let dialog = UIAlertController(title: "Cancel creation", message: "Are you sure you want to leave?", preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            }
        ))
        dialog.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(dialog, animated: true, completion: nil)
    }
    
    func showContentPlaceholder() {
        // Make placeholder text for content textView
        self.textViewPlaceholder = true
        self.postContent!.text = "Type something here..."
        self.postContent!.textColor = UIColor.lightGray
    }
    
    func handlePhotosUpdated() {
        // When the selected images are updated
        // we need to handle updating the UI
        if self.images.count < 1 {
            self.slideshowHeight.constant = 0
        } else {
            self.slideshowHeight.constant = 150
        }
        
        var imageSources: [ImageSource] = []
        for image in self.images {
            imageSources.append(ImageSource(image: image))
        }
        
        self.imageSlideshow.setImageInputs(imageSources)
        self.handleBottomBar()
    }
    
    @objc func handleValidatePost() {
        // Validate if post can be clicked (Title and content)
        print(self.postContent.text)
        self.postButton.isEnabled =
            self.postTitle!.text!.count > 0
            && !self.textViewPlaceholder
            && self.postContent.text!.count > 0
            && !self.uploading
    }
    
    func handleBottomBar() {
        // Handle setting items on
        // the bottom bar correctly
        // (clear if images are attached, otherwise attach button)
        self.bottomBar!.items?.removeAll()
        self.bottomBar!.items?.append(
            UIBarButtonItem(
                barButtonSystemItem: .camera,
                target: nil,
                action: #selector(self.attachClicked)
            )
        )

        if self.images.count > 0 {
            self.bottomBar!.items?.append(
                UIBarButtonItem(
                    title: "Clear photos",
                    style: .done,
                    target: nil,
                    action: #selector(self.clearAttachments)
                )
            )
        }
        
    }
    
    func openPhotoPicker() {
        // Open the gallery picker
        bs_presentImagePickerController(
            BSImagePickerViewController(),
            animated: true,
            select: nil,
            deselect: nil,
            cancel: { (assets: [PHAsset]) -> Void in
                // User cancelled. And this where the assets currently selected.
            },
            finish: { (assets: [PHAsset]) -> Void in
                for asset in assets {
                    self.images.append(self.getUIImage(asset: asset)!)
                }
                DispatchQueue.main.async {
                    self.handlePhotosUpdated()
                }
            },
            completion: nil
        )
    }
    
    /**
    Open the camera UI and allow a photo to be picked
    **/
    func openCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    @objc
    func attachClicked() {
        // Add photos clicked, so
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        let camera = !discoverySession.devices.isEmpty
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Photos",
            style: .default,
            handler: { (value: UIAlertAction) in
                self.openPhotoPicker()
            }
        ))
        
        if camera {
            actionSheet.addAction(UIAlertAction(
                title: "Camera",
                style: .default,
                handler: { (value: UIAlertAction) in
                    self.openCamera()
            }
            ))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @objc
    func clearAttachments() {
        // Clear the current attachments
        self.images.removeAll()
        self.handlePhotosUpdated()
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

// Handle image picker
extension NewPostController: OpalImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true, completion: nil)
        let newImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        self.images.append(newImage)
    }
}

/**
 Handle all PostDataModel callbacks
 **/
extension NewPostController: PostsDataModelDelegate {
    func didRecievePosts(posts: [Post], pinnedPosts: [Post]) {}
    func didFailReceive(with error: ApiError) {}
    
    func didCreatePost(post: Post) {
        // When post is created, we should dismiss the
        // progress dialog, and then present the new post
        // in its own UI.
        self.hud?.dismiss()
        self.hud = nil
        
        weak var pvc = self.presentingViewController
        
        self.dismiss(animated: true, completion: {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let view = storyBoard.instantiateViewController(withIdentifier: "postDetails") as! PostDetailsController
            view.isNew = true
            view.post = post
            
            let navController = UINavigationController(rootViewController: view)
            pvc?.present(navController, animated: true, completion: nil)
        })
    }
    
    // When we receive progress, update HUD
    func didCreatePostProgress(progress: Double) {
        self.hud?.progress = Float(progress * 100)
        self.hud?.detailTextLabel.text = "\(progress)% Complete"
    }
    
    func didFailCreatePost(with error: ApiError) {
        self.uploading = false
    }
}

// Handle textview placeholders
extension NewPostController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textViewPlaceholder {
            self.textViewPlaceholder = false
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            self.showContentPlaceholder()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Check if the form is valid when text
        // changes
        self.handleValidatePost()
    }
}
