from datetime import datetime
from flask import Flask, request
from flask_json import FlaskJSON, JsonError, json_response, as_json
import json, os, threading
import pandas as pd
from ast import literal_eval

### DATA FILES ###
root_dir = "./data"
chats_fn = 'chats.csv'
scores_fn = 'scores.csv'
displayed_chats_fn = 'displayed_chats.csv'

chats_lock = threading.Lock()
displayed_chats_lock = threading.Lock()
scores_lock = threading.Lock()

app = Flask(__name__)
FlaskJSON(app)



@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

@app.route("/test_get",methods=['GET'])
def test_get():
    return json_response(value="test get")

@app.route("/test_post",methods=['POST'])
def test_post(data):
    print("i am posting something", data)
    return

@app.route("/save_chat", methods=['POST'])
def save_chat():
    with chats_lock:
        data = request.get_json()
        room_id = data["metadata"]["room_id"].rstrip('.')
        subdir = f"{root_dir}/{room_id}"
        chats_fp = f"{subdir}/{chats_fn}"

        if not os.path.exists(subdir):
            os.makedirs(subdir,exist_ok=True)

        chat_text = data["data"]["chat_text"].replace("\n"," ").strip()
        chat_username = data["data"]["chat_username"]
        del data["data"]
        df = pd.DataFrame.from_dict(data,orient="index")
        df["chat_text"] = [chat_text]
        df["chat_username"] = [chat_username]

        headers = False
        if not os.path.exists(chats_fp):
            headers = True
        _entry = df.to_csv(index=False,header=headers)

    
    
        with open(chats_fp,'a') as f:
            f.write(_entry)

        return json_response(200)
@app.route("/save_displayed_chat", methods=['POST'])
def save_displayed_chat():
    with displayed_chats_lock:
        data = request.get_json()
        room_id = data["metadata"]["room_id"].rstrip('.')
        subdir = f"{root_dir}/{room_id}"
        chats_fp = f"{subdir}/{displayed_chats_fn}"

        if not os.path.exists(subdir):
            os.makedirs(subdir,exist_ok=True)

        chat_text = data["data"]["chat_text"].replace("\n"," ").strip()
        chat_username = data["data"]["chat_username"]
        del data["data"]
        df = pd.DataFrame.from_dict(data,orient="index")
        df["chat_text"] = [chat_text]
        df["chat_username"] = [chat_username]

    
    
    
        headers = False
        if not os.path.exists(chats_fp):
            headers = True
        _entry = df.to_csv(index=False,header=headers)
        with open(chats_fp,'a') as f:
            f.write(_entry)

        return json_response(200)
    
@app.route("/save_score", methods=['POST'])
def save_score():
    with scores_lock:

        scores_fp = f"{root_dir}/{scores_fn}"
        data = request.get_json()

        gold = data["data"]["score_breakdown"]["money"]
        score = data["data"]["score"]
        won = data["data"]["won"]
        enemy_values = data["data"]["score_breakdown"]["enemy_values"]
        health = data["data"]["score_breakdown"]["health"]
        level = data["metadata"]["current_level"]
        game_id = data["metadata"]["game_id"]
        del data["data"]
        df = pd.DataFrame.from_dict(data,orient="index")
        df["score"] = [score]
        df["won"] = [won]
        df["health"] = [health]
        df["enemy_values"] = [enemy_values]
        df["game_id"] = [game_id]
        df["level"] = [level]
        df["money"] = [gold]

    

        headers = False
        if not os.path.exists(scores_fp):
            headers = True
        _entry = df.to_csv(index=False,header=headers)
        with open(scores_fp,'a') as f:
            f.write(_entry)
    
        return json_response(200)
@app.route("/test_save_score", methods=['POST'])
def test_save_score():
    with scores_lock:

        scores_fp = f"{root_dir}/test_{scores_fn}"
        data = request.get_json()

        gold = data["data"]["score_breakdown"]["money"]
        score = data["data"]["score"]
        won = data["data"]["won"]
        enemy_values = data["data"]["score_breakdown"]["enemy_values"]
        health = data["data"]["score_breakdown"]["health"]
        level = data["metadata"]["current_level"]
        game_id = data["metadata"]["game_id"]
        del data["data"]
        df = pd.DataFrame.from_dict(data,orient="index")
        df["score"] = [score]
        df["won"] = [won]
        df["health"] = [health]
        df["enemy_values"] = [enemy_values]
        df["game_id"] = [game_id]
        df["level"] = [level]
        df["money"] = [gold]

    

        headers = False
        if not os.path.exists(scores_fp):
            headers = True
        _entry = df.to_csv(index=False,header=headers)
        with open(scores_fp,'a') as f:
            f.write(_entry)
    
        return json_response(200)
@app.route("/get_scores", methods=["GET"])
def get_scores():
    scores_fp = f"{root_dir}/{scores_fn}"

    if not os.path.exists(scores_fp):
        
        return json_response(scores={})

    with scores_lock:
        scores_json = pd.read_csv(scores_fp)

    # get all levels 
    levels = [0,1,2,3]
    json = {}
    for level in levels:
        _slice = scores_json[scores_json["level"] == level]
        for row in _slice.itertuples():
            _entry = {
                "level": level,
                "score": int(row.score),
                "game_id": row.game_id if row.game_id is not None and not pd.isnull(row.game_id) else '',
                "room_id": row.room_id,
                "rts_mode": row.is_rts
            
            }
            if level not in json:
                json[level] = [_entry]
            else:
                json[level].append(_entry)

    
    return json_response(scores=json)