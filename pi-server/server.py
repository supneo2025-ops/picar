#!/usr/bin/env python3
"""
Pi Car Server - Main server application
Provides WebSocket control interface and MJPEG video streaming
"""

import logging
import signal
import sys
import json
from threading import Thread, Timer
from flask import Flask, Response, render_template_string, jsonify
from flask_socketio import SocketIO, emit
import config
from car_controller import CarController
from camera_stream import CameraStream


# Configure logging
logging.basicConfig(
    level=getattr(logging, config.LOG_LEVEL),
    format=config.LOG_FORMAT
)
logger = logging.getLogger(__name__)


# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'picar-secret-key-change-in-production'

# Initialize SocketIO with CORS support
socketio = SocketIO(
    app,
    cors_allowed_origins=config.CORS_ALLOWED_ORIGINS,
    async_mode='eventlet',
    ping_timeout=config.CLIENT_TIMEOUT,
    ping_interval=25
)

# Initialize car controller and camera
car = None
camera = None


def initialize_hardware():
    """Initialize car controller and camera"""
    global car, camera

    logger.info("Starting Pi Car Server...")

    try:
        # Initialize camera
        logger.info("Initializing camera...")
        camera = CameraStream()
        if camera.is_initialized:
            logger.info("✓ Camera initialized successfully")
        else:
            logger.warning("✗ Camera initialization failed - streaming disabled")

        # Initialize car controller
        logger.info("Initializing car controller...")
        car = CarController()
        if car.is_initialized:
            logger.info("✓ Car controller initialized successfully")
        else:
            logger.warning("✗ GPIO not available - controller in simulation mode")

        return True

    except Exception as e:
        logger.error(f"Failed to initialize hardware: {e}")
        return False


def cleanup_hardware():
    """Clean up hardware resources"""
    logger.info("Cleaning up hardware...")

    if car:
        car.cleanup()

    if camera:
        camera.cleanup()

    logger.info("Cleanup complete")


def watchdog_timer():
    """Periodic watchdog check to auto-stop motors if no commands received"""
    if car and config.ENABLE_WATCHDOG:
        car.check_watchdog()

    # Schedule next check
    Timer(1.0, watchdog_timer).start()


# Signal handler for graceful shutdown
def signal_handler(sig, frame):
    """Handle shutdown signals"""
    logger.info("Shutdown signal received")
    cleanup_hardware()
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


# ============================================================================
# HTTP Routes
# ============================================================================

@app.route('/')
def index():
    """Server status page"""
    status_page = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Pi Car Server</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: #f5f5f5;
            }
            .container {
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            h1 { color: #333; }
            .status {
                padding: 10px;
                margin: 10px 0;
                border-radius: 5px;
            }
            .status.ok {
                background: #d4edda;
                color: #155724;
            }
            .status.warning {
                background: #fff3cd;
                color: #856404;
            }
            .endpoint {
                background: #e9ecef;
                padding: 10px;
                margin: 5px 0;
                border-radius: 5px;
                font-family: monospace;
            }
            .video-preview {
                margin: 20px 0;
                border: 2px solid #ddd;
                border-radius: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚗 Pi Car Server</h1>

            <h2>Status</h2>
            <div class="status {{ camera_status }}">
                Camera: {{ camera_message }}
            </div>
            <div class="status {{ controller_status }}">
                Controller: {{ controller_message }}
            </div>

            <h2>Video Stream</h2>
            <img src="/video" class="video-preview" width="640" height="480" alt="Video Stream">

            <h2>API Endpoints</h2>
            <div class="endpoint">GET /</div>
            <p>This status page</p>

            <div class="endpoint">GET /video</div>
            <p>MJPEG video stream</p>

            <div class="endpoint">GET /health</div>
            <p>Health check endpoint</p>

            <div class="endpoint">WebSocket /socket.io/</div>
            <p>Control command interface</p>

            <h2>WebSocket Protocol</h2>
            <p>Send control commands as JSON:</p>
            <div class="endpoint">
                {"type": "control", "x": 0.5, "y": 0.8}
            </div>
            <p>x: -1.0 (left) to 1.0 (right)</p>
            <p>y: -1.0 (backward) to 1.0 (forward)</p>
        </div>
    </body>
    </html>
    """

    camera_ok = camera and camera.is_initialized
    controller_ok = car and car.is_initialized

    return render_template_string(
        status_page,
        camera_status='ok' if camera_ok else 'warning',
        camera_message='Online' if camera_ok else 'Offline (simulation mode)',
        controller_status='ok' if controller_ok else 'warning',
        controller_message='Online' if controller_ok else 'Offline (simulation mode)'
    )


@app.route('/video')
def video():
    """MJPEG video stream endpoint"""
    if not camera:
        return "Camera not initialized", 503

    return Response(
        camera.generate_frames(),
        mimetype='multipart/x-mixed-replace; boundary=frame'
    )


@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'camera': camera.is_initialized if camera else False,
        'controller': car.is_initialized if car else False
    })


# ============================================================================
# WebSocket Events
# ============================================================================

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    logger.info(f"Client connected")
    emit('status', {
        'type': 'status',
        'connected': True,
        'camera_available': camera.is_initialized if camera else False,
        'controller_available': car.is_initialized if car else False
    })


@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    logger.info("Client disconnected")
    # Stop motors when client disconnects for safety
    if car:
        car.stop()


@socketio.on('control')
def handle_control(data):
    """
    Handle control commands from client

    Expected data format:
    {
        "type": "control",
        "x": float (-1.0 to 1.0),
        "y": float (-1.0 to 1.0)
    }
    """
    try:
        # Parse command
        if isinstance(data, str):
            data = json.loads(data)

        command_type = data.get('type', 'control')

        if command_type == 'dual':
            if car:
                left = float(data.get('left', 0))
                right = float(data.get('right', 0))
                if config.DEBUG:
                    logger.info(f"Dual control received: left={left:.2f}, right={right:.2f}")
                car.process_dual_input(left, right)
            else:
                logger.warning("Car controller not available")
            return
        elif command_type != 'control':
            logger.warning(f"Unknown command type: {command_type}")
            return

        # Extract joystick coordinates
        x = float(data.get('x', 0))
        y = float(data.get('y', 0))

        # Validate range
        if not (-1.0 <= x <= 1.0 and -1.0 <= y <= 1.0):
            logger.warning(f"Invalid coordinate values: x={x}, y={y}")
            return

        # Control car
        if car:
            car.process_joystick_input(x, y)
            if config.DEBUG:
                logger.info(f"Control command received: x={x:.2f}, y={y:.2f}")
        else:
            logger.warning("Car controller not available")

    except ValueError as e:
        logger.error(f"Invalid control data format: {e}")
    except Exception as e:
        logger.error(f"Error processing control command: {e}")


@socketio.on('message')
def handle_message(data):
    """Handle generic messages (redirect to control handler)"""
    handle_control(data)


@socketio.on('ping')
def handle_ping():
    """Handle ping from client"""
    emit('pong')


# ============================================================================
# Main
# ============================================================================

def main():
    """Main entry point"""
    # Initialize hardware
    if not initialize_hardware():
        logger.error("Failed to initialize hardware")
        sys.exit(1)

    # Start watchdog timer if enabled
    if config.ENABLE_WATCHDOG:
        logger.info("Starting watchdog timer")
        watchdog_timer()

    # Display server information
    logger.info("=" * 60)
    logger.info("Pi Car Server Ready")
    logger.info("=" * 60)
    logger.info(f"Server running on {config.SERVER_HOST}:{config.SERVER_PORT}")
    logger.info(f"Video stream: http://192.168.100.148:{config.SERVER_PORT}/video")
    logger.info(f"WebSocket: ws://192.168.100.148:{config.SERVER_PORT}/socket.io/")
    logger.info(f"Status page: http://192.168.100.148:{config.SERVER_PORT}/")
    logger.info("=" * 60)

    # Run server
    try:
        socketio.run(
            app,
            host=config.SERVER_HOST,
            port=config.SERVER_PORT,
            debug=config.DEBUG,
            use_reloader=False  # Disable reloader to avoid double initialization
        )
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
    finally:
        cleanup_hardware()


if __name__ == '__main__':
    main()
