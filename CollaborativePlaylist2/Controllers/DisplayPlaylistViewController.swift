//
//  DisplayPlaylistViewController.swift
//  CollaborativePlaylist2
//
//  Created by Brian on 7/13/17.
//  Copyright © 2017 jamee. All rights reserved.
//

import UIKit
import SafariServices
import FirebaseDatabase
import FirebaseStorage
import Spartan
import Kingfisher
import FirebaseDatabaseUI
import AVFoundation


class DisplayPlaylistViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    
    var session: SPTSession!
    var auth = SPTAuth.defaultInstance()!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    
    let queue = DispatchQueue(label: "serial")
    var playAllSongs = [String]()
    var selectedPlaylist: Playlist?
    var listMusic = [Music?]()
    
    fileprivate var dataSource: FUITableViewDataSource? // step 1
    fileprivate var songsQuery: DatabaseQuery? // step2 + querty in FirebaseQueryService (same as getSongs)
    
    var isNewPlaylist: Bool{
        return self.selectedPlaylist == nil
    }

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var accessCodeLabel: UILabel!
    @IBOutlet weak var playAllSongsButton: UIButton!
    
    
    
    
    
    
    
//Mark: - Button Actions
   
    @IBAction func playAllSongsButtonTapped(_ sender: UIButton) {
        audioStreaming()
        print("stfu \(String(describing: player?.loggedIn))")
    }


    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        if isNewPlaylist {
            PlaylistService.I.create(playlistName: playlistNameTextField.text ?? "")
        } else {
             self.selectedPlaylist?.playlistName = playlistNameTextField.text ?? self.selectedPlaylist!.playlistName
            
            
            PlaylistService.I.update(playlist: self.selectedPlaylist!)
        }
        
        self.navigationController?.popToRootViewController(animated: true)
        
    }
    @IBOutlet weak var LoginToSpotify: UIButton!
    
    @IBAction func LoginToSpotifyButtonTapped(_ sender: UIButton) {
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
        
    }
    
    
    
    
    
//MARK: - Audio
    
    func audioStreaming() {
        //        _ = Spartan.getAudioAnaylsis(trackId: "2ZyuwVvV6Z3XJaXIFbspeE", success: { (AudioAnalysis) in
        //            let trackInfo = AudioAnalysis.track
        //            let trackDuration = trackInfo?.duration
        //            print("bob is a sponge \(trackDuration)")
        //
        //
        //        }, failure:  { (error) in
        //            print(error)
        //
        //        })
        for song in playAllSongs {
            
            self.player?.queueSpotifyURI(song, callback: { (error) in
                print("hello")
            })
            queue.async {
                self.player?.queueSpotifyURI(song, callback: { (error) in
                    if (error == nil) {
                        self.queue.async {
                            self.player?.playSpotifyURI(song, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                                if (error == nil) {
                                    print("playing!")
                                    
                                } else {
                                    print("song error")
                                    print(error!.localizedDescription)
                                    
                                }
                                
                            })
                        }
                    } else {
                        print("queue error")
                    }
                    
                })
            }
            
        }
        
        
    }
  
  
    
}


//MARK: - Life cycle
extension DisplayPlaylistViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playAllSongsButton.isEnabled = false
        tableView.rowHeight = 80
        setupDataSource()
        
        player = SPTAudioStreamingController.sharedInstance()
        
        if (player?.loggedIn)! {
            updateAfterFirstLogin()
            
        } else {
            setup()
            print("auth session \(self.auth.session)")
            
            NotificationCenter.default.addObserver(self, selector: #selector(DisplayPlaylistViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
            
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let playlist = selectedPlaylist {
            playlistNameTextField.text = playlist.playlistName
        }
    }
}

//MARK: - Data source
extension DisplayPlaylistViewController {
    func setupDataSource() {
        if !isNewPlaylist {
            self.songsQuery = FirebaseQueryService.I.getSongs(for: self.selectedPlaylist!)
            self.setupTableView()
        }
    }
    
    private func setupTableView() { // step 3
        self.dataSource = tableView.bind(to: songsQuery!, populateCell: { tableView, indexPath, snapshot in
            let cell = tableView.dequeueReusableCell(withIdentifier: "addedSongCell") as! addedSongCell
            
            if let song = Music(snapshot: snapshot) {
                self.playAllSongs.append(song.uri)
                print(song)
                
                cell.songNameLabel.text = song.name
                let imageURL = URL(string: song.mainImage)
                cell.songImageView.kf.setImage(with: imageURL)
            }
            
            return cell
        })
    }

    
}

//MARK: - Segue
extension DisplayPlaylistViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "songsList" {
                let listSpotifyMusicViewController = segue.destination as! ListSpotifyMusicViewController
                
                if isNewPlaylist {
                    PlaylistService.I.create(playlistName: playlistNameTextField.text ?? "") { playlist in
                        listSpotifyMusicViewController.playlist = playlist
                        listSpotifyMusicViewController.playlist?.playlistName = self.playlistNameTextField.text ?? ""
                        self.setupDataSource()
                    }
                    
                    return
                }
                
                selectedPlaylist?.playlistName = playlistNameTextField.text ?? ""
                listSpotifyMusicViewController.playlist = selectedPlaylist
            }
        }
    }
}


//MARK: - LOGIN TO SPOTIFY
extension DisplayPlaylistViewController {
    
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
        
        Spartan.authorizationToken = session.accessToken
        print("hello")
        Spartan.loggingEnabled = true
        
    }
    
    func updateAfterFirstLogin () {
        
        LoginToSpotify.isHidden = true
        self.playAllSongsButton.isEnabled = true
        
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            self.session = firstTimeSession
            initializePlayer(authSession: session)
            
            self.LoginToSpotify.isHidden = true
            self.playAllSongsButton.isEnabled = true
            // self.loadingLabel.isHidden = false
            
            
        }
    }


    
}

