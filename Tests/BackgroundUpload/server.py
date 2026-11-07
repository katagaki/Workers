import hashlib
import http.server
import json
import sys
import time


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *arguments):
        pass

    def do_PUT(self):
        expected = int(self.headers.get("Content-Length", 0))
        received = 0
        digest = hashlib.sha256()
        while received < expected:
            chunk = self.rfile.read(min(65536, expected - received))
            if not chunk:
                break
            received += len(chunk)
            digest.update(chunk)
            if "slow" in self.path:
                time.sleep(0.05)
        print(json.dumps({"path": self.path, "sha256": digest.hexdigest()}), flush=True)
        status, body = 200, b'{"success":true,"result":{}}'
        if "denied" in self.path:
            status, body = 403, b'{"success":false,"errors":[{"message":"Forbidden"}]}'
        if "rejected" in self.path:
            status, body = 400, b'{"success":false,"errors":[{"message":"Bucket quota exceeded"}]}'
        self.send_response(status)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
