function Create-TmpJson($Obj) {
	$FileName = [System.IO.Path]::GetTempFileName()
	ConvertTo-Json -Depth 100 $Obj | Out-File -Encoding UTF8 $FileName
	return $FileName
}

echo "ESRP_CLIENT_ID $env:ESRP_CLIENT_ID"
echo "ESRPClientId $env:ESRPClientId"
echo "ESRPAuthCertificateSubjectName $env:ESRPAuthCertificateSubjectName"
echo "ESRPCertificateSubjectName $env:ESRPCertificateSubjectName"

$Auth = Create-TmpJson @{
	Version = "1.0.0"
	AuthenticationType = "AAD_CERT"
	ClientId = $env:ESRP_CLIENT_ID
	AuthCert = @{
		SubjectName = $env:ESRPAuthCertificateSubjectName
		StoreLocation = "LocalMachine"
		StoreName = "My"
		SendX5c = "true"
	}
	RequestSigningCert = @{
		SubjectName = $env:ESRPCertificateSubjectName
		StoreLocation = "LocalMachine"
		StoreName = "My"
	}
}

$Policy = Create-TmpJson @{
	Version = "1.0.0"
}

$Input = Create-TmpJson @{
	Version = "1.0.0"
	SignBatches = @(
		@{
			SourceLocationType = "UNC"
			SignRequestFiles = @(
				@{
					SourceLocation = $args[0]
				}
			)
			SigningInfo = @{
				Operations = @(
					@{
						KeyCode = "CP-230012"
						OperationCode = "SigntoolSign"
						Parameters = @{
							OpusName = "VS Code"
							OpusInfo = "https://code.visualstudio.com/"
							Append = "/as"
							FileDigest = "/fd `"SHA256`""
							PageHash = "/NPH"
							TimeStamp = "/tr `"http://rfc3161.gtm.corp.microsoft.com/TSS/HttpTspServer`" /td sha256"
						}
						ToolName = "sign"
						ToolVersion = "1.0"
					},
					@{
						KeyCode = "CP-230012"
						OperationCode = "SigntoolVerify"
						Parameters = @{
							VerifyAll = "/all"
						}
						ToolName = "sign"
						ToolVersion = "1.0"
					}
				)
			}
		}
	)
}

$Output = [System.IO.Path]::GetTempFileName()
$ScriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

echo "--- Auth"
cat $Auth

echo "--- Policy"
cat $Policy

echo "--- Input"
cat $Input

echo "--- Output"
cat $Output

& "esrpclient.exe" Sign -a $Auth -p $Policy -i $Input -o $Output
