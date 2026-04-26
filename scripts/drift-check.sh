#!/bin/bash


# Drift detection script
# Checks :
# - container existence (web, app, db)
# - nginx installation and status (web)
# - app port (5000)
# - PostgreSQL port (5432)


# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "===== DRIFT CHECK START ====="
echo ""

echo "Expected state:"
echo "- web container running with nginx"
echo "- app container running on port 5000"
echo "- db container running with PostgreSQL (port 5432)"
echo ""

# Check Docker
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}❌ Docker is not running. Start Docker and try again.${NC}"
  exit 1
fi

# Functions
check_container_exists() {
  docker ps -a --format '{{.Names}}' | grep -q "^$1$"
}

check_container_running() {
  docker ps --format '{{.Names}}' | grep -q "^$1$"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

# --- WEB CHECK ---
echo "Checking WEB container..."
if check_container_exists web; then
  if check_container_running web; then
    print_success "Web container is running"

    docker exec web dpkg -l | grep -q nginx
    [ $? -eq 0 ] && print_success "Nginx is installed" || print_error "Nginx is NOT installed"

    docker exec web service nginx status > /dev/null 2>&1
    [ $? -eq 0 ] && print_success "Nginx service is running" || print_error "Nginx service is NOT running"

  else
    print_error "Web container exists but is NOT running"
  fi
else
  print_error "Web container does NOT exist"
fi

echo ""

# --- APP CHECK ---
echo "Checking APP container..."
if check_container_exists app; then
  if check_container_running app; then
    print_success "App container is running"

    docker exec app ss -tuln | grep -q 5000
    [ $? -eq 0 ] && print_success "App is running on port 5000" || print_error "App is NOT running on port 5000"

  else
    print_error "App container exists but is NOT running"
  fi
else
  print_error "App container does NOT exist"
fi

echo ""

# --- DB CHECK ---
echo "Checking DB container..."
if check_container_exists db; then
  if check_container_running db; then
    print_success "DB container is running"

    docker exec db ss -tuln | grep -q 5432
    [ $? -eq 0 ] && print_success "PostgreSQL is running on port 5432" || print_error "PostgreSQL is NOT running on port 5432"

  else
    print_error "DB container exists but is NOT running"
  fi
else
  print_error "DB container does NOT exist"
fi

echo ""
echo "===== DRIFT CHECK COMPLETE ====="