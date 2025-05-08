# Use a more complete base image to ensure system dependencies are available
FROM python:3.8-slim

# Set working directory
WORKDIR /app

# Install system dependencies for Playwright and FFmpeg
RUN apt-get update && apt-get install -y \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright and retry Chromium installation on failure
RUN pip install playwright==1.38.0
RUN python -m playwright install chromium --with-deps || \
    (echo "Retrying Chromium install..." && python -m playwright install chromium --with-deps)

# Copy the application code
COPY . .

# Expose the port (Render will override this with PORT env variable)
EXPOSE 5000

# Start the app with gunicorn (single worker for Render free tier)
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "--workers", "1", "--timeout", "300", "app:app"]