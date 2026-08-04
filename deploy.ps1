$ErrorActionPreference = "Stop"

Write-Host "Starting PostgreSQL container..."
docker compose up -d postgres

Write-Host "Running complete ETL pipeline..."
docker compose run --rm --build etl

Write-Host "Deployment completed successfully."
Write-Host "PostgreSQL is available at localhost:5433"