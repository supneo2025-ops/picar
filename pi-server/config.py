"""
Configuration settings for Pi Car Server
Modify these values to match your hardware setup
"""

# ============================================================================
# Network Configuration
# ============================================================================

# Server host (0.0.0.0 allows connections from any device on network)
SERVER_HOST = "0.0.0.0"

# Server port
SERVER_PORT = 5000

# CORS allowed origins (set to "*" for development, restrict in production)
CORS_ALLOWED_ORIGINS = "*"

# ============================================================================
# GPIO Pin Configuration (BCM numbering)
# ============================================================================

# Motor A (typically left motor)
MOTOR_A_PIN1 = 17  # GPIO 17
MOTOR_A_PIN2 = 27  # GPIO 27

# Motor B (typically right motor)
MOTOR_B_PIN1 = 23  # GPIO 23
MOTOR_B_PIN2 = 24  # GPIO 24

# PWM pins for speed control (optional, set to None if not using PWM)
MOTOR_A_ENABLE = 12  # GPIO 12 (PWM0)
MOTOR_B_ENABLE = 13  # GPIO 13 (PWM1)

# PWM frequency in Hz (if using PWM)
PWM_FREQUENCY = 1000

# Default motor speed (0-100, only used if PWM is enabled)
DEFAULT_SPEED = 70

# ============================================================================
# Motor Control Logic
# ============================================================================

# Invert motor direction if your motors are wired backwards
# Both motors have same wiring orientation
MOTOR_A_INVERTED = False
MOTOR_B_INVERTED = False

# Minimum input threshold to activate motors (dead zone)
# Values below this threshold (near center) will stop motors
JOYSTICK_DEAD_ZONE = 0.15

# Motor speed mapping
# These values determine how joystick input maps to motor speed
MIN_MOTOR_SPEED = 40   # Minimum speed to overcome motor resistance
MAX_MOTOR_SPEED = 100  # Maximum speed

# ============================================================================
# Camera Configuration
# ============================================================================

# Camera resolution (width, height)
CAMERA_RESOLUTION = (640, 480)

# Camera frame rate (fps)
CAMERA_FRAMERATE = 20

# JPEG quality for MJPEG stream (0-100, higher = better quality, more bandwidth)
JPEG_QUALITY = 80

# Camera rotation (0, 90, 180, 270) - adjust if camera is mounted upside down
CAMERA_ROTATION = 0

# Camera flip
CAMERA_HFLIP = False  # Horizontal flip
CAMERA_VFLIP = False  # Vertical flip

# ============================================================================
# Server Behavior
# ============================================================================

# Enable debug mode (verbose logging)
DEBUG = True

# Timeout for client connections (seconds)
CLIENT_TIMEOUT = 60

# Maximum message size for WebSocket (bytes)
MAX_MESSAGE_SIZE = 1024

# ============================================================================
# Logging Configuration
# ============================================================================

# Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
LOG_LEVEL = "INFO"

# Log format
LOG_FORMAT = "[%(levelname)s] %(message)s"

# ============================================================================
# Safety Features
# ============================================================================

# Auto-stop timeout: stop motors if no command received for this many seconds
AUTO_STOP_TIMEOUT = 2.0

# Enable watchdog timer for safety
ENABLE_WATCHDOG = True
