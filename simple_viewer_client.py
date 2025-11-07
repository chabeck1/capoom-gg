#!/usr/bin/env python3
"""
Simple viewer client for Gaussian Grouping network_gui server.
Connects to the training server and allows basic camera control.
"""

import socket
import struct
import json
import sys

def connect_to_server(host='localhost', port=6009):
    """Connect to the Gaussian Grouping viewer server."""
    print(f"Connecting to {host}:{port}...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, port))
    print("✅ Connected!")
    return sock

def send_camera_params(sock, do_training=True):
    """Send camera parameters to the server."""
    # Simple camera at origin looking down -Z axis
    camera_data = {
        'do_training': do_training,
        'keep_alive': True,
        'width': 1920,
        'height': 1080,
        'view_matrix': [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, -5,
            0, 0, 0, 1
        ],
        'projection_matrix': [
            1.5, 0, 0, 0,
            0, 2.0, 0, 0,
            0, 0, -1, -0.2,
            0, 0, -1, 0
        ]
    }
    
    msg = json.dumps(camera_data).encode('utf-8')
    sock.sendall(msg + b'\n')
    print(f"📤 Sent camera params (training={'ON' if do_training else 'OFF'})")

def main():
    if len(sys.argv) > 1:
        host = sys.argv[1]
    else:
        host = 'localhost'
    
    try:
        sock = connect_to_server(host, 6009)
        
        print("\n🎮 Simple Viewer Client")
        print("Commands:")
        print("  t - Toggle training")
        print("  q - Quit")
        print()
        
        is_training = True
        
        # Send initial camera
        send_camera_params(sock, is_training)
        
        # Interactive loop
        while True:
            cmd = input("Command (t/q): ").strip().lower()
            
            if cmd == 'q':
                print("Disconnecting...")
                break
            elif cmd == 't':
                is_training = not is_training
                send_camera_params(sock, is_training)
                print(f"Training: {'ON' if is_training else 'OFF'}")
            else:
                print("Unknown command. Use 't' to toggle training or 'q' to quit.")
        
        sock.close()
        print("Disconnected.")
        
    except ConnectionRefusedError:
        print("❌ Connection refused. Make sure the viewer server is running.")
        print("   Start it with: sbatch slurm_jobs/viewer_job.slurm")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == '__main__':
    main()
