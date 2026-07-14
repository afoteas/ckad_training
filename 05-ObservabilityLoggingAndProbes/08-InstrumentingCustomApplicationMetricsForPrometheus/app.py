from prometheus_client import start_http_server, Counter
import random
import time
import http.server
import socketserver

# 1. Define the Metric
# Create a Counter metric to track the total number of processed requests
REQUEST_COUNT = Counter('http_requests_total', 'Total number of HTTP requests processed by the application.')

# 2. Define the Application Logic (Simulated Request Handler)
class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # 3. Track the Event
        # In a real app, this is called inside your routing/handler logic
        REQUEST_COUNT.inc()
        
        # Standard response logic
        self.send_response(200)
        self.end_headers()
        
        if self.path == '/metrics':
            # Prometheus client library handles rendering the metrics here
            self.wfile.write(b'# Metrics data would be rendered here by the Prometheus client library\n')
            self.wfile.write(f'http_requests_total {REQUEST_COUNT._value}\n'.encode('utf-8'))
        else:
            self.wfile.write(b"Hello from the instrumented app!")

# 4. Expose the Endpoint
def start_app():
    # Start the Prometheus metrics endpoint on port 8080
    start_http_server(8080)
    
    # Start the main application server
    PORT = 8080
    with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
        print(f"Serving at port {PORT}")
        httpd.serve_forever()

if __name__ == '__main__':
    start_app()
