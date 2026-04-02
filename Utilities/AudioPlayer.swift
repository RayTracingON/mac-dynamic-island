import Combine
//
//  AudioPlayer.swift
//  boringNotch
//
//  Created by Richard Kunkli on 2024-08-06.
//

import AVFoundation
import Foundation

class AudioPlayer {
    private var audioPlayer: AVAudioPlayer?
    
    func play(fileName: String, fileExtension: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Audio file not found: \(fileName).\(fileExtension)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
    }
}
