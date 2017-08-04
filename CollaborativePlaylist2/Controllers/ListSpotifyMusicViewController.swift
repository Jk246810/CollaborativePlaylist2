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
    var session:SPTSession!
    
    var loginUrl: URL?
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var LoginToSpotify: UIButton!
    
    @IBAction func LoginToSpotifyButtonTapped(_ sender: UIButton) {
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                            // To do - build in error handling
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if self.auth.session.isValid() {
//            updateAfterFirstLogin()
//            player = SPTAudioStreamingController.sharedInstance()
//        }else {
        
            setup()
            NotificationCenter.default.addObserver(self, selector: #selector(ListSpotifyMusicViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)

       

        
//        }
       
    }
    
        // Do any additional setup after loading the view.
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserReadPrivateScope, SPTAuthUserLibraryModifyScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistReadPrivateScope]
        loginUrl = auth.spotifyWebAuthenticationURL()
    }
    
    
    func updateAfterFirstLogin () {
        
        LoginToSpotify.isHidden = true
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            self.session = firstTimeSession
            initializePlayer(authSession: session)
            
            
            self.LoginToSpotify.isHidden = true
            // self.loadingLabel.isHidden = false
            
            
            
        }
    }

    
    
    func initializePlayer(authSession:SPTSession){
        var player: SPTAudioStreamingController?
        player!.playbackDelegate = self
        player!.delegate = self
        try! player?.start(withClientId: auth.clientID)
        player!.login(withAccessToken: authSession.accessToken)
    
        Spartan.authorizationToken = session.accessToken
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
                    
                    guard let playlist = self.playlist else { return }
                    
                    if !playlist.songs.contains(trackId!) {
                        self.songSelections.append(selection)
                    }
                }
            }

                self.tableView.reloadData()
        }, failure: { (error) in
            print(error)
        })
        player = SPTAudioStreamingController.sharedInstance()
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
