$url = "https://lottie.host/471612cd-a65c-4ef2-ac30-74ea0f66cd82/P9llGuJ6h1.lottie"
$output = "../assets/water_animation.lottie"

# Create assets directory if it doesn't exist
$assetsDir = [System.IO.Path]::GetDirectoryName($output)
if (-not (Test-Path -Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir | Out-Null
}

# Download the file
Invoke-WebRequest -Uri $url -OutFile $output

Write-Host "Animation downloaded to $output"
