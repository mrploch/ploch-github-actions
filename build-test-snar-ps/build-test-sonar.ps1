if ([string]::IsNullOrWhiteSpace($env:SONAR_TOKEN)) {
    Write-Error "SONAR_TOKEN is not set. Without it the scanner authenticates anonymously and the analysis fails later with 'Not authorized or project not found'."
    exit 1
}

dotnet tool install --global dotnet-sonarscanner
dotnet tool install --global dotnet-coverage
dotnet restore Ploch.Common.sln
dotnet sonarscanner begin /k:"mrploch_ploch-common" /o:"mrploch" /d:sonar.token="$env:SONAR_TOKEN" /d:sonar.cs.opencover.reportsPaths=**/CoverageResults/coverage.opencover.xml /d:sonar.host.url="https://sonarcloud.io"
dotnet build Ploch.Common.sln --no-incremental --no-restore
dotnet test Ploch.Common.sln --verbosity normal --no-build --logger "trx;LogFileName=TestOutputResults.xml" /p:CollectCoverage=true /p:CoverletOutput=./CoverageResults/ "/p:CoverletOutputFormat=cobertura%2copencover"
dotnet sonarscanner end /d:sonar.token="$env:SONAR_TOKEN"