from flask import Flask, request
from moralis import auth
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

api_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJub25jZSI6ImViNGM4YTZiLTJkNDItNDg2Yy04ZDRkLTA4YTg0YmIxMjdjZiIsIm9yZ0lkIjoiMTIzMTEiLCJ1c2VySWQiOiIyMzAyMCIsInR5cGVJZCI6Ijc4YzEwZWQ2LTUxNmItNDcyNC05NzY1LWRkODk3OTFlNmIwZiIsInR5cGUiOiJQUk9KRUNUIiwiaWF0IjoxNzIzMzM4MjA1LCJleHAiOjQ4NzkwOTgyMDV9.MSw-9PHbWX6VXL74nDZI2DVml3elHgqBfmsOTLgR4jA"

@app.route('//requestChallenge', methods=["GET"])
def reqChallenge():
    args = request.args
    body = {
        "domain": "localhost",
        "chainId": args.get("ChainId"),
        "address": args.get("address"),
        "statement": "Please confirm login",
        "url": "https://localhost:3000/",
        "expirationTime": "2023-01-01T00:00:000Z",
        "notBefore": "2024-01-01T00:00:000Z",
        "resources": ['https://docs.moralis.io/'],
        "timout": 30,
    }

    result = auth.challenge.request_challenge_evm(
        api_key = api_key,
        body = body,
    )

    return result

@app.route('//verifyChallenge', methods=["GET"])
def verifyChallenge():
    args = request.args
    body = {
        "message": args.get("message"),
        "signature": args.get("signature"),
    }

    result = auth.challenge.verify_challenge_evm(
        api_key = api_key,
        body = body,
    )

    return result

if __name__ == '__main__':
    app.run(host="127.0.0.1", port=3000, debug=True)
