# Use official Python image
FROM python:3.9

WORKDIR /app

# Copy app files
COPY . .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 80 (for browser access without port suffix)
EXPOSE 80

# Run Flask app on 0.0.0.0:80
CMD ["python", "app.py"]
