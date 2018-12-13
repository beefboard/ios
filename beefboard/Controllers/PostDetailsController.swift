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

class PostDetailsController: UIViewController {
    // The details of the post we are going to display
    var post: Post?
    
    // Is this a new post
    var isNew = false
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var slideshowHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var imageSlideshow: ImageSlideshow!
    
    @IBOutlet weak var viewPhotosButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.isNew {
            super.viewDidLoad()
            let backbutton = UIButton(type: .custom)
            backbutton.setTitle("Close", for: .normal)
            backbutton.setTitleColor(backbutton.tintColor, for: .normal)
            backbutton.addTarget(
                self,
                action: #selector(self.closeAction),
                for: .touchUpInside
            )
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backbutton)
        }
        
        self.fillDetails()
    }
    
    @objc
    func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func fillDetails() {
        if let postDetails = self.post {
            self.titleLabel.text = postDetails.title
            self.contentLabel.text = postDetails.content
            
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
                self.slideshowHeight.constant = 0
            }
            
            self.resizeView()
        }
    }
    
    func resizeView() {
        
        self.contentLabel.sizeToFit()
        var height = self.slideshowHeight.constant;
        height += self.titleLabel.frame.height + 16
        height += self.dateLabel.frame.height + 16
        height += self.contentLabel.frame.height + 16
        
        
        
        let size = CGSize(width: self.contentView.frame.width, height: height)
        self.contentView.frame.size = size
        self.scrollView.contentSize = size
        print(size.height)
    }
}
