#!/usr/bin/python3

import http.server
from subprocess import run, PIPE
import sys

class Server(http.server.BaseHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        return http.server.BaseHTTPRequestHandler.__init__(self, *args, **kwargs) 

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        result = run(["qrexec-client-vm", sys.argv[1], "qpay"], input=self.path[1:], encoding="ascii", stdout=PIPE)
        self.wfile.write(result.stdout.encode())

server = http.server.HTTPServer(("127.0.0.1", 9876), Server)
server.serve_forever()
