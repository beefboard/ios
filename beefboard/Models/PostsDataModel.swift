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
    func didFailReceive(with error: ApiError)
    
    func didCreatePost(post: Post)
    func didCreatePostProgress(progress: Double)
    func didFailCreatePost(with error: ApiError)
}

/**
 * Model for handling all data related
 * to posts.
 *
 * Makes callbacks to given delegate
 */
class PostsDataModel {
    weak var delegate: PostsDataModelDelegate?
    
    let dataContext: NSManagedObjectContext
    
    init() {
        // Bind our CoreData on initialisation
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.dataContext = appDelegate.persistentContainer.viewContext
    }
    
    /**
     * Sort given posts list and notify delegate
     */
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
    
    /**
     * Refresh the posts lists, ommiting first from cache
     * and then from API once data has been received
     */
    func refreshPosts(excludingCache: Bool = false) {
        // Notify cache first, unless excluded
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
            } catch let error as ApiError {
                DispatchQueue.main.async {
                    self.delegate?.didFailReceive(with: error)
                }
                return
            }
            
            // save the set of posts and notify
            DispatchQueue.main.async {
                self.cachePosts(posts: allPosts)
                self.notifyPosts(allPosts)
            }
        }
    }
    
    /**
     * Send post creation request to API with given data
     *
     * Ommits didCreatePostProgress and didCreatePost
     */
    func createPost(title: String, content: String, images: [UIImage]) {
        // Create a new post by sending the data to the API.
        // new posts 
        async {
            do {
                let id = try await(
                    BeefboardApi.newPost(
                        title: title,
                        content: content,
                        images: images,
                        progressHandler: { (progress) in
                            DispatchQueue.main.async {
                                self.delegate?.didCreatePostProgress(progress: progress)
                            }
                        }
                    )
                )
                let post = try await(BeefboardApi.getPost(id: id))
                DispatchQueue.main.async {
                    self.delegate?.didCreatePost(post: post)
                }
                
            } catch let error as ApiError {
                DispatchQueue.main.async {
                    self.delegate?.didFailCreatePost(with: error)
                }
            }
        }
    }
    
    func pinPost(id: String, pin: Bool) {
        
    }
    
    private func loadCache() -> [Post] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PostsData")
        request.returnsObjectsAsFaults = false
        
        var posts: [Post] = []
        
        do {
            let result = try self.dataContext.fetch(request)
            for data in result as! [PostsData] {
                if let id = data.id?.uuidString {
                    let post = Post(
                        id: id,
                        title: data.title!,
                        content: data.content!,
                        author: data.author!,
                        date: data.date!,
                        numImages: Int(data.numImages),
                        approved: data.approved,
                        pinned: data.pinned,
                        votes: PostVotes(
                            grade: Int(data.grade),
                            user: Int(data.userGrade)
                        )
                    )
                    
                    posts.append(post)
                }
            }
            
        } catch {
            print("Failed")
        }
        
        print("Loaded \(posts.count) posts from cache")
        
        return posts
    }
    
    private func cachePosts(posts: [Post]) {
        // Remove old cache
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PostsData")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? self.dataContext.execute(request)
        
        let entity = NSEntityDescription.entity(forEntityName: "PostsData", in: self.dataContext)
        
        for post in posts {
            let postEntry = NSManagedObject(entity: entity!, insertInto: self.dataContext) as! PostsData
            postEntry.id = UUID(uuidString: post.id)
            postEntry.title = post.title
            postEntry.content = post.content
            postEntry.date = post.date
            postEntry.author = post.author
            postEntry.numImages = Int16(post.numImages)
            postEntry.approved = post.approved
            postEntry.pinned = post.pinned
            postEntry.grade = Int16(post.votes.grade)
            if let userGrade = post.votes.user {
                postEntry.userGrade = Int16(userGrade)
            } else {
                postEntry.userGrade = 0
            }
        }
    }
}
