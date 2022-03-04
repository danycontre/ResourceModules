param name string
param location string

param hostPoolName string
//@secure()
param hostPoolToken string

// This path might change.

var avdAgentPackageLocation = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_01-20-2022.zip'
/* Add session hosts to Host Pool */

resource addToHostPool 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${name}/dscextension'
  location: location
  properties: {
    publisher: 'Microsoft.PowerShell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: avdAgentPackageLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolName
        registrationInfoToken: hostPoolToken
      }
    }
  }
}
