import json
import os
import ssl
import time
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import websocket


HTTPS = "https://127.0.0.1:8443"
CA = Path(__file__).resolve().parent / ".local" / "echo-dev-ca.pem"
TLS = ssl.create_default_context(cafile=str(CA))


def request(path, *, data=None, token=None, expected=200):
    headers = {"Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    if token is not None:
        headers["Authorization"] = "Bearer " + token
    req = Request(HTTPS + path, headers=headers, data=json.dumps(data).encode() if data is not None else None)
    try:
        response = urlopen(req, context=TLS, timeout=5)
    except HTTPError as error:
        response = error
    with response:
        body = json.load(response)
        if response.status != expected or body["code"] != (expected if expected >= 400 else 0):
            raise AssertionError(f"{path.split('?')[0]}: HTTP {response.status}, code {body['code']}")
        return body["data"]


def login(role):
    return request("/auth/login", data={"account": role, "password": os.environ[f"ECHO_{role.upper()}_PASSWORD"]})


def socket_for(token, song):
    client = websocket.create_connection(
        "wss://127.0.0.1:8443/ws", header={"Authorization": "Bearer " + token},
        sslopt={"ca_certs": str(CA), "cert_reqs": ssl.CERT_REQUIRED}, suppress_origin=True, timeout=2,
    )
    try:
        client.send(json.dumps({"type": "subscribe", "songId": song}))
        event = json.loads(client.recv())
        if event["type"] != "subscribed" or event["songId"] != song:
            raise AssertionError("Wrong subscription")
        return client
    except BaseException:
        client.close()
        raise


class LocalIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.listener = login("listener")
        cls.operator = login("operator")
        cls.peer = login("listener")

    def test_role_and_401(self):
        self.assertEqual(self.listener["user"]["role"], "listener")
        self.assertEqual(self.operator["user"]["role"], "operator")
        request("/auth/login", data={"account": "listener", "password": "incorrect"}, expected=401)
        request("/home/feed", token="invalid", expected=401)
        request("/song/2124/comments", token=self.operator["token"], expected=403)
        token = login("operator")["token"]
        request("/auth/logout", token=token, data={})
        request("/home/feed", token=token, expected=401)
        for _ in range(20):
            self.assertEqual(len(request("/home/feed", token=self.listener["token"])["banners"]), 3)

    def test_search_and_ordered_playlists(self):
        token = self.listener["token"]
        feed = request("/home/feed", token=token)
        self.assertEqual(len(feed["daily"]), 36)
        self.assertEqual(len(feed["playlists"]), 13)
        self.assertEqual([item["id"] for item in feed["banners"]], [1, 2, 3])
        category = request("/playlist/15", token=token)
        self.assertEqual([item["id"] for item in category["songs"]], [2006, 2109, 2114, 2004, 2105, 2117, 2102])
        pages = [request("/search?" + urlencode({"keyword": "周杰伦", "page": page, "pageSize": 5}), token=token)
                 for page in range(1, 3)]
        self.assertTrue(pages[0]["hasMore"])
        self.assertEqual(len({item["id"] for page in pages for item in page["list"] + page["playlists"]}), 10)
        request("/playlist/999999", token=token, expected=404)

    def test_wss_push_heartbeat_song_isolation_and_resubscribe(self):
        token = self.listener["token"]
        subscriber = socket_for(token, 2124)
        other_song = socket_for(token, 2125)
        try:
            subscriber.send('{"type":"ping"}')
            self.assertEqual(json.loads(subscriber.recv())["type"], "pong")
            start = time.monotonic()
            first = request("/song/2124/comments", token=self.peer["token"], data={"text": "实训联调"})
            pushed = json.loads(subscriber.recv())
            elapsed = time.monotonic() - start
            self.assertEqual(pushed["comment"], first)
            self.assertLess(elapsed, 1.0)
            print(f"Independent HTTPS/WSS sessions: push round trip {elapsed * 1000:.1f} ms", flush=True)
            other_song.settimeout(0.35)
            with self.assertRaises(websocket.WebSocketTimeoutException):
                other_song.recv()
            subscriber.close()
            for index in range(5):
                song = 2125 if index % 2 == 0 else 2124
                subscriber = socket_for(token, song)
                sent = request(f"/song/{song}/comments", token=self.peer["token"], data={"text": "重新订阅"})
                self.assertEqual(json.loads(subscriber.recv())["comment"], sent)
                subscriber.close()
            history = request("/song/2124/comments", token=token)
            self.assertIn(first["id"], {item["id"] for item in history})
        finally:
            subscriber.close()
            other_song.close()


if __name__ == "__main__":
    unittest.main(verbosity=2)