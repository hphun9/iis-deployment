# CONFIG
$imageName = "helloworld-app"
$containerName = "helloworld-container"
$hostPort = 8080

# Stop existing container if exists
docker stop $containerName -ErrorAction SilentlyContinue
docker rm $containerName -ErrorAction SilentlyContinue

# Build image (optional, if not already built)
if (Test-Path "./Dockerfile") {
    Write-Host "Building Docker image..."
    docker build -t $imageName .
}

# Run container
Write-Host "Running container on port $hostPort"
docker run -d -p $hostPort:80 --name $containerName $imageName

Write-Host "HelloWorld is now available at http://localhost:$hostPort"
