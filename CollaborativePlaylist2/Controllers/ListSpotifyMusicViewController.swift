//
//  ListSpotifyMusicViewController.swift
//  CollaborativePlaylist2
//
//  Created by Brian on 7/31/17.
//  Copyright © 2017 jamee. All rights reserved.
//

import UIKit
import SafariServices
import Spartan

struct Post {
    let mainImage : UIImage
    let name: String
    let uri: String
    let mainImageURL: String
    
}

struct SongSelection {
    let post: Post
    let track: Track
}

class ListSpotifyMusicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate  {
    
    var songSelections = [SongSelection]()
    var playlist: Playlist?

    
    var auth = SPTAuth.defaultInstance()!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var LoginToSpotify: UIButton!
    
    @IBAction func LoginToSpotifyButtonTapped(_ sender: UIButton) {
        if UIApplication.shared.openURL(auth.spotifyWebAuthenticationURL()) {
            if auth.canHandle(auth.redirectURL) {
                            // To do - build in error handling
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(ListSpotifyMusicViewController.initializePlayer), name: NSNotification.Name(rawValue: "sessionUpdated"), object: nil)

        player = SPTAudioStreamingController.sharedInstance()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (auth.session != nil) {
            if (auth.session.isValid()) {
                self.LoginToSpotify.isHidden = true
                initializePlayer(authSession: auth.session)
            } else {
                self.LoginToSpotify.isHidden = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songSelections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotifySongsCell") as! SpotifySongsCell
        //let cell = tableView.dequeueReusableCell(withIdentifier: "songsTableViewCell", for: indexPath) as! songsTableViewCell
//        print("what's uppppppp")
        let songSelection = songSelections[indexPath.row]
        cell.nameLabel.text = songSelection.post.name
        cell.mainImageView.image = songSelection.post.mainImage
        
        
        
        return cell
        
    }


    
    func setup() {
        auth = SPTAuth.defaultInstance()
        auth.clientID = "27094f14e3b842d28bdffcc9d3f5d863"
        auth.redirectURL = URL(string: "collaborativePlaylist2://")
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserReadPrivateScope, SPTAuthUserLibraryModifyScope]
        loginUrl = auth.spotifyWebAuthenticationURL()
    }

    func initializePlayer(authSession:SPTSession){
        self.player!.playbackDelegate = self
        self.player!.delegate = self
        
        do {
            try player?.start(withClientId: auth.clientID)
        } catch {
            print("error")
        }
        
        self.player!.login(withAccessToken: authSession.accessToken)
    
        Spartan.authorizationToken = authSession.accessToken
        print("hello")
        Spartan.loggingEnabled = true
        
        _ = Spartan.getSavedTracks(limit: 20, offset: 0, market: .us, success: {(PagingObject) in
            print("number of playlists \(PagingObject.total)")
            for item in PagingObject.items {
                if let track = item.track, let name = track.name, let uri = track.uri {
                    let imageData = track.album.images[0]
                    
                    guard let url = URL(string: imageData.url) else { return }
                    guard let data = try? Data(contentsOf: url) else { return }
                    guard let mainImage = UIImage(data: data) else { return }
                    
                    let post = Post(mainImage: mainImage, name: name, uri: uri, mainImageURL: imageData.url)
                    let selection = SongSelection(post: post, track: track)
                    
                    let trackId = selection.track.id
                    
                    guard let playlist = self.playlist else {
                        return
                    }
                    
                    if !playlist.songs.contains(trackId!) {
                        self.songSelections.append(selection)
                    }
                }
            }

                self.tableView.reloadData()
        }, failure: { (error) in
            print(error)
        })
    }

    private func createSong(post: Post, playlist: Playlist, trackId: String) {
        MusicService.I.createSong(using: post,
                                  playlist: playlist,
                                  trackId: trackId)
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let identifier = segue.identifier {
            if identifier == "addSong" {
                if let cell = sender as? UITableViewCell {
                    
                    guard let indexPath = tableView.indexPath(for: cell) else { return }
                    let songSelection = songSelections[indexPath.row]
                    
                    self.playlist?.songs.append(songSelection.track.id)                    
                    guard let playlist = self.playlist else { return }
                    
                    guard let displayPlaylistViewController = segue.destination as? DisplayPlaylistViewController else { return }
                    
                    displayPlaylistViewController.selectedPlaylist = playlist
                    self.createSong(post: songSelection.post,
                                    playlist: playlist,
                                    trackId: songSelection.track.id)
                    
                }
                print ("hello")
            }
            
            
        }

       
    }



    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
        /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
