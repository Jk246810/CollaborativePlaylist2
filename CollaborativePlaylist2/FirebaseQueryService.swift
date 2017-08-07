//
//  FirebaseQueryService.swift
//  CollaborativePlaylist2
//
//  Created by Brian on 8/2/17.
//  Copyright © 2017 jamee. All rights reserved.
//

import Foundation
import Firebase

final class FirebaseQueryService {
    static let I = FirebaseQueryService()
    let db = Database.database().reference()
    
    func getSongs(for playlist: Playlist) -> DatabaseQuery? {
        guard let playlistId = playlist.id else { return nil }
        let query = db.child("music/\(playlistId)").queryOrdered(byChild: "name")
        
            //.queryOrdered(byChild: "name")
        return query
    }
    
    
}
