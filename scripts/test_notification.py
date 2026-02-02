import http.server
import socketserver
import threading
import time
import os
import sys

PORT = 8989
HANDLER_CALLED = False

class WebhookHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        global HANDLER_CALLED
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        print(f"\n[Server] Received POST data: {post_data.decode('utf-8')}")
        HANDLER_CALLED = True
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

    def log_message(self, format, *args):
        return # Silence default logging

def start_server():
    with socketserver.TCPServer(("", PORT), WebhookHandler) as httpd:
        print(f"[Server] Listening on port {PORT}...")
        httpd.handle_request() # Handle one request then exit

def test_notification():
    # Start server in thread
    server_thread = threading.Thread(target=start_server)
    server_thread.start()
    time.sleep(1) # Wait for server

    # Simulate Agent Action
    webhook_url = f"http://localhost:{PORT}/webhook"
    print(f"[Agent] Simulating notification to {webhook_url}...")
    
    # This is the exact command pattern used in the .md files
    cmd = f"curl -X POST -H \"Content-Type: application/json\" -d '{{\"text\": \"✅ Dev Task Complete: Tests passed.\"}}' {webhook_url}"
    
    print(f"[Agent] Running: {cmd}")
    os.system(cmd)
    
    server_thread.join()
    
    if HANDLER_CALLED:
        print("\n✅ SUCCESS: Notification received successfully.")
    else:
        print("\n❌ FAILURE: Notification not received.")

if __name__ == "__main__":
    test_notification()
