//
//  JoinPlaylistViewController.swift
//  CollaborativePlaylist2
//
//  Created by Brian on 8/2/17.
//  Copyright © 2017 jamee. All rights reserved.
//

import UIKit
import Spartan
import SafariServices

class JoinPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate  {

    var songSelections = [SongSelection]()

    var playlist : Playlist?
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    @IBOutlet weak var loginToSpotifyButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func loginToSpotifyButtonTapped(_ sender: UIButton) {
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(JoinPlaylistViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        player = SPTAudioStreamingController.sharedInstance()
        //        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(songSelections.count)
        return songSelections.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinSpotifySongsCell") as! JoinSpotifySongsCell
        
        print("what's uppppppp")
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
    
    
    func updateAfterFirstLogin () {
        
       loginToSpotifyButton.isHidden = true
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let timeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            self.session = timeSession
            initializePlayer(authSession: session)
            
            
            self.loginToSpotifyButton.isHidden = true
            // self.loadingLabel.isHidden = false
            
            
            
        }
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
                    print(self.playlist)
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
    }

    private func createSong(post: Post, playlist: Playlist, trackId: String) {
        MusicService.I.createSong(using: post,
                                  playlist: playlist,
                                  trackId: trackId)
    }
    
    
    //finishedAddingSong
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let identifier = segue.identifier {
            if identifier == "finishedAddingSong" {
                if let cell = sender as? UITableViewCell {
                    
                    guard let indexPath = tableView.indexPath(for: cell) else { return }
                    let songSelection = songSelections[indexPath.row]
                    
                    self.playlist?.songs.append(songSelection.track.id)
                    guard let playlist = self.playlist else { return }
                    
                    guard let viewController = segue.destination as? ViewController else { return }
                    
                    viewController.joinPlaylist = playlist
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
    

   

}
