###########################################################
# outputs to a file
# but if the path does not exist, it will create it for you
###########################################################
function Out-FileForce {
    <#
        .SYNOPSIS
          Outputs to a file, if the path doesn't exist, the path is created
    #>
 PARAM($path)
 PROCESS
 {
  if(Test-Path $path)
  {
   $null = Out-File -inputObject $_ -append -filepath $path
  }
  else
  {
   $null = new-item -force -path $path -value $_ -type file
  }
 }
}
 
###########################################################
# deletes a file
###########################################################
function Remove-File {
    <#
        .SYNOPSIS
          Removes a file - checks for existance first
    #>
 PARAM($path)
 PROCESS
 {
  if(Test-Path $path)
  {
   remove-item $path
  }
 }
}
 
###########################################################
# saves credentials to file based on a "name"
# if no name,username & password are provided,
# it will be prompted
###########################################################
function Save-Credentials{
    <#
        .SYNOPSIS
          Saves credentials in the "mirko"-style
           - stored in local input directory
           - if non are provided, you are prompted
           - if non are provided, possibility to loop (returns y/n)
    #>
 PARAM(
        $name,
        $username,
        $password
    )
 PROCESS{
 
  if($name -eq $null){
   $new = $true
   $name = read-host "Name of the host"
  }
 
  if(-not $username){
   $username = read-host "Username"
  }
  if(-not $password){
   $password = read-host "Password" -assecurestring
  }else{
    $password = ConvertTo-SecureString $password -AsPlainText -Force
  }
  $usernamepath = (".\input\" + $name + "_" + "username.nonsecured")
  $passwordpath = (".\input\" + $name + "_" + "password.secured")
   
  Remove-File($usernamepath)
  Remove-File($passwordpath)
 
  Write-Output $username | Out-FileForce($usernamepath)
  Write-Output $password | convertfrom-securestring | Out-FileForce($passwordpath)
 
  if($new){
   $more = read-host "`nDo you want to create more credentials (y|n) [n]"
   return $more.ToLower()
  }
 }
 
}
###########################################################
# saves default credentials
# if no name,username & password are provided,
# it will be prompted
###########################################################
function Save-DefaultCredentials{
    <#
        .SYNOPSIS
          Saves default credentials in the "mirko"-style
           - stored in local input directory
    #>
 PARAM($username, $password)
 PROCESS{
 
  if($username -eq $null){
   $username = read-host "Username"
  }
  if($password -eq $null){
   $password = read-host "Password" -assecurestring
  }else{
    $password = ConvertTo-SecureString $password -AsPlainText -Force
  }
  $usernamepath = (".\input\username.nonsecured")
  $passwordpath = (".\input\password.secured")
   
  Remove-File($usernamepath)
  Remove-File($passwordpath)
 
  Write-Output $username | Out-FileForce($usernamepath)
  Write-Output $password | convertfrom-securestring | Out-FileForce($passwordpath)
 
 }
 
}
###########################################################
# tries to load saved credentials
# but if the path does not exist, it will prompt credentials
###########################################################
function Get-SavedCredentials {
    <#
        .SYNOPSIS
          Searched for saved credentials in the "mirko"-style
           - searches local input directory
           - falls back to default credentials in the "mirko"-style
    #>
 PARAM(
        [Parameter(Mandatory=$True)]
        [string]$name,
        [switch]$save
    )
 PROCESS{
        $pathname = $name
  $usernamepath = (".\input\" + $pathname + "_" + "username.nonsecured")
  $passwordpath = (".\input\" + $pathname + "_" + "password.secured")
  $defaultusernamepath = (".\input\username.nonsecured")
  $defaultpasswordpath = (".\input\password.secured")
  if((Test-Path $usernamepath) -and (Test-Path $passwordpath)){
   $username = get-content  $usernamepath
   $password = get-content  $passwordpath | convertto-securestring
   $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
  }else{
   if((Test-Path $defaultusernamepath) -and (Test-Path $defaultpasswordpath)){
    $username = get-content  $defaultusernamepath
    $password = get-content  $defaultpasswordpath | convertto-securestring
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
   }
   else{
    $cred = Get-Credential
    if($save){
     Save-Credentials -name $name -username $cred.UserName -password $cred.Password
    }
   }
  }
  return $cred
   
 }
}