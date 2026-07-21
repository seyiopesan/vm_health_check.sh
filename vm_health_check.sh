#!/bin/bash

# VM Health Check Script
# Analyzes CPU, Memory, and Disk Space utilization
# Usage: ./vm_health_check.sh [explain]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Threshold for health status (in percent)
THRESHOLD=60

# Flag for detailed explanation
EXPLAIN=false
if [[ "${1:-}" == "explain" ]]; then
    EXPLAIN=true
fi

# Function to get CPU utilization
get_cpu_utilization() {
    # Calculate average CPU usage over 1 second
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    echo "${cpu_usage%.*}"
}

# Function to get Memory utilization
get_memory_utilization() {
    # Get memory usage percentage
    local mem_usage=$(free | grep Mem | awk '{printf("%.0f\n", ($3/$2) * 100)}')
    echo "$mem_usage"
}

# Function to get Disk Space utilization
get_disk_utilization() {
    # Get root filesystem disk usage percentage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# Function to check if value is healthy
check_health() {
    local value=$1
    local threshold=$2
    
    if (( value < threshold )); then
        return 0  # Healthy
    else
        return 1  # Not Healthy
    fi
}

# Main script execution
echo "========================================"
echo "VM HEALTH CHECK REPORT"
echo "========================================"
echo ""

# Get all metrics
CPU_UTIL=$(get_cpu_utilization)
MEM_UTIL=$(get_memory_utilization)
DISK_UTIL=$(get_disk_utilization)

# Determine overall health
CPU_HEALTHY=false
MEM_HEALTHY=false
DISK_HEALTHY=false
OVERALL_HEALTHY=true

if check_health "$CPU_UTIL" "$THRESHOLD"; then
    CPU_HEALTHY=true
else
    OVERALL_HEALTHY=false
fi

if check_health "$MEM_UTIL" "$THRESHOLD"; then
    MEM_HEALTHY=true
else
    OVERALL_HEALTHY=false
fi

if check_health "$DISK_UTIL" "$THRESHOLD"; then
    DISK_HEALTHY=true
else
    OVERALL_HEALTHY=false
fi

# Print metrics
echo "CPU Utilization:    ${CPU_UTIL}%"
echo "Memory Utilization: ${MEM_UTIL}%"
echo "Disk Utilization:   ${DISK_UTIL}%"
echo ""

# Print health status
if $OVERALL_HEALTHY; then
    echo -e "${GREEN}[HEALTHY]${NC}"
else
    echo -e "${RED}[NOT HEALTHY]${NC}"
fi

echo ""

# Print detailed explanation if requested
if $EXPLAIN; then
    echo "========================================"
    echo "HEALTH STATUS EXPLANATION"
    echo "========================================"
    echo "Threshold: ${THRESHOLD}% (values below this are healthy)"
    echo ""
    
    # CPU Explanation
    if $CPU_HEALTHY; then
        echo -e "${GREEN}✓ CPU: HEALTHY${NC}"
        echo "  └─ CPU utilization is ${CPU_UTIL}% (below ${THRESHOLD}% threshold)"
    else
        echo -e "${RED}✗ CPU: NOT HEALTHY${NC}"
        echo "  └─ CPU utilization is ${CPU_UTIL}% (above ${THRESHOLD}% threshold)"
        echo "  └─ Recommendation: Check running processes and optimize workload"
    fi
    echo ""
    
    # Memory Explanation
    if $MEM_HEALTHY; then
        echo -e "${GREEN}✓ MEMORY: HEALTHY${NC}"
        echo "  └─ Memory utilization is ${MEM_UTIL}% (below ${THRESHOLD}% threshold)"
    else
        echo -e "${RED}✗ MEMORY: NOT HEALTHY${NC}"
        echo "  └─ Memory utilization is ${MEM_UTIL}% (above ${THRESHOLD}% threshold)"
        echo "  └─ Recommendation: Stop unnecessary services or add more RAM"
    fi
    echo ""
    
    # Disk Explanation
    if $DISK_HEALTHY; then
        echo -e "${GREEN}✓ DISK: HEALTHY${NC}"
        echo "  └─ Disk utilization is ${DISK_UTIL}% (below ${THRESHOLD}% threshold)"
    else
        echo -e "${RED}✗ DISK: NOT HEALTHY${NC}"
        echo "  └─ Disk utilization is ${DISK_UTIL}% (above ${THRESHOLD}% threshold)"
        echo "  └─ Recommendation: Clean up old files or expand disk space"
    fi
    echo ""
fi

echo "========================================"
echo ""

# Exit with appropriate status code
if $OVERALL_HEALTHY; then
    exit 0
else
    exit 1
fi
