"""
Camera Stream - MJPEG video streaming for Raspberry Pi Camera
Provides continuous MJPEG stream over HTTP
"""

import io
import time
import logging
from threading import Thread, Event
from typing import Generator
import config

try:
    from picamera2 import Picamera2
    from picamera2.encoders import JpegEncoder
    from picamera2.outputs import FileOutput
    PICAMERA2_AVAILABLE = True
except ImportError:
    PICAMERA2_AVAILABLE = False
    logging.warning("picamera2 not available. Camera streaming disabled.")

try:
    from PIL import Image, ImageDraw, ImageFont
    PILLOW_AVAILABLE = True
except ImportError:
    PILLOW_AVAILABLE = False


class StreamingOutput(io.BufferedIOBase):
    """
    Output class that buffers JPEG frames for streaming
    """

    def __init__(self):
        self.frame = None
        self.condition = Event()

    def write(self, buf):
        """Write frame data to buffer"""
        self.frame = buf
        self.condition.set()
        return len(buf)


class CameraStream:
    """
    Manages Raspberry Pi camera and provides MJPEG streaming
    """

    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.camera = None
        self.output = None
        self.is_initialized = False
        self.is_streaming = False

        if PICAMERA2_AVAILABLE:
            self._initialize_camera()
        else:
            self.logger.warning("Camera not available - streaming disabled")

    def _initialize_camera(self):
        """Initialize the Pi Camera with configured settings"""
        try:
            self.logger.info("Initializing camera...")

            # Create camera instance
            self.camera = Picamera2()

            # Configure camera
            camera_config = self.camera.create_video_configuration(
                main={
                    "size": config.CAMERA_RESOLUTION,
                    "format": "RGB888"
                }
            )
            self.camera.configure(camera_config)

            # Apply rotation and flip settings
            if config.CAMERA_HFLIP or config.CAMERA_VFLIP:
                transform = {
                    "hflip": config.CAMERA_HFLIP,
                    "vflip": config.CAMERA_VFLIP
                }
                self.camera.set_controls({"Transform": transform})

            # Start camera
            self.camera.start()

            self.is_initialized = True
            self.logger.info(
                f"Camera initialized: {config.CAMERA_RESOLUTION[0]}x{config.CAMERA_RESOLUTION[1]} "
                f"@ {config.CAMERA_FRAMERATE}fps"
            )

        except Exception as e:
            self.logger.error(f"Failed to initialize camera: {e}")
            self.camera = None
            raise

    def generate_frames(self) -> Generator[bytes, None, None]:
        """
        Generator that yields MJPEG frames for streaming

        Yields:
            JPEG frame data with multipart headers
        """
        self.logger.info("generate_frames() called")

        if not self.is_initialized:
            self.logger.error("Camera not initialized")
            # Return a placeholder image
            yield self._generate_placeholder_frame()
            return

        self.is_streaming = True
        frame_time = 1.0 / config.CAMERA_FRAMERATE
        self.logger.info(f"Starting frame generation, target framerate: {config.CAMERA_FRAMERATE}fps")

        try:
            frame_count = 0
            while self.is_streaming:
                start_time = time.time()

                # Capture frame
                self.logger.debug(f"Capturing frame {frame_count}...")
                frame = self.camera.capture_array()
                self.logger.debug(f"Frame captured, shape: {frame.shape if hasattr(frame, 'shape') else 'unknown'}")

                # Convert to JPEG
                jpeg_buffer = self._encode_jpeg(frame)
                self.logger.debug(f"JPEG encoded, size: {len(jpeg_buffer)} bytes")

                # Yield frame with MJPEG headers
                yield (
                    b'--frame\r\n'
                    b'Content-Type: image/jpeg\r\n\r\n' + jpeg_buffer + b'\r\n'
                )

                frame_count += 1
                if frame_count % 30 == 0:  # Log every 30 frames
                    self.logger.info(f"Streamed {frame_count} frames")

                # Maintain frame rate
                elapsed = time.time() - start_time
                sleep_time = max(0, frame_time - elapsed)
                if sleep_time > 0:
                    time.sleep(sleep_time)

        except Exception as e:
            self.logger.error(f"Error in frame generation: {e}", exc_info=True)
        finally:
            self.is_streaming = False
            self.logger.info(f"Frame generation stopped after {frame_count} frames")

    def _encode_jpeg(self, frame) -> bytes:
        """
        Encode frame as JPEG

        Args:
            frame: Numpy array of image data

        Returns:
            JPEG encoded bytes
        """
        try:
            # Convert numpy array to PIL Image
            if PILLOW_AVAILABLE:
                image = Image.fromarray(frame)

                # Encode to JPEG
                buffer = io.BytesIO()
                image.save(buffer, format='JPEG', quality=config.JPEG_QUALITY)
                return buffer.getvalue()
            else:
                # Fallback: use simple encoding if PIL not available
                # This is less efficient but works
                import cv2
                import numpy as np
                encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), config.JPEG_QUALITY]
                _, jpeg = cv2.imencode('.jpg', frame, encode_param)
                return jpeg.tobytes()

        except Exception as e:
            self.logger.error(f"Error encoding JPEG: {e}")
            return b''

    def _generate_placeholder_frame(self) -> bytes:
        """
        Generate a placeholder image when camera is not available

        Returns:
            MJPEG formatted placeholder frame
        """
        if not PILLOW_AVAILABLE:
            return b'--frame\r\nContent-Type: image/jpeg\r\n\r\n\r\n'

        try:
            # Create black image with text
            img = Image.new('RGB', (640, 480), color=(0, 0, 0))
            draw = ImageDraw.Draw(img)

            # Add text
            text = "Camera Not Available"
            text_bbox = draw.textbbox((0, 0), text)
            text_width = text_bbox[2] - text_bbox[0]
            text_height = text_bbox[3] - text_bbox[1]
            position = ((640 - text_width) // 2, (480 - text_height) // 2)
            draw.text(position, text, fill=(255, 255, 255))

            # Encode to JPEG
            buffer = io.BytesIO()
            img.save(buffer, format='JPEG', quality=80)
            jpeg_data = buffer.getvalue()

            return (
                b'--frame\r\n'
                b'Content-Type: image/jpeg\r\n\r\n' + jpeg_data + b'\r\n'
            )

        except Exception as e:
            self.logger.error(f"Error generating placeholder: {e}")
            return b'--frame\r\nContent-Type: image/jpeg\r\n\r\n\r\n'

    def get_test_frame(self) -> bytes:
        """
        Capture a single test frame

        Returns:
            JPEG encoded frame
        """
        if not self.is_initialized:
            return b''

        try:
            frame = self.camera.capture_array()
            return self._encode_jpeg(frame)
        except Exception as e:
            self.logger.error(f"Error capturing test frame: {e}")
            return b''

    def stop_streaming(self):
        """Stop the video stream"""
        self.is_streaming = False
        self.logger.info("Camera streaming stopped")

    def cleanup(self):
        """Clean up camera resources"""
        if self.camera is not None:
            try:
                self.stop_streaming()
                self.camera.stop()
                self.camera.close()
                self.logger.info("Camera cleaned up")
            except Exception as e:
                self.logger.error(f"Error cleaning up camera: {e}")


# Test code
if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format=config.LOG_FORMAT)

    print("Camera Stream Test")
    print("=" * 50)

    stream = CameraStream()

    if not stream.is_initialized:
        print("ERROR: Camera not initialized")
        print("This test must be run on a Raspberry Pi with camera module")
        exit(1)

    try:
        print("\nTest 1: Capture single frame")
        frame = stream.get_test_frame()
        if frame:
            print(f"✓ Captured frame: {len(frame)} bytes")
            # Save test frame
            with open("/tmp/test_frame.jpg", "wb") as f:
                f.write(frame)
            print("✓ Saved to /tmp/test_frame.jpg")
        else:
            print("✗ Failed to capture frame")

        print("\nTest 2: Generate streaming frames (5 seconds)")
        import threading

        frame_count = [0]

        def count_frames():
            for _ in stream.generate_frames():
                frame_count[0] += 1
                if time.time() > start_time + 5:
                    stream.stop_streaming()
                    break

        start_time = time.time()
        thread = threading.Thread(target=count_frames)
        thread.start()
        thread.join(timeout=6)

        elapsed = time.time() - start_time
        fps = frame_count[0] / elapsed
        print(f"✓ Captured {frame_count[0]} frames in {elapsed:.1f}s ({fps:.1f} fps)")

        print("\nAll tests completed successfully!")

    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    except Exception as e:
        print(f"\nTest failed: {e}")
    finally:
        stream.cleanup()
        print("Cleanup complete")
