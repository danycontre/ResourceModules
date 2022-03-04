param name string
param location string
param avdAgentPackageLocation string
param hostPoolName string
//@secure()
param hostPoolToken string

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
