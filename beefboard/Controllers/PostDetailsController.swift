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
    
    var post: Post?
    
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
        
        
        self.fillDetails()
    }
    
    func fillDetails() {
        if let postDetails = self.post {
            self.titleLabel.text = postDetails.title
            self.contentLabel.text = postDetails.content
            
            if postDetails.numImages > 0 {
                var imageSources = [KingfisherSource]()
                
                for i in 0..<postDetails.numImages {
                    if let source = KingfisherSource(
                            urlString: BeefboardApi.getImageUrl(forPost: postDetails.id, forImage: i)
                        ) {
                        imageSources.append(source)
                    }
                }
                
                self.imageSlideshow.setImageInputs(imageSources)
            }
            
            self.resizeView()
        }
    }
    
    func resizeView() {
        var height = self.slideshowHeight.constant;
        height += self.titleLabel.frame.height + 16
        height += self.dateLabel.frame.height + 16
        height += self.contentLabel.frame.height + 16
        
        print(height)
        
        let size = CGSize(width: self.contentView.frame.width, height: height)
        self.contentView.frame.size = size
        self.scrollView.contentSize = size
    }
}
