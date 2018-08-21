    [Parameter(Mandatory=$True,position=3)]$password,
    $UserPrincipalName,
    $changepw = $true
    )
 try
  {
        $count=0
	$uname = "$fname $lname"
	$User = Get-ADUser -LDAPFilter "(Name=$uname)"
   if ($User -eq $Null)
      {
        $uname1="$fname.$lname"
        $samaccountname = "$fname.$lname"
      }
  else
      {
      #$User = Get-ADUser -LDAPFilter "(Name=$uname)"
          while($user -ne $null)
        {
            $count++
            $uname = "$fname $lname $count"
            $User = Get-ADUser -LDAPFilter "(Name=$uname)"
                 if ($User -eq $Null)
                 {
                     $uname1="$fname.$lname.$count"
                     $samaccountname = "$fname.$lname.$count"
                 }
         }
      }
        $password_ss = ConvertTo-SecureString -String $password -AsPlainText -Force
        $dn = Get-ADDomain  | %{$_.DNSRoot}
        $DomainName = $dn
        $params = @{
            'SamAccountName' = $samaccountname
            'DisplayName' = $uname
            'GivenName' = $fname
            'SurName' = $lname
            'UserPrincipalName'=  $UserPrincipalName = $uname1+"@$DomainName"
            'AccountPassword' = $password_ss
            'ChangePasswordAtLogon'=$changepw
            'Enabled'=$true
            }
    New-ADUser -Name $uname @params
    Add-ADGroupMember -Identity "Users" -Members $uname1
    Add-ADGroupMember -Identity "administrators"  -Members $uname1
    Write-Host "User $uname has been successfully created with password $password "
  }
  catch
   {
      $ErrorMessage = $_.Exception.Message
      Write-Host "$ErrorMessage "
      }
    
        Import-Module ActiveDirectory
        $u_Adminuser = "vhabau\administrator"
        $u_Adminpwd = "321,ssap"
        $u_machineip="192.168.14.149"
        try
        {
                $SecurePassWord = ConvertTo-SecureString -AsPlainText $u_Adminpwd -Force
                $Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $u_Adminuser,$SecurePassWord
                $Session = New-PSSession -ComputerName $u_machineip -Credential $Cred
                $ExchServer = Invoke-Command -Session $Session -Scriptblock {param($u_machineip);hostname} -ArgumentList $u_machineip
                Remove-PSSession -Session $Session
                $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchServer/PowerShell/ -Authentication Kerberos -Credential $Cred
                Import-PSSession $ExchSession -AllowClobber > $null -WarningAction SilentlyContinue -DisableNameChecking
        }
      catch
       {
         $ErrorMessage = $_.Exception.Message
         $FailedItem = $_.Exception.ItemName
         Write-Host  "Problem in creating a session with exchange server. Error is as follows :"+$ErrorMessage
       }
try
 {

  $a=Enable-Mailbox -Identity $samaccountname
  $Mailboxes = Get-Mailbox | Foreach{$_.Name}
  if($Mailboxes -contains $uname)
     {
         Write-Host "Mailbox has been created successfully for $uname"
     }
    else
    {
     $ErrorMessage=$_.exception.message
      Write-Host "Mailbox Creation Failed:$errormessage"
    }
 }
catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
     Write-Host  "Mailbox creation failed. Error is as follows :"+ $ErrorMessage
}



##############  Script start Here ########## 
 ##############  Script start Here ##########
# $smtp variable contain the name/ip of your email server ##
# $to contain the email id whom you want to send email ###
# $from contain email of sender ###
# $Subject contain subject of the email. 
# In Body we are defining some HTML coding in to our email message body
# <b> means BOLD 
#<br> means Break go to next Line
#<a href> provide a link to the text
# <font color=red> , give the color to the font 

$smtp = "192.168.14.149"

$to = "ansibleuser@vhabau.com"

$from = "ansibleadmin@vhabau.com"

$subject = "User Creation in AD"
$body=' <html>
<head>
<title></title>
</head>
<body>
<p>&nbsp;</p>
<table style="width: 100%; border-top: 1px solid #006400; border-bottom: 1px solid #006400;">
<tbody>
<tr style="font-family: Calibri; background-color: #006400; width: 100%; color: #ffffff; text-align: center; font-size: 18px;">
<td><strong>Email Notification - AD-User Creation </strong></td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p style="font-family: Calibri; color: black;">Hi,</p>
<p style="font-family: Calibri; color: black;"><strong>AD-User</strong> has been created successfully.Following are the details. </p>
<table style="width: 60%;">
<tbody>
<tr>
<td style="font-family: Calibri; border: thin solid #C0C0C0; background-color: #f8f8ff; color: #0c090a; font-weight: bold;">User Name</td>
<td style="font-family: Calibri; border: thin solid #C0C0C0;" colspan="3">'
$body+=$uname
$body+='</td>
</tr>
<tr>
<td style="font-family: Calibri; border: thin solid #C0C0C0; background-color: #f8f8ff; color: #0c090a; font-weight: bold;">Password</td>
<td style="font-family: Calibri; border: thin solid #C0C0C0;" colspan="3">'
$body+=$password
$body+='</td>
</tr>
</tbody>
</table>
<p style="font-family: Calibri; color: black; ">Regards,<br /><b>Service Automation Team</b></p>
<p style="font-family: Calibri; font-size: small; color: black;">Note: This is a system generated email. Please do not reply to this.</p>
</body>
</html>'
send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -Priority high

