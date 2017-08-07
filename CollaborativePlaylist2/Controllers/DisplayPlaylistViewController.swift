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
    
    
   
    var auth = SPTAuth.defaultInstance()!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    
    let queue = DispatchQueue(label: "serial")
    var playAllSongs = [String]()
    var selectedPlaylist: Playlist?
    var listMusic: [Music?] = []

    
    var isPaused = true
    var currentPoseIndex = 0.00
    var timer = Timer()
    var count = 0
    var trackDuration = 0
    var fullTrackDuration = 0
    var indexProgressBar = 0.00
    
    var playIndex: Int = 0 // index of current playing track
    var furthestIndex : Int = 0

    
    fileprivate var dataSource: FUITableViewDataSource? // step 1
    fileprivate var songsQuery: DatabaseQuery? // step2 + querty in FirebaseQueryService (same as getSongs)
    
    var isNewPlaylist: Bool{
        return self.selectedPlaylist == nil
    }
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!

    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var accessCodeLabel: UILabel!
    @IBOutlet weak var playAllSongsButton: UIButton!
    
    
    
    
    @IBAction func nextTapped(_ sender: Any) {
        playAllSongsButton.isSelected = true
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(DisplayPlaylistViewController.updateTimer), userInfo: nil, repeats: true)
        
        let tracks = listMusic
        
        if !tracks.isEmpty {
            if playIndex == tracks.count - 1 {
                player?.skipNext(printError(_:))
                
            } else {
                incrementPlayIndex()
                guard let track = listMusic[playIndex] else {return}
                self.trackDuration = track.length / 1000
                self.fullTrackDuration = track.length / 1000
                indexProgressBar = 0
                player?.playSpotifyURI(tracks[playIndex]?.uri, startingWith: 0, startingWithPosition: 0, callback: printError(_:))
                
                
//                 player?.playSpotifyURI(tracks[playIndex]?.uri, startingWith: 0, startingWithPosition: 0, callback: printError(_:))

            }
        }
    }
    
    
    
//Mark: - Button Actions
   
    @IBAction func playAllSongsButtonTapped(_ sender: UIButton) {
//        audioStreaming()
        playAllSongsButton.isSelected = !playAllSongsButton.isSelected
        
        if playAllSongsButton.isSelected {
            isPaused = false
            runTimer()
        }else{
            isPaused = true
            timer.invalidate()
        }
        
        if !listMusic.isEmpty {
            if let playbackState = player?.playbackState {
                let resume = !playbackState.isPlaying
                player?.setIsPlaying(resume, callback: printError(_:))
            }else {
                player?.playSpotifyURI(listMusic[playIndex]?.uri, startingWith: 0, startingWithPosition: 0, callback: printError(_:))
                print("the song is playing")
            }
                
            
        }else{
            print("no tracks to play")
        }
        
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
        if UIApplication.shared.openURL(auth.spotifyWebAuthenticationURL()) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
        
    }
    
    
    
    
    
//MARK: - Audio
    
    func audioStreaming() {
       
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

//Mark: Testing the Pause and Play 
extension DisplayPlaylistViewController {
    func runTimer () {
        getNextPoseData()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(DisplayPlaylistViewController.updateTimer)), userInfo: nil, repeats: true)
        
    }
    
    func printError(_ error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func updateTimer () {
        let songs = listMusic
        if songs.isEmpty {
            return
        }
        if trackDuration <= 0 {
            guard let track = listMusic[playIndex] else {return}
            self.trackDuration = (track.length) / 1000
            self.fullTrackDuration = (track.length) / 1000
        } else {
            trackDuration = trackDuration - 1
            if indexProgressBar != 0 && indexProgressBar == Double(fullTrackDuration) {
                getNextPoseData()
                indexProgressBar = 0
                if !listMusic.isEmpty {
                    if playIndex == listMusic.count - 1 {
                       player?.skipNext(printError(_:))
                    } else {
                        currentPoseIndex = 0
                        incrementPlayIndex()
                        guard let track = listMusic[playIndex] else {return}
                        self.trackDuration = track.length / 1000
                        self.fullTrackDuration = track.length / 1000
                        player?.playSpotifyURI(listMusic[playIndex]?.uri, startingWith: 0, startingWithPosition: 0, callback: printError(_:))
                        tableView.reloadData()
//
                    }
                }
            }
            
            progressBar.progress = Float(indexProgressBar)/Float(fullTrackDuration-1)
            indexProgressBar += 1
        }
        
        let (_,m, s) = secondsToHoursMinutesSeconds (seconds: trackDuration)
        let (_,min, sec) = secondsToHoursMinutesSeconds (seconds: Int(indexProgressBar))
        if s < 10  {
            timerLabel.text = "0\(m):0\(s)" // updates the label            startTimer.text = "0\(min):0\(sec)"
        } else {
            timerLabel.text = "0\(m):\(s)"
            startLabel.text = "0\(min):\(sec)"
        }
        if sec < 10  {
            startLabel.text = "0\(min):0\(sec)"
        } else {
            startLabel.text = "0\(min):\(sec)"
        }
    
    
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func printSecondsToHoursMinutesSeconds (seconds:Int) -> () {
        let (h, m, s) = secondsToHoursMinutesSeconds (seconds: trackDuration)
        print ("\(h) Hours, \(m) Minutes, \(s) Seconds")
    }
    
    func getNextPoseData() {
        currentPoseIndex += 1
        print("bye \(currentPoseIndex)")
        
    }
    
    func incrementPlayIndex() {
        if furthestIndex == playIndex {
            furthestIndex += 1
        }
        playIndex += 1
    }
    func decrementPlayIndex() {
        playIndex -= 1
        
    }
    
    func setProgressBar() {
        if indexProgressBar == Double(trackDuration) {
            getNextPoseData()
            // reset the progress counter
            indexProgressBar = 0
        }
        indexProgressBar += 1
    
    
    }
}


//MARK: - Life cycle
extension DisplayPlaylistViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playAllSongsButton.isEnabled = false
        tableView.rowHeight = 80
        
        setupDataSource()
        
         NotificationCenter.default.addObserver(self, selector: #selector(DisplayPlaylistViewController.initializePlayer), name: NSNotification.Name(rawValue: "sessionUpdated"), object: nil)
        
        player = SPTAudioStreamingController.sharedInstance()
        
        
        setProgressBar()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let playlist = selectedPlaylist {
            playlistNameTextField.text = playlist.playlistName
        }
        if (auth.session != nil) {
            if (auth.session.isValid()) {
                self.LoginToSpotify.isHidden = true
                initializePlayer(authSession: auth.session)
                
            } else {
                self.LoginToSpotify.isHidden = false
            }
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
                self.listMusic.append(song)
                
                
                
                
                
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
        
        Spartan.authorizationToken = authSession.accessToken
        print("hello")
        Spartan.loggingEnabled = true
        
    }
    
    


    
}

