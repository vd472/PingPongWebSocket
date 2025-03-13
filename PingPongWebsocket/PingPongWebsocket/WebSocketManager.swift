import Foundation

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var ballPosition: CGPoint = CGPoint(x: 250, y: 300)
    @Published var playerPaddlePosition: CGFloat = 0.5
    @Published var opponentPaddlePosition: CGFloat = 0.5
    @Published var playerRole: String?

    func connect() {
        guard let url = URL(string: "ws://localhost:8080") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessages()
    }

    func sendPaddlePosition() {
        let gameState: [String: Any] = [
            "paddle": playerPaddlePosition
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: gameState, options: []) {
            let message = URLSessionWebSocketTask.Message.string(String(data: jsonData, encoding: .utf8)!)
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        }
    }

    func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message,
                   let data = text.data(using: .utf8),
                   let receivedState = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {

                    DispatchQueue.main.async {
                        if let role = receivedState["role"] as? String {
                            self?.playerRole = role
                        }

                        if let players = receivedState["players"] as? [String: CGFloat] {
                            if self?.playerRole == "player1" {
                                self?.playerPaddlePosition = players["player1"] ?? 0.5
                                self?.opponentPaddlePosition = players["player2"] ?? 0.5
                            } else {
                                self?.playerPaddlePosition = players["player2"] ?? 0.5
                                self?.opponentPaddlePosition = players["player1"] ?? 0.5
                            }
                        }

                        if let ball = receivedState["ball"] as? [String: CGFloat] {
                            let originalBallY = ball["y"] ?? 300

                            // ✅ Flip the Y position for Player 2
                            if self?.playerRole == "player2" {
                                let flippedY = 600 - originalBallY
                                self?.ballPosition = CGPoint(x: ball["x"] ?? 250, y: flippedY)
                            } else {
                                self?.ballPosition = CGPoint(x: ball["x"] ?? 250, y: originalBallY)
                            }
                        }
                    }
                }
                self?.receiveMessages()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
