# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Authors: Fox Mallady
# Co-Author: 
# Date Created: 7/6/2021
# Prerequesites:
# Description: This program will download files of a given type from an SFTP service. It will log the movement of those files and create an archive of those files that will self-destruct after a given amount of time. Set this with windows scheduler to periodically pull files from an SFTP service. 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

$date = Get-Date
$dateDay = Get-Date -Format "dd"

$fileType = '.json'

$userName = ''
$password = Get-Content \folder\password.txt | ConvertTo-SecureString -Key (Get-Content \\Credentials\aes.key)
# SFTP credentials (password stored in external file w/ encyrption key)

$fingerprint = ""

#shh connection info 

#folder locations

########### LOGGING & ARCHIVING ##########
$logFile = "\\some\network\file\path" + $dateDay + ".txt"
$archive = "\\some\network\file\path"
#Log file archive & location

$DatetoDelete = $date.AddDays(-27)
Get-ChildItem $logFile -Recurse  | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -force -recurse
#delete logs after 27 days. Avoids issues in Feb. 

$dateToNuke = $date.AddMonths(-6) 
# deletes archive after 6 months
Get-ChildItem $archive -Recurse  | Where-Object { $_.LastWriteTime -lt $dateToNuke } | Remove-Item -force -recurse

##########################################



Add-Type -Path "C:\lcoal\path"
# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    HostName = "" #hostname goes here
    UserName = $userName
    Password = $password #PW - probably should import from a secure file. 
    SshHostKeyFingerprint = $fingerprint
}

$sessionOptions.AddRawSettings("FSProtocol", "2")

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

     # Download files
     $transferOptions = New-Object WinSCP.TransferOptions
     $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
     $downloadFolder = "\\download\folder"
     $transferResult =
         $session.GetFiles("\*$fileType", $downloadFolder, $False, $transferOptions)
         $session.GetFiles("\*$fileType", $archive, $False, $transferOptions)
         # move files to both local folder and archive. can set $False value to $True in order to delete files after moving them. Consider using on second instance of GetFiles. 

     # Throw on any error
     $transferResult.Check()

     # Print results
     foreach ($transfer in $transferResult.Transfers)
     {
         Write-Output "Download of $($transfer.FileName) succeeded @ $date"
     }
    # Your code
}
finally
{
    $session.Dispose()
}

