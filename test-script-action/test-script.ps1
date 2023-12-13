Enter-ActionOutputGroup -Name "Script Action Step 1"
Write-ActionOutput "Script Action Step 1" "This is the output of the first step of the script action"
Write-ActionInfo "Processing $github.repository"
Exit-ActionOutputGroup
Enter-ActionOutputGroup -Name "Script Action Step 2"
Write-ActionOutput "Script Action Step 2" "This is the output of the second step of the script action"
Exit-ActionOutputGroup
