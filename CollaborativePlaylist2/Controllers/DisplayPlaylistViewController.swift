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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var accessCodeLabel: UILabel!
    
    var player = SPTAudioStreamingController.sharedInstance()
    let queue = DispatchQueue(label: "serial")
    
    var playAllSongs = [String]()
    @IBAction func playSongsButton(_ sender: Any) {
       audioStreaming()
    }
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

    
    
    var selectedPlaylist: Playlist?
    var listMusic = [Music?]()
    
    fileprivate var dataSource: FUITableViewDataSource? // step 1
    fileprivate var songsQuery: DatabaseQuery? // step2 + querty in FirebaseQueryService (same as getSongs)

    var isNewPlaylist: Bool{
        return self.selectedPlaylist == nil
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
}

//MARK: - Life cycle
extension DisplayPlaylistViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 80
        setupDataSource()
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
                    // I think you should only push to this ListSpotifyMusicViewController once you have fetched the playlist.
                    // Right now, even if you don't have a playlist, you push to the next screen, and your screen will be blank if the playlist fetching fails.
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
