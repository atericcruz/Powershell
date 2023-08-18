<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Test and get SSL information from a URL
Function original location: http://en-us.sysadmins.lv/Lists/Posts/Post.aspx?List=332991f0-bfed-4143-9eea-f521167d287c&ID=60
#>

Function Test-eWebServerSSL {

    [CmdletBinding()]
    
    param(
    
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$URL,
        [Parameter(Position = 1)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,
        [Parameter(Position = 2)]
        [Net.WebProxy]$Proxy,
        [Parameter(Position = 3)]
        [int]$Timeout = 15000,
        [switch]$UseUserContext
   
    )

Add-Type @"
using System;
using System.Net;
using System.Security.Cryptography.X509Certificates;
namespace PKI {
    namespace Web {
        public class WebSSL {
            public Uri OriginalURi;
            public Uri ReturnedURi;
            public X509Certificate2 Certificate;
            //public X500DistinguishedName Issuer;
            //public X500DistinguishedName Subject;
            public string Issuer;
            public string Subject;
            public string[] SubjectAlternativeNames;
            public bool CertificateIsValid;
            //public X509ChainStatus[] ErrorInformation;
            public string[] ErrorInformation;
            public HttpWebResponse Response;
        }
    }
}
"@

    $ConnectString = "https://$($url -replace 'https://'):$port"
    $WebRequest = [Net.WebRequest]::Create($ConnectString)
    $WebRequest.Proxy = $Proxy
    $WebRequest.Credentials = $null
    $WebRequest.Timeout = $Timeout
    $WebRequest.AllowAutoRedirect = $true

    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    try { 
        
        $Response = $WebRequest.GetResponse() 
    
    }
    catch {}
    
    if ($null -ne $WebRequest.ServicePoint.Certificate) {

        $Cert = [Security.Cryptography.X509Certificates.X509Certificate2]$WebRequest.ServicePoint.Certificate.Handle

        try { 
            
            $SAN = ($Cert.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.17" }).Format(0) -split ", "
        
        }
        catch { 
            
            $SAN = $null 
        
        }
        
        $Chain = New-Object Security.Cryptography.X509Certificates.X509Chain -ArgumentList (!$UseUserContext)
        
        [void]$Chain.ChainPolicy.ApplicationPolicy.Add("1.3.6.1.5.5.7.3.1")
        
        $Status = $Chain.Build($Cert)

      $Output =  New-Object PKI.Web.WebSSL -Property @{

            OriginalUri             = $ConnectString;
            ReturnedUri             = $Response.ResponseUri;
            Certificate             = $WebRequest.ServicePoint.Certificate;
            Issuer                  = $WebRequest.ServicePoint.Certificate.Issuer;
            Subject                 = $WebRequest.ServicePoint.Certificate.Subject;
            SubjectAlternativeNames = $SAN;
            CertificateIsValid      = $Status;
            Response                = $Response;
            ErrorInformation        = $Chain.ChainStatus | ForEach-Object { $_.Status }

        }

        $Chain.Reset()
        
        [Net.ServicePointManager]::ServerCertificateValidationCallback = $null

        Write-Output $Output

    }
    else {

        Write-Output $Error[0]

    }
    
}