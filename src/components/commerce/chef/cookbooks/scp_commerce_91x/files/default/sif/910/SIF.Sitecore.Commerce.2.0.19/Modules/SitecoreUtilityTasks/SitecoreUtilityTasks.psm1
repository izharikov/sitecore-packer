Function Invoke-InstallModuleTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$ModuleFullPath,
      [Parameter(Mandatory=$true)]
      [string]$ModulesDirDst,
      [Parameter(Mandatory=$true)]
      [string]$BaseUrl
  )

  Copy-Item $ModuleFullPath -destination $ModulesDirDst -force

  $moduleToInstall = Split-Path -Path $ModuleFullPath -Leaf -Resolve


  Write-Host "Installing module: " $moduleToInstall -ForegroundColor Green ;
  $urlInstallModules = $BaseUrl + "/InstallModules.aspx?modules=" + $moduleToInstall
  Write-Host $urlInstallModules
  Invoke-RestMethod $urlInstallModules -TimeoutSec 0
}

Function Invoke-PublishToWebTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$BaseUrl
  )

  Write-Host "Publishing to web..." -ForegroundColor Green ;
  Start-Sleep -Seconds 60
  $urlPublish = $BaseUrl + "/Publish.aspx"
  Invoke-RestMethod $urlPublish -TimeoutSec 0
  Write-Host "Publishing to web complete..." -ForegroundColor Green ;
}

Function Invoke-CreateDefaultStorefrontTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$BaseUrl,
      [Parameter(Mandatory=$false)]
      [string]$scriptName = "CreateDefaultStorefrontTenantAndSite",
      [Parameter(Mandatory=$false)]
      [string]$siteName = "",
      [Parameter(Mandatory=$true)]
      [string]$sitecoreUsername,
      [Parameter(Mandatory=$true)]
      [string]$sitecoreUserPassword
  )

  if($siteName -ne "")
  {
      Write-Host "Restarting the website and application pool for $($siteName)..." -ForegroundColor Green ;
      Import-Module WebAdministration

      Stop-WebSite $siteName

      if((Get-WebAppPoolState $siteName).Value -ne 'Stopped')
       {
           Stop-WebAppPool -Name $siteName
       }

       Start-WebAppPool -Name $siteName
      Start-WebSite $siteName
      Write-Host "Restarting the website and application pool for $($siteName) complete..." -ForegroundColor Green ;
  }

  Write-Host "Creating the default storefront..." -ForegroundColor Green ;

  #Added Try catch to avoid deployment failure due to an issue in SPE 4.7.1 - Once fixed, we can remove this
  Try
  {
      $urlPowerShellScript = $BaseUrl + "/-/script/v2/master/$($scriptName)?user=$($sitecoreUsername)&password=$($sitecoreUserPassword)"
      Invoke-RestMethod $urlPowerShellScript -TimeoutSec 0
  }
  Catch
  {
      $errorMessage = $_.Exception.Message
      Write-Host "Error occured: $errorMessage..." -ForegroundColor Red;
  }

  Write-Host "Creating the default storefront complete..." -ForegroundColor Green;
}

Function Invoke-RebuildIndexesTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$BaseUrl
  )

  Write-Host "Rebuilding index 'sitecore_core_index' ..." -ForegroundColor Green ;
  $urlRebuildIndex = $BaseUrl + "/RebuildIndex.aspx?index=sitecore_core_index"
  Invoke-RestMethod $urlRebuildIndex -TimeoutSec 0
  Write-Host "Rebuilding index 'sitecore_core_index' completed." -ForegroundColor Green ;

  Write-Host "Rebuilding index 'sitecore_master_index' ..." -ForegroundColor Green ;
  $urlRebuildIndex = $BaseUrl + "/RebuildIndex.aspx?index=sitecore_master_index"
  Invoke-RestMethod $urlRebuildIndex -TimeoutSec 0
  Write-Host "Rebuilding index 'sitecore_master_index' completed." -ForegroundColor Green ;

Write-Host "Rebuilding index 'sitecore_web_index' ..." -ForegroundColor Green ; 
$urlRebuildIndex = $BaseUrl + "/RebuildIndex.aspx?index=sitecore_web_index"
Invoke-RestMethod $urlRebuildIndex -TimeoutSec 0
Write-Host "Rebuilding index 'sitecore_web_index' completed." -ForegroundColor Green ; 
}

Function Invoke-GenerateCatalogTemplatesTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$BaseUrl
  )

  Write-Host "Generating Catalog Templates ..." -ForegroundColor Green ;
  $urlGenerate = $BaseUrl + "/GenerateCatalogTemplates.aspx"
  Invoke-RestMethod $urlGenerate -TimeoutSec 0
  Write-Host "Generating Catalog Templates completed." -ForegroundColor Green ;
}

Function Invoke-DisableConfigFilesTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$ConfigDir,
      [parameter(Mandatory=$true)]
      [string[]]$ConfigFileList
  )

  foreach ($configFileName in $ConfigFileList) {
      Write-Host "Disabling config file: $configFileName" -ForegroundColor Green;
      $configFilePath = Join-Path $ConfigDir -ChildPath $configFileName
      $disabledFilePath = "$configFilePath.disabled";

      if (Test-Path $configFilePath) {
          Rename-Item -Path $configFilePath -NewName $disabledFilePath;
          Write-Host "  successfully disabled $configFilePath";
      } else {
          Write-Host "  configuration file not found." -ForegroundColor Red;
      }
  }
}
Function Invoke-EnableConfigFilesTask {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$ConfigDir,
      [parameter(Mandatory=$true)]
      [string[]]$ConfigFileList
  )

  foreach ($configFileName in $ConfigFileList) {
      Write-Host "Enabling config file: $configFileName" -ForegroundColor Green;
      $configFilePath = Join-Path $ConfigDir -ChildPath $configFileName
      $disabledFilePath = "$configFilePath.disabled";
      $exampleFilePath = "$configFilePath.example";

      if (Test-Path $configFilePath) {
          Write-Host "  config file is already enabled...";
      } elseif (Test-Path $disabledFilePath) {
          Rename-Item -Path $disabledFilePath -NewName $configFileName;
          Write-Host "  successfully enabled $disabledFilePath";
      } elseif (Test-Path $exampleFilePath) {
          Rename-Item -Path $exampleFilePath -NewName $configFileName;
          Write-Host "  successfully enabled $exampleFilePath";
      } else {
          Write-Host "  configuration file not found." -ForegroundColor Red;
      }
  }
}

Function Invoke-ExpandArchive {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$SourceZip,
      [parameter(Mandatory=$true)]
      [string]$DestinationPath
  )

  Expand-Archive $SourceZip -DestinationPath $DestinationPath -Force
}   

  
Function Invoke-NewCommerceSignedCertificateTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param
  (
      [Parameter(Mandatory)]
      [ValidateScript({$_.HasPrivateKey -eq $true})]
      [System.Security.Cryptography.X509Certificates.X509Certificate2]$Signer,
      [ValidateScript( { $_.StartsWith("Cert:\", "CurrentCultureIgnoreCase")})]
      [ValidateScript( { Test-Path $_ -Type Container })]
      [string]$CertStoreLocation = 'Cert:\LocalMachine\My',
      [ValidateNotNullOrEmpty()]
      [string]$DnsName = '127.0.0.1',
      [ValidateNotNullOrEmpty()]
      [string]$FriendlyName = "Sitecore Commerce Services SSL Certificate",
      [ValidateScript( { Test-Path $_ -Type Container })]
      [string]$Path,
      [string]$Name = 'localhost'
  )
  Write-Host "Creating self-signed certificate for $Name" -ForegroundColor Yellow                    
  $params = @{
      CertStoreLocation = $CertStoreLocation.Split('\')[1]
      DnsNames = $DnsName
      FriendlyName = $FriendlyName
      Signer = $Signer
  }
  # Get or create self-signed certificate for localhost                                        
  $certificates = Get-ChildItem -Path $CertStoreLocation -DnsName $DnsName | Where-Object { $_.FriendlyName -eq $FriendlyName }
  if ($certificates.Length -eq 0) {
      Write-Host "Create new self-signed certificate"
      NewCertificate @params
  }
  else {
      Write-Host "Reuse existing self-signed certificate"
  }
  Write-Host "Created self-signed certificate for $Name" -ForegroundColor Green
}
# This function is a complete copy from SIF/Private/Certificates.ps1 and should be removed together with Invoke-NewCommerceSignedCertificateTask later.
function NewCertificate {
  param(
      [string]$FriendlyName = "Sitecore Install Framework",
      [string[]]$DNSNames = "127.0.0.1",
      [ValidateSet("LocalMachine","CurrentUser")]
      [string]$CertStoreLocation = "LocalMachine",
      [ValidateScript({$_.HasPrivateKey})]
      [System.Security.Cryptography.X509Certificates.X509Certificate2]$Signer
  )
  # DCOM errors in System Logs are by design.
  # https://support.microsoft.com/en-gb/help/4022522/dcom-event-id-10016-is-logged-in-windows-10-and-windows-server-2016
  $date = Get-Date
  $certificateLocation = "Cert:\\$CertStoreLocation\My"
  $rootCertificateLocation = "Cert:\\$CertStoreLocation\Root"
  # Certificate Creation Location.
  $location = @{}
  if ($CertStoreLocation -eq "LocalMachine"){
      $location.MachineContext = $true
      $location.Value = 2 # Machine Context
  } else {
      $location.MachineContext = $false
      $location.Value = 1 # User Context
  }
  # RSA Object
  $rsa = New-Object -ComObject X509Enrollment.CObjectId
  $rsa.InitializeFromValue(([Security.Cryptography.Oid]"RSA").Value)
  # SHA256 Object
  $sha256 = New-Object -ComObject X509Enrollment.CObjectId
  $sha256.InitializeFromValue(([Security.Cryptography.Oid]"SHA256").Value)
  # Subject
  $subject = "CN=$($DNSNames[0]), O=DO_NOT_TRUST, OU=Created by https://www.sitecore.com"
  $subjectDN = New-Object -ComObject X509Enrollment.CX500DistinguishedName
  $subjectDN.Encode($Subject, 0x0)
  # Subject Alternative Names
  $san = New-Object -ComObject X509Enrollment.CX509ExtensionAlternativeNames
  $names = New-Object -ComObject X509Enrollment.CAlternativeNames
  foreach ($sanName in $DNSNames) {
      $name = New-Object -ComObject X509Enrollment.CAlternativeName
      $name.InitializeFromString(3,$sanName)
      $names.Add($name)
  }
  $san.InitializeEncode($names)
  # Private Key
  $privateKey = New-Object -ComObject X509Enrollment.CX509PrivateKey
  $privateKey.ProviderName = "Microsoft Enhanced RSA and AES Cryptographic Provider"
  $privateKey.Length = 2048
  $privateKey.ExportPolicy = 1 # Allow Export
  $privateKey.KeySpec = 1
  $privateKey.Algorithm = $rsa
  $privateKey.MachineContext = $location.MachineContext
  $privateKey.Create()
  # Certificate Object
  $certificate = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
  $certificate.InitializeFromPrivateKey($location.Value,$privateKey,"")
  $certificate.Subject = $subjectDN
  $certificate.NotBefore = ($date).AddDays(-1)
  if ($Signer){
      # WebServer Certificate
      # WebServer Extensions
      $usage = New-Object -ComObject X509Enrollment.CObjectIds
      $keys = '1.3.6.1.5.5.7.3.2','1.3.6.1.5.5.7.3.1' #Client Authentication, Server Authentication
      foreach($key in $keys) {
          $keyObj = New-Object -ComObject X509Enrollment.CObjectId
          $keyObj.InitializeFromValue($key)
          $usage.Add($keyObj)
      }
      $webserverEnhancedKeyUsage = New-Object -ComObject X509Enrollment.CX509ExtensionEnhancedKeyUsage
      $webserverEnhancedKeyUsage.InitializeEncode($usage)
      $webserverBasicKeyUsage = New-Object -ComObject X509Enrollment.CX509ExtensionKeyUsage
      $webserverBasicKeyUsage.InitializeEncode([Security.Cryptography.X509Certificates.X509KeyUsageFlags]"DataEncipherment")
      $webserverBasicKeyUsage.Critical = $true
      # Signing CA cert needs to be in MY Store to be read as we need the private key.
      Move-Item -Path $Signer.PsPath -Destination $certificateLocation -Confirm:$false
      $signerCertificate = New-Object -ComObject X509Enrollment.CSignerCertificate
      $signerCertificate.Initialize($location.MachineContext,0,0xc, $Signer.Thumbprint)
      # Return the signing CA cert to the original location.
      Move-Item -Path "$certificateLocation\$($Signer.PsChildName)" -Destination $Signer.PSParentPath -Confirm:$false
      # Set issuer to root CA.
      $issuer = New-Object -ComObject X509Enrollment.CX500DistinguishedName
      $issuer.Encode($signer.Issuer, 0)
      $certificate.Issuer = $issuer
      $certificate.SignerCertificate = $signerCertificate
      $certificate.NotAfter = ($date).AddDays(36500)
      $certificate.X509Extensions.Add($webserverEnhancedKeyUsage)
      $certificate.X509Extensions.Add($webserverBasicKeyUsage)
  } else {
      # Root CA
      # CA Extensions
      $rootEnhancedKeyUsage = New-Object -ComObject X509Enrollment.CX509ExtensionKeyUsage
      $rootEnhancedKeyUsage.InitializeEncode([Security.Cryptography.X509Certificates.X509KeyUsageFlags]"DigitalSignature,KeyEncipherment,KeyCertSign")
      $rootEnhancedKeyUsage.Critical = $true
      $basicConstraints = New-Object -ComObject X509Enrollment.CX509ExtensionBasicConstraints
      $basicConstraints.InitializeEncode($true,-1)
      $basicConstraints.Critical = $true
      $certificate.Issuer = $subjectDN #Same as subject for root CA
      $certificate.NotAfter = ($date).AddDays(36500)
      $certificate.X509Extensions.Add($rootEnhancedKeyUsage)
      $certificate.X509Extensions.Add($basicConstraints)
  }
  $certificate.X509Extensions.Add($san) # Add SANs to Certificate
  $certificate.SignatureInformation.HashAlgorithm = $sha256
  $certificate.AlternateSignatureAlgorithm = $false
  $certificate.Encode()
  # Insert Certificate into Store
  $enroll = New-Object -ComObject X509Enrollment.CX509enrollment
  $enroll.CertificateFriendlyName = $FriendlyName
  $enroll.InitializeFromRequest($certificate)
  $certificateData = $enroll.CreateRequest(1)
  $enroll.InstallResponse(2, $certificateData, 1, "")
  # Retrieve thumbprint from $certificateData
  $certificateByteData = [System.Convert]::FromBase64String($certificateData)
  $createdCertificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2
  $createdCertificate.Import($certificateByteData)
  # Locate newly created certificate.
  $newCertificate = Get-ChildItem -Path $certificateLocation | Where-Object {$_.Thumbprint -Like $createdCertificate.Thumbprint}
  # Move CA to root store.
  if (!$Signer){
      Move-Item -Path $newCertificate.PSPath -Destination $rootCertificateLocation
      $newCertificate = Get-ChildItem -Path $rootCertificateLocation | Where-Object {$_.Thumbprint -Like $createdCertificate.Thumbprint}
  }
  return $newCertificate
}

Register-SitecoreInstallExtension -Command Invoke-NewCommerceSignedCertificateTask -As NewCommerceSignedCertificate -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-InstallModuleTask -As InstallModule -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-PublishToWebTask -As PublishToWeb -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-RebuildIndexesTask -As RebuildIndexes -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-GenerateCatalogTemplatesTask -As GenerateCatalogTemplates -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-EnableConfigFilesTask -As EnableConfigFiles -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-DisableConfigFilesTask -As DisableConfigFiles -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-CreateDefaultStorefrontTask -As CreateDefaultStorefront -Type Task -Force

Register-SitecoreInstallExtension -Command Invoke-ExpandArchive -As ExpandArchive -Type Task -Force
