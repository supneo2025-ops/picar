"""
Car Controller - GPIO-based motor control for Raspberry Pi car
Handles motor control based on joystick input coordinates
"""

import time
import logging
from typing import Tuple
import config

try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    logging.warning("RPi.GPIO not available. Running in simulation mode.")


class CarController:
    """
    Controls car motors via GPIO pins based on joystick input.

    Joystick coordinates:
    - x: -1.0 (left) to 1.0 (right)
    - y: -1.0 (backward) to 1.0 (forward)
    """

    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.is_initialized = False
        self.pwm_a = None
        self.pwm_b = None
        self.last_command_time = time.time()

        if GPIO_AVAILABLE:
            self._initialize_gpio()
        else:
            self.logger.warning("GPIO not available - controller in simulation mode")

    def _initialize_gpio(self):
        """Initialize GPIO pins for motor control"""
        try:
            # Set GPIO mode to BCM numbering
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)

            # Setup motor A pins
            GPIO.setup(config.MOTOR_A_PIN1, GPIO.OUT)
            GPIO.setup(config.MOTOR_A_PIN2, GPIO.OUT)

            # Setup motor B pins
            GPIO.setup(config.MOTOR_B_PIN1, GPIO.OUT)
            GPIO.setup(config.MOTOR_B_PIN2, GPIO.OUT)

            # Setup PWM pins if configured
            if config.MOTOR_A_ENABLE is not None:
                GPIO.setup(config.MOTOR_A_ENABLE, GPIO.OUT)
                self.pwm_a = GPIO.PWM(config.MOTOR_A_ENABLE, config.PWM_FREQUENCY)
                self.pwm_a.start(0)

            if config.MOTOR_B_ENABLE is not None:
                GPIO.setup(config.MOTOR_B_ENABLE, GPIO.OUT)
                self.pwm_b = GPIO.PWM(config.MOTOR_B_ENABLE, config.PWM_FREQUENCY)
                self.pwm_b.start(0)

            # Initialize motors to stopped state
            self.stop()

            self.is_initialized = True
            self.logger.info("GPIO initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize GPIO: {e}")
            raise

    def _set_motor_a(self, direction: int, speed: int):
        """
        Set Motor A direction and speed

        Args:
            direction: 1 (forward), -1 (backward), 0 (stop)
            speed: 0-100 PWM duty cycle
        """
        if not GPIO_AVAILABLE:
            return

        # Apply inversion if configured
        if config.MOTOR_A_INVERTED:
            direction = -direction

        if direction == 1:  # Forward
            GPIO.output(config.MOTOR_A_PIN1, GPIO.HIGH)
            GPIO.output(config.MOTOR_A_PIN2, GPIO.LOW)
        elif direction == -1:  # Backward
            GPIO.output(config.MOTOR_A_PIN1, GPIO.LOW)
            GPIO.output(config.MOTOR_A_PIN2, GPIO.HIGH)
        else:  # Stop
            GPIO.output(config.MOTOR_A_PIN1, GPIO.LOW)
            GPIO.output(config.MOTOR_A_PIN2, GPIO.LOW)

        # Set speed via PWM if available
        if self.pwm_a is not None:
            self.pwm_a.ChangeDutyCycle(speed if direction != 0 else 0)

    def _set_motor_b(self, direction: int, speed: int):
        """
        Set Motor B direction and speed

        Args:
            direction: 1 (forward), -1 (backward), 0 (stop)
            speed: 0-100 PWM duty cycle
        """
        if not GPIO_AVAILABLE:
            return

        # Apply inversion if configured
        if config.MOTOR_B_INVERTED:
            direction = -direction

        if direction == 1:  # Forward
            GPIO.output(config.MOTOR_B_PIN1, GPIO.HIGH)
            GPIO.output(config.MOTOR_B_PIN2, GPIO.LOW)
        elif direction == -1:  # Backward
            GPIO.output(config.MOTOR_B_PIN1, GPIO.LOW)
            GPIO.output(config.MOTOR_B_PIN2, GPIO.HIGH)
        else:  # Stop
            GPIO.output(config.MOTOR_B_PIN1, GPIO.LOW)
            GPIO.output(config.MOTOR_B_PIN2, GPIO.LOW)

        # Set speed via PWM if available
        if self.pwm_b is not None:
            self.pwm_b.ChangeDutyCycle(speed if direction != 0 else 0)

    def process_joystick_input(self, x: float, y: float):
        """
        Process joystick input and control motors accordingly

        Args:
            x: Horizontal axis (-1.0 to 1.0), negative = left, positive = right
            y: Vertical axis (-1.0 to 1.0), negative = backward, positive = forward
        """
        self.last_command_time = time.time()

        # Clamp values to valid range
        x = max(-1.0, min(1.0, x))
        y = max(-1.0, min(1.0, y))

        # Apply axis-specific dead zones to avoid unintended drift
        if abs(x) < config.JOYSTICK_DEAD_ZONE:
            x = 0.0
        if abs(y) < config.JOYSTICK_DEAD_ZONE:
            y = 0.0

        if x == 0.0 and y == 0.0:
            self.stop()
            return

        # Calculate motor speeds using differential drive
        # Base speed from y-axis (forward/backward)
        left_speed = y
        right_speed = y

        # Add turning component from x-axis
        # Positive x (right) reduces left motor and increases right motor
        # Negative x (left) reduces right motor and increases left motor
        left_speed -= x
        right_speed += x

        # Clamp to -1.0 to 1.0
        left_speed = max(-1.0, min(1.0, left_speed))
        right_speed = max(-1.0, min(1.0, right_speed))

        # Convert to direction and PWM values
        left_direction = 1 if left_speed > 0 else (-1 if left_speed < 0 else 0)
        right_direction = 1 if right_speed > 0 else (-1 if right_speed < 0 else 0)

        # Map to configured speed range
        left_pwm = self._map_speed(abs(left_speed))
        right_pwm = self._map_speed(abs(right_speed))

        # Set motors
        self._set_motor_a(left_direction, left_pwm)
        self._set_motor_b(right_direction, right_pwm)

        # Log command in debug mode
        if config.DEBUG:
            self.logger.debug(
                f"Joystick: ({x:.2f}, {y:.2f}) -> "
                f"Left: {left_direction}@{left_pwm}%, Right: {right_direction}@{right_pwm}%"
            )

    def process_dual_input(self, left: float, right: float):
        """
        Control motors independently using normalized left/right values

        Args:
            left: -1.0 (full reverse) to 1.0 (full forward) for left motor
            right: -1.0 (full reverse) to 1.0 (full forward) for right motor
        """
        self.last_command_time = time.time()

        left = max(-1.0, min(1.0, left))
        right = max(-1.0, min(1.0, right))

        if abs(left) < config.JOYSTICK_DEAD_ZONE:
            left = 0.0
        if abs(right) < config.JOYSTICK_DEAD_ZONE:
            right = 0.0

        if left == 0.0 and right == 0.0:
            self.stop()
            return

        left_direction = 1 if left > 0 else (-1 if left < 0 else 0)
        right_direction = 1 if right > 0 else (-1 if right < 0 else 0)

        left_pwm = self._map_speed(abs(left))
        right_pwm = self._map_speed(abs(right))

        self._set_motor_a(left_direction, left_pwm)
        self._set_motor_b(right_direction, right_pwm)

        if config.DEBUG:
            self.logger.debug(
                f"Dual control -> Left: {left_direction}@{left_pwm}%, "
                f"Right: {right_direction}@{right_pwm}%"
            )

    def _map_speed(self, normalized_speed: float) -> int:
        """
        Map normalized speed (0.0-1.0) to PWM duty cycle

        Args:
            normalized_speed: Speed value from 0.0 to 1.0

        Returns:
            PWM duty cycle value (MIN_MOTOR_SPEED to MAX_MOTOR_SPEED)
        """
        if normalized_speed < config.JOYSTICK_DEAD_ZONE:
            return 0

        # Map to configured speed range
        speed_range = config.MAX_MOTOR_SPEED - config.MIN_MOTOR_SPEED
        return int(config.MIN_MOTOR_SPEED + (normalized_speed * speed_range))

    def stop(self):
        """Stop all motors"""
        self._set_motor_a(0, 0)
        self._set_motor_b(0, 0)
        if config.DEBUG:
            self.logger.debug("Motors stopped")

    def forward(self, speed: int = None):
        """Move forward at specified speed"""
        speed = speed or config.DEFAULT_SPEED
        self._set_motor_a(1, speed)
        self._set_motor_b(1, speed)
        self.logger.debug(f"Moving forward at {speed}%")

    def backward(self, speed: int = None):
        """Move backward at specified speed"""
        speed = speed or config.DEFAULT_SPEED
        self._set_motor_a(-1, speed)
        self._set_motor_b(-1, speed)
        self.logger.debug(f"Moving backward at {speed}%")

    def turn_left(self, speed: int = None):
        """Turn left (left motor backward, right motor forward)"""
        speed = speed or config.DEFAULT_SPEED
        self._set_motor_a(-1, speed)
        self._set_motor_b(1, speed)
        self.logger.debug(f"Turning left at {speed}%")

    def turn_right(self, speed: int = None):
        """Turn right (left motor forward, right motor backward)"""
        speed = speed or config.DEFAULT_SPEED
        self._set_motor_a(1, speed)
        self._set_motor_b(-1, speed)
        self.logger.debug(f"Turning right at {speed}%")

    def check_watchdog(self):
        """
        Check if too much time has elapsed since last command
        Auto-stop motors if timeout exceeded
        """
        if not config.ENABLE_WATCHDOG:
            return

        elapsed = time.time() - self.last_command_time
        if elapsed > config.AUTO_STOP_TIMEOUT:
            self.stop()
            self.logger.warning(f"Watchdog timeout ({elapsed:.1f}s) - motors stopped")

    def cleanup(self):
        """Clean up GPIO resources"""
        if GPIO_AVAILABLE and self.is_initialized:
            self.stop()
            if self.pwm_a:
                self.pwm_a.stop()
            if self.pwm_b:
                self.pwm_b.stop()
            GPIO.cleanup()
            self.logger.info("GPIO cleaned up")


# Test code
if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format=config.LOG_FORMAT)

    print("Car Controller Test")
    print("=" * 50)

    controller = CarController()

    if not controller.is_initialized:
        print("WARNING: GPIO not initialized. Simulation mode only.")

    try:
        print("\nTest 1: Forward for 2 seconds")
        controller.forward(50)
        time.sleep(2)

        print("Test 2: Backward for 2 seconds")
        controller.backward(50)
        time.sleep(2)

        print("Test 3: Turn left for 2 seconds")
        controller.turn_left(50)
        time.sleep(2)

        print("Test 4: Turn right for 2 seconds")
        controller.turn_right(50)
        time.sleep(2)

        print("Test 5: Joystick control - forward")
        controller.process_joystick_input(0, 0.8)
        time.sleep(2)

        print("Test 6: Joystick control - forward right")
        controller.process_joystick_input(0.5, 0.8)
        time.sleep(2)

        print("Test 7: Stop")
        controller.stop()

        print("\nAll tests completed successfully!")

    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    finally:
        controller.cleanup()
        print("Cleanup complete")
