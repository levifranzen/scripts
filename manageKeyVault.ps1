### Powershell script to manage Azure Key vault secrets ###
# KB page to be displayed in line 59:
$KBurl = "https://example.com/kb"

Write-Host "~~ Powershell script to manage secrets from Azure Key Vault ~~"

Write-Host "---"

#Check if the Az powershell module is installed
$installedModule = Get-InstalledModule -Name Az; if ($installedModule) {Write-Host "Azure module installed"} else {Write-Host "Module not installed, refer to: https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-11.5.0#&tabs=windowspowershell&pivots=windows-psgallery";Read-Host -Prompt "Press Enter to exit";exit}

# Connect the Azure module
$context = Get-AzContext; if (!$context) {Connect-AzAccount} else {Write-Host "Already connected to Azure"}  

Write-Host "---"

# Define the Azure Key Vault
Function Choose-KeyVault {
    $keyVaults = Get-AzKeyVault
    $index = 1

    foreach ($kv in $keyVaults) {
        Write-Host "$index. $($kv.VaultName)"
        $index++
    }

    $choice = Read-Host "Choose the Key Vault"
    $choiceResult = $keyVaults[$choice - 1]
    $keyVaultResult = $choiceResult.VaultName

    Write-Host "You've selected $keyVaultResult"
    return $keyVaultResult
}

# Find secret in all Key Vaults
Function Check-Secret {
 $secretName = Read-Host -Prompt "Inform secret name to search in all Key Vaults (supports wildcard, e.g. *example*)"
 $keyVaults = Get-AzKeyVault
 foreach ($keyVault in $keyVaults) {
    $keyVaultName = $keyVault.VaultName
    $secretResult = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName
    if (!$secretResult) {
     Write-Host "Secret '$secretName' DOES NOT exists in Key Vault '$keyVaultName'"
    } else {
     Write-Host "Secret '$secretName' exists in Key Vault '$keyVaultName'";echo $secretResult.Name
    }
 }
}

# Find secret and details in specific Key Vault
Function Check-Secret-Detailed {
 $secretName = Read-Host -Prompt "Inform secret complete name to search"
 $secretResult = Get-AzKeyVaultSecret -VaultName $keyVaultResult -Name $secretName
 $secretValueText = Get-AzKeyVaultSecret -VaultName $keyVaultResult -Name $secretName -AsPlainText
  if (!$secretResult) {
    Write-Host "Secret '$secretName' DOES NOT exists in Key Vault '$keyVaultResult'"
    } else {
     echo $secretResult, "Value        : $secretValueText";echo " "
    }
}


Function Create-Secret {
 # Define the secret name and value
 Write-Host "Please, follow these instructions to define secret name: $KBurl"
 $secretName = Read-Host -Prompt "Inform the secret name to be created"
 $secretValue = Read-Host -Prompt "Inform the secret value"

 # Search for secrets with the same name
 $secretResult = Get-AzKeyVaultSecret -VaultName $keyVaultResult -Name $secretName
 if ($secretResult.Name -eq "$secretName") {
  Write-Host "Secret already exists, nothing was created";echo $secretResult.Name
} else {
 # Create a new secret in the Key Vault
 Set-AzKeyVaultSecret -VaultName $keyVaultResult -Name $secretName -SecretValue (ConvertTo-SecureString -String $secretValue -AsPlainText -Force)
 }
}

Function Bulk-Create-Secret {
# Path to the CSV file
 $csvPath = Read-Host -Prompt "Inform the absolute path of the CSV file, e.g. C:\path\to\secrets.csv
File must be in the following format:
keyVault,secretName,secretValue
keyVault-Dev,secret1,value1
keyVault-Hml,secret2,value2
keyVault-Prod,secret3,value3
CSV Path"

# Read the CSV file
 $secrets = Import-Csv -Path $csvPath

# Loop through each row in the CSV file and create secrets in the Key Vault
 foreach ($secret in $secrets) {
    $keyVault = $secret.keyVault
    $secretName = $secret.secretName
    $secretValue = $secret.secretValue
    $secretResult = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretName
    if ($secretResult.Name -eq "$secretName") {
     Write-Host "Secret already exists, nothing was created";echo $secretResult.Name "in" $keyVault
    } else {
     Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue (ConvertTo-SecureString -String $secretValue -AsPlainText -Force)
    }
 }
}

Function Delete-Secret {
 # Define the secret name you want to delete
 $secretNameToDelete = Read-Host -Prompt "Inform the secret name to be deleted"

 # Remove the specified secret from the Key Vault
 $continue = Read-Host -Prompt "You're going to delete '$secretNameToDelete' from the vault '$keyVaultResult', continue? [y/n]"
 if ($continue -eq "y") {
  Remove-AzKeyVaultSecret -VaultName $keyVaultResult -Name $secretNameToDelete 
 } else {
  Write-Host "Nothing was deleted" 
 }
}

Function Update-Secret {
 # Define the secret name and value
 $secretName = Read-Host -Prompt "Inform the secret name to be updated"
 $secretValue = Read-Host -Prompt "Inform the secret value to be updated"
 $continue = Read-Host -Prompt "You're going to update '$secretName' from the vault '$keyVaultResult', continue? [y/n]"
 if ($continue -eq "y") {
  Set-AzKeyVaultSecret -VaultName $keyVaultResult -Name $secretName 
 } else {
  Write-Host "Nothing was updated" 
 }
}

Function Bulk-Update-Secret {
# Path to the CSV file
 $csvPath = Read-Host -Prompt "Inform the absolute path of the CSV file, e.g. C:\path\to\secrets.csv
File must be in the following format:
keyVault,secretName,secretValue
keyVault-Dev,secret1,value1
keyVault-Hml,secret2,value2
keyVault-Prod,secret3,value3
CSV Path"

# Read the CSV file
 $secrets = Import-Csv -Path $csvPath

 $continue = Read-Host -Prompt "You're going to update multiple secrets, continue? [y/n]"
 if ($continue -eq "y") {
 # Loop through each row in the CSV file and create secrets in the Key Vault
 foreach ($secret in $secrets) {
    $keyVault = $secret.keyVault
    $secretName = $secret.secretName
    $secretValue = $secret.secretValue
    $secretResult = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretName
    if ($secretResult.Name -eq "$secretName") {
     Write-Host "Secret already exists, nothing was created";echo $secretResult.Name "in" $keyVault
    } else {
     Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue (ConvertTo-SecureString -String $secretValue -AsPlainText -Force)
    }
   }
 } else {
  Write-Host "Nothing was updated" 
 }
}

# Main menu
while ($true) {
    Write-Host "1. Check Secret"
    Write-Host "2. Check Secret (Detailed)"
    Write-Host "3. Create Secret"
    Write-Host "4. Bulk Create Secret"
    Write-Host "5. Update Secret"
    Write-Host "6. Bulk Update Secret"
    Write-Host "9. Delete Secret"
    Write-Host "0. Exit"

    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' {
            Check-Secret
        }
        '2' {
            $keyVaultResult=Choose-KeyVault
            Check-Secret-Detailed
        }
        '3' {
            $keyVaultResult=Choose-KeyVault
            Create-Secret
        }
        '4' {
            Bulk-Create-Secret
        }
        '5' {
            $keyVaultResult=Choose-KeyVault
            Update-Secret
        }
        '6' {
            Bulk-Update-Secret
        }
        '9' {
            $keyVaultResult=Choose-KeyVault
            Delete-Secret
        }
        '0' {
            exit
        }
        default {
            Write-Host "Invalid choice. Please select a valid option."
        }
    }
}
