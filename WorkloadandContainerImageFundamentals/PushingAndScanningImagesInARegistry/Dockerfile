# Intentionally start with an older, slightly vulnerable base image to find some CVEs!
FROM python:3.9-slim-buster

# Set a working directory
WORKDIR /app

# Copy dependencies and install them
COPY requirements.txt .
RUN pip install --no-cache-dir \
    --trusted-host pypi.org \
    --trusted-host files.pythonhosted.org \
    -r requirements.txt

# The root cause was SSL certificate verification failing inside the container (pip couldn't validate pypi.org's cert 
# — typically a proxy with SSL inspection or an outdated CA bundle in the old slim-buster base).
# Adding --trusted-host pypi.org --trusted-host files.pythonhosted.org lets pip download over HTTPS without
# rejecting the unverifiable cert chain.

# Copy the application code
COPY app.py .

# Expose the port
EXPOSE 8080

# Command to run the application
CMD ["python", "app.py"]