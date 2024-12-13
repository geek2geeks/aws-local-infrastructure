# set-permissions.ps1

Write-Host "Setting WSL permissions..." -ForegroundColor Cyan

$wslCmd = @"
sudo chmod -R 755 /mnt/d/models;
sudo chmod -R 755 /mnt/e/docker;
echo 'Permissions set.';
ls -la /mnt/d/models;
ls -la /mnt/e/docker
"@

wsl bash -c $wslCmd

Write-Host "Permission setup complete" -ForegroundColor Green