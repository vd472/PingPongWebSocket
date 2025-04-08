import asyncio
import websockets
import json
import random

# Store connected players
connected_clients = {}

# Game state
game_state = {
    "ball": {"x": 250, "y": 300, "dx": 3, "dy": 3},  # Ball position and speed
    "players": {
        "player1": 0.5,  # Paddle position (0-1)
        "player2": 0.5
    }
}

async def move_ball():
    """Continuously update the ball's position and check for collisions."""
    while True:
        game_state["ball"]["x"] += game_state["ball"]["dx"]
        game_state["ball"]["y"] += game_state["ball"]["dy"]

        # Ball collision with walls (left/right)
        if game_state["ball"]["x"] <= 0 or game_state["ball"]["x"] >= 400:
            game_state["ball"]["dx"] *= -1  # Reverse direction

        # Ball collision with paddles
        if game_state["ball"]["y"] <= 20:  # Top paddle (Player 1)
            print(abs(game_state["players"]["player2"]))
            if abs(game_state["players"]["player2"] * 500 - game_state["ball"]["x"]) < 50:
                game_state["ball"]["dy"] *= -1  # Reverse direction

        if game_state["ball"]["y"] >= 580:  # Bottom paddle (Player 2)
            print(abs(game_state["players"]["player1"]))
            if abs(game_state["players"]["player1"] * 500 - game_state["ball"]["x"]) < 50:
                game_state["ball"]["dy"] *= -1  # Reverse direction

        # Ball goes out of bounds (reset game)
        if game_state["ball"]["y"] <= 0 or game_state["ball"]["y"] >= 600:
            game_state["ball"] = {"x": 250, "y": 300, "dx": random.choice([-3, 3]), "dy": random.choice([-3, 3])}

        await broadcast()
        await asyncio.sleep(0.01)  # Update ball every 30ms

async def broadcast():
    """Send the game state to all connected players."""
    if connected_clients:
        message = json.dumps(game_state)
        await asyncio.wait([client.send(message) for client in connected_clients.keys()])

async def handler(websocket):
    """Handle a new player connection."""
    if len(connected_clients) == 0:
        player_role = "player1"
    elif len(connected_clients) == 1:
        player_role = "player2"
    else:
        await websocket.send(json.dumps({"error": "Game full"}))
        return

    connected_clients[websocket] = player_role
    print(f"{player_role} connected!")

    # Send player role
    await websocket.send(json.dumps({"role": player_role}))

    try:
        async for message in websocket:
            data = json.loads(message)

            # Update player's paddle position
            if player_role == "player1" and "paddle" in data:
                game_state["players"]["player1"] = data["paddle"]
            elif player_role == "player2" and "paddle" in data:
                game_state["players"]["player2"] = data["paddle"]

            await broadcast()

    except websockets.exceptions.ConnectionClosed:
        print(f"{player_role} disconnected!")
        del connected_clients[websocket]

# Start WebSocket server
async def main():
    print("WebSocket server running on ws://localhost:8080")
    asyncio.create_task(move_ball())  # ✅ Start the ball movement loop
    async with websockets.serve(handler, "localhost", 8080):
        await asyncio.Future()  # Keeps the server running

asyncio.run(main())
