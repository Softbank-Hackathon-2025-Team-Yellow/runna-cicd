# Minimal worker application for testing
import time

def main():
    print("Worker service started")
    while True:
        time.sleep(60)

if __name__ == "__main__":
    main()
