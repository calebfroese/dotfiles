# Windows

```
# Install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install -y git.install chezmoi
chezmoi.exe init calebfroese
chezmoi.exe apply
```


