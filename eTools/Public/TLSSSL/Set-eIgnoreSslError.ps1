<#
Author: Eric Cruz
Date: 11/09/2022
Version: 1.0
Description: Ignore Self Signed Cert warnings
#>
Function Set-eIgnoreSslError {

    if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne 'TrustAllCertsPolicy') {

        Add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

}