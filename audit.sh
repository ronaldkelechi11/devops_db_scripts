#!/bin/bash

# Ubuntu System Health & Speed Test Script with MB/s Conversion

# Timestamp
echo "Date: $(date +'%Y-%m-%d %H:%M:%S')"
echo

# Check RAM usage
echo "Checking RAM usage..."
ram_usage=$(free | awk '/Mem:/ {printf "%.2f%%", $3/$2 * 100}')
echo "RAM Usage: $ram_usage"
echo

# Check CPU usage
echo "Checking CPU usage..."
cpu_idle=$(top -bn1 | awk '/Cpu\(s\)/{print $8}')
cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN{printf "%.2f%%", 100 - idle}')
echo "CPU Usage: $cpu_usage"
echo

# Check Storage usage with used/total and percentage
echo "Checking storage usage..."
df -h --output=source,size,used,pcent,target | grep -v 'Use%' | while read -r line; do
  echo "$line"
done
echo

# Ensure speedtest-cli is installed
if ! command -v speedtest-cli &>/dev/null; then
  echo "speedtest-cli not found. Installing via apt..."
  sudo apt-get update && sudo apt-get install -y speedtest-cli
fi

echo "Running speed test..."
if command -v speedtest-cli &>/dev/null; then
  # Capture Mbit/s values
  read ping download upload <<< $(speedtest-cli --simple \
    | awk '/Ping/ {p=$2} /Download/ {d=$2} /Upload/ {u=$2} END{print p, d, u}')
  # Convert to MBytes/s
  download_bytes=$(awk -v dl="$download" 'BEGIN{printf "%.2f", dl/8}')
  upload_bytes=$(awk -v ul="$upload" 'BEGIN{printf "%.2f", ul/8}')
  echo "Ping: ${ping} ms | Download: ${download} Mbit/s (${download_bytes} MB/s) | Upload: ${upload} Mbit/s (${upload_bytes} MB/s)"
else
  echo "⚠️ speedtest-cli unavailable; skipping network test."
fi
echo

# Run disk write speed test
echo "Running disk write speed test..."
dd_output=$(dd if=/dev/zero of=testfile bs=1G count=1 oflag=dsync 2>&1)
disk_speed=$(echo "$dd_output" | awk -F, '/copied/ {print $3}' | xargs)
echo "Disk write speed: $disk_speed, $dd_output"
echo

# Cleanup test file
echo "Cleaning up test files..."
rm -f testfile
echo

echo "All tests completed."
