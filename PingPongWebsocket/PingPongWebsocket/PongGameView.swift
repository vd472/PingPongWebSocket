//
//  ContentView.swift
//  PingPongWebsocket
//
//  Created by vijayesha on 12.03.25.
//

import SwiftUI

struct PongGameView: View {
    @StateObject private var webSocketManager = WebSocketManager()

    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("Ping Pong Multiplayer")
                    .font(.title)
                    .padding()

                Text("You are: \(String(describing: webSocketManager.playerRole))")
                    .font(.headline)
                    .padding()

                ZStack {
                    // Ball
                    Circle()
                        .frame(width: 20, height: 20)
                        .position(webSocketManager.ballPosition)

                    // Player Paddle (Controlled by the current user)
                    Rectangle()
                        .frame(width: 100, height: 10)
                        .position(x: webSocketManager.playerPaddlePosition * geo.size.width, y: geo.size.height - 170)
                        .foregroundColor(.blue)

                    // Opponent Paddle
                    Rectangle()
                        .frame(width: 100, height: 10)
                        .position(x: webSocketManager.opponentPaddlePosition * geo.size.width, y: 0)
                        .foregroundColor(.red)
                }
                .gesture(DragGesture().onChanged { value in
                    let normalizedPosition = value.location.x / geo.size.width
                    print(normalizedPosition)
                    print(geo.size)
                    webSocketManager.playerPaddlePosition = normalizedPosition
                    webSocketManager.sendPaddlePosition()
                })
            }
        }
        .onAppear {
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}
#Preview {
    PongGameView()
}
