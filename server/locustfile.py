import time
from locust import HttpUser, task, between
from random import randint,choice
import string
from lorem_text import lorem

def id_generator(size=6, chars=string.ascii_uppercase + string.digits):
    return ''.join(choice(chars) for _ in range(size))
class QuickstartUser(HttpUser):
    wait_time = between(1, 5)
    host = "<YOUR_SERVER_HERE>"
    def __init__(self, env, *args, **kwargs):
        super().__init__(env, *args, **kwargs)

        self.user1 = randint(1,100000000)
        self.user2 = randint(1,100000000)
        self.user3 = randint(1,100000000)
        self.user4 = randint(1,100000000)
        self.username1 = id_generator()
        self.username2 = id_generator()
        self.username3 = id_generator()
        self.username4 = id_generator()
        self.metadata = {
            "metadata": {
                "client_player_map": {
                    "1": {
                        "element_id": 1,
                        "peer_id": 1,
                        "username": self.username1
                    },
                    f"{self.user2}": {
                        "element_id": 0,
                        "peer_id": self.user2,
                        "username": self.username2
                    },
                    f"{self.user3}": {
                        "element_id": 2,
                        "peer_id": self.user3,
                        "username": self.username3
                    },
                    f"{self.user4}": {
                        "element_id": 3,
                        "peer_id": self.user4,
                        "username": self.username4
                    }
                },
                "client_submitting_data": 1,
                "current_level": randint(0,4),
                "current_round": randint(0,4),
                "game_id": "TEST_LOCUST_" + id_generator(),
                "room_id": "TEST_LOCUST_" + id_generator(),
                "timestamp": randint(1,1000000000)
            },
        }

    @task
    def get_scores(self):
        self.client.get("/get_scores")

    @task
    def save_scores(self):
        json = {
            **self.metadata, 
            **{
                "data": {
                    "score": randint(0,50000),
            "won": True,
            "score_breakdown": {
                "enemy_values": randint(0,40000),
                "health": randint(0,10),
                "score": randint(0,50000),
                "money": randint(0,2000)
            }
                }
            
        }
        }
        self.client.post("/test_save_score",json=json)
    
    @task 
    def save_chat(self):
        json = {
            **self.metadata,
            **{
                "data":
                {
                    "chat_text": lorem.words(randint(1,50)),
                    "chat_username": choice([self.username1,self.username2,self.username3,self.username4])
                }
            }
        }
        self.client.post("/save_chat",json=json)
        self.save_display_chat()

    @task 
    def save_display_chat(self):
        json = {
            **self.metadata,
            **{
                "data":
                {
                    "chat_text": lorem.words(randint(1,50)),
                    "chat_username": choice([self.username1,self.username2,self.username3,self.username4])
                }
            }
        }
        self.client.post("/save_displayed_chat",json=json)
