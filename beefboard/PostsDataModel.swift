//
//  PostsManager.swift
//  beefboard
//
//  Created by Oliver on 26/11/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation
import AwaitKit
import CoreData

protocol PostsDataModelDelegate: class {
    func didRecievePosts(posts: [Post], pinnedPosts: [Post])
    func didFailReceiveWithError(error: ApiError)
}

class PostsDataModel {
    weak var delegate: PostsDataModelDelegate?
    
    let dataContext: NSManagedObjectContext
    
    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.dataContext = appDelegate.persistentContainer.viewContext
    }
    
    private func notifyPosts(_ postsList: [Post]) {
        var allPosts = postsList
        
        // Sort posts by date order
        allPosts.sort(by: { (post1, post2) -> Bool in
            return post1.date > post2.date
        })
        
        // Filter pinned posts from posts
        var pinnedPosts: [Post] = []
        var posts: [Post] = []
        
        for post in allPosts {
            if post.pinned {
                pinnedPosts.append(post)
            } else {
                posts.append(post)
            }
        }
        
        self.delegate?.didRecievePosts(posts: posts, pinnedPosts: pinnedPosts)
    }
    
    func refreshPosts(excludingCache: Bool = false) {
        if !excludingCache {
            let currentPosts = self.loadCache()
            if currentPosts.count > 0 {
                self.notifyPosts(currentPosts)
            }
        }
        
        async {
            var allPosts: [Post] = []
            do {
                allPosts = try await(BeefboardApi.getPosts())
            } catch is ApiError {
                return
            }
            
            // save the set of posts
            DispatchQueue.main.async {
                //self.cachePosts(posts: allPosts)
                self.notifyPosts(allPosts)
            }
        }
    }
    
    private func loadCache() -> [Post] {
        return []
    }
    
    private func cachePosts(posts: [Post]) {
        let entity = NSEntityDescription.entity(forEntityName: "PostsData", in: self.dataContext)
        
        for post in posts {
            let postEntry = NSManagedObject(entity: entity!, insertInto: self.dataContext)
            postEntry.setValue(post.id, forKey: "id")
            postEntry.setValue(post.title, forKey: "title")
            postEntry.setValue(post.content, forKey: "content")
            postEntry.setValue(post.date, forKey: "date")
            postEntry.setValue(post.author, forKey: "author")
            postEntry.setValue(post.numImages, forKey: "numImages")
            postEntry.setValue(post.approved, forKey: "approved")
            postEntry.setValue(post.pinned, forKey: "pinned")
            postEntry.setValue(post.votes.grade, forKey: "grade")
            postEntry.setValue(post.votes.user, forKey: "userGrade")
        }
    }
}
