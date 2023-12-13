dotnet tool install --global dotnet-sonarscanner
dotnet tool install --global dotnet-coverage
dotnet restore Ploch.Common.sln
dotnet sonarscanner begin /k:"mrploch_ploch-common" /o:"mrploch" /d:sonar.login="$sonarToken" /d:sonar.cs.opencover.reportsPaths=**/CoverageResults/coverage.opencover.xml /d:sonar.host.url="https://sonarcloud.io"
dotnet build Ploch.Common.sln --no-incremental --no-restore
dotnet test Ploch.Common.sln --verbosity normal --no-build --logger "trx;LogFileName=TestOutputResults.xml" /p:CollectCoverage=true /p:CoverletOutput=./CoverageResults/ "/p:CoverletOutputFormat=cobertura%2copencover"
dotnet sonarscanner end /d:sonar.login="$env:SONAR_TOKEN"