Write-Output "  Enabling IIS."
Install-WindowsFeature -name Web-Server -IncludeManagementTools | out-null

function Grant-Access {
    param($Path,
          $Principal = "IIS AppPool\DefaultAppPool") 
    
    if (!(Test-Path $Path)){
        Write-Output "  $Path does not exist. Creating it."
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
    Write-Output "  Granting read access to $Path for $Principal."
    $Acl = Get-Acl $Path
    $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Principal,
        "Read",      # [System.Security.AccessControl.FileSystemRights]
        "ContainerInherit, ObjectInherit", # [System.Security.AccessControl.InheritanceFlags]
        "None",      # [System.Security.AccessControl.PropagationFlags]
        "Allow"      # [System.Security.AccessControl.AccessControlType]
    )))
    (Get-Item $Path).SetAccessControl($Acl)
}

# Ensuring IIS has access to applications
Grant-Access -Path "C:\Octopus\Applications"

# Ensuring IIS has access to dotnet
Grant-Access -Path "C:\Program Files\dotnet"