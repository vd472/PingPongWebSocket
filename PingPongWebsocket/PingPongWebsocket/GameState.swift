//
//  GameState.swift
//  PingPongWebsocket
//
//  Created by vijayesha on 12.03.25.
//

import Foundation
import CoreGraphics

struct GameState: Codable {
    var ballPosition: CGPoint
    var player1Paddle: CGFloat
    var player2Paddle: CGFloat
    var score: [Int]
}

