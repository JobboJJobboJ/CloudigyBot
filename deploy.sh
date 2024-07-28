#!/usr/bin/env bash

# Clean up any previous installations or environments
echo "Cleaning up previous installations..."
rm -rf venv /tmp/antenv ~/.local/lib/python3.11 ~/.local/lib/python3.12 ~/.local/bin

# Find the correct Python version
PYTHON_CMD=$(command -v python3.12 || command -v python3.11 || command -v python3.10 || command -v python3)

if [ -z "$PYTHON_CMD" ]; then
  echo "No suitable Python version found."
  exit 1
fi

echo "Using Python interpreter at: $PYTHON_CMD"

# Check if venv is available, if not install it
if ! $PYTHON_CMD -m ensurepip --version &> /dev/null; then
  echo "Installing python3-venv..."
  apt-get update && apt-get install -y python3-venv
fi

# Ensure the venv directory exists and create it if it doesn't
if [ ! -d "venv" ]; then
  echo "Creating virtual environment..."
  $PYTHON_CMD -m venv venv
  if [ $? -ne 0 ]; then
    echo "Failed to create virtual environment"
    exit 1
  fi
fi

# Ensure pip is in the PATH
export PATH=$PATH:/home/.local/bin:/home/site/wwwroot/venv/bin

# Activate the virtual environment
echo "Activating virtual environment..."
if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
  source venv/Scripts/activate
else
  echo "Error: venv activation script not found."
  exit 1
fi

# Check if the virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
  echo "Virtual environment is not activated."
  exit 1
fi

# Upgrade pip and install dependencies
echo "Upgrading pip and installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install Node.js directly if not available
if ! command -v node &> /dev/null; then
  echo "Node.js not found, installing Node.js"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install 18
  nvm use 18
fi

# Ensure Node.js version is set correctly
export PATH=$NVM_DIR/versions/node/v18.*/bin:$PATH

# Ensure frontend directory exists and restore npm packages
if [ -d "frontend" ]; then
  echo "Restoring npm packages in frontend directory..."
  cd frontend
  npm install
  if [ $? -ne 0 ]; then
    echo "Failed to restore frontend npm packages. See above for logs."
  fi
  cd ..
else
  echo "Frontend directory not found"
fi

# Ensure the application directory exists and change to it
cd /home/site/wwwroot || exit

# Copy current virtual environment to the appropriate directory
cp -r venv /tmp/antenv

# Start the application (assuming it is configured in Azure Web App settings)
echo "Deployment completed successfully."
