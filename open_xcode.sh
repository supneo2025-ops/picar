#!/bin/bash
# Quick launcher for PiCar Xcode project

echo "Opening PiCar Xcode project..."
echo ""
echo "📱 Xcode project: ~/PycharmProjects/picar/ios-app/PiCar/PiCar.xcodeproj"
echo ""
echo "⚠️  IMPORTANT: Update server IP in Models/WebSocketClient.swift"
echo "   Current IP: 192.168.100.148"
echo "   For local testing: Use 'localhost' or your Mac's IP"
echo ""

# Open Xcode project
open ~/PycharmProjects/picar/ios-app/PiCar/PiCar.xcodeproj

echo "✅ Xcode should open now!"
echo ""
echo "Next steps:"
echo "1. Configure signing (select your Team)"
echo "2. Update server IP if needed"
echo "3. Build and run (Cmd+R)"
echo ""
echo "For detailed instructions, see: ios-app/PiCar/SETUP_COMPLETE.md"
