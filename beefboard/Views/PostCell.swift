//
//  PostCell.swift
//  beefboard
//
//  Created by Oliver on 27/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import Kingfisher
import SwiftMoment

class PostCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    static let identifier = "postCell"
    
    func configureCell(with post: Post) {
        self.titleLabel.text = post.title
        self.contentLabel.text = post.content
        self.authorLabel.text = post.author
        self.dateLabel.text = moment(post.date).fromNow()
        
        if post.numImages > 0 {
            self.mainImage.contentMode = .scaleAspectFill
            self.mainImage.clipsToBounds = true
            self.mainImage.kf.indicatorType = .activity
            let imageResource = ImageResource(
                downloadURL: URL(
                    string: BeefboardApi.getImageUrl(forPost: post.id, forImage: 0)
                )!,
                cacheKey:"\(post.id)0"
            )
            self.mainImage.kf.setImage(with: imageResource)
            self.imageHeight.constant = 200
        } else {
            self.mainImage.kf.setImage(with: nil)
            self.imageHeight.constant = 30
        }
    }
}

