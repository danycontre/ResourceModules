targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Required. The name of the resource group to deploy')
param deploymentPrefix string = 'AVD'

@description('Required. The location to deploy into')
param location string = deployment().location

@allowed([
    'Personal'
    'Pooled'
  ])
@description('Optional. AVD host pool type (Default: Pooled)')
param avdHostPoolType string = 'Pooled' 

@allowed([
    'BreadthFirst'
    'DepthFirst'
  ])
@description('Optional. AVD host pool load balacing type (Default: BreadthFirst)')
param avdHostPoolloadBalancerType string = 'BreadthFirst' 

@description('Optional. AVD host pool start VM on Connect (Default: true)')
param avdStartVMOnConnect bool = true

@allowed([
    'Desktop'
    'RemoteApp'
  ])
@description('Optional. AVD application group type (Default: Desktop)')
param avdApplicationGroupType string = 'Desktop' 

@description('Optional. AVD host pool Custom RDP properties')
param avdHostPoolRdpProperty string = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2'

@description('Create custom Start VM on connect role')
param createStartVmOnConnectCustomRole bool = true

@description('Create custom azure image builder role')
param createAibCustomRole bool = true

@allowed([
    'win10-21h2-office'
    'win10-21h2'
    'win11-21h2-office'
    'win11-21h2'
  ])
@description('Optional. AVD OS image source')
param avdOsImage string = 'win10-21h2' 


@description('Regions to replicate AVD images')
param avdImageRegionsReplicas array       = [
    'EastUs'
  ]

@description('Create azure image Builder managed identity')
param createAibManagedIdentity bool = true

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// =========== //
// Variable declaration //
// =========== //
var deploymentPrefixLowercase = toLower(deploymentPrefix)
var avdServiceObjectsRgName = 'rg-${deploymentPrefixLowercase}-avd-service-objects'
var avdNetworkObjectsRgName = 'rg-${deploymentPrefixLowercase}-avd-network'
var avdComputeObjectsRgName = 'rg-${deploymentPrefixLowercase}-avd-compute'
var avdStorageObjectsRgName = 'rg-${deploymentPrefixLowercase}-avd-storage'
var avdWorkSpaceName = 'avdws-${deploymentPrefixLowercase}'
var avdHostPoolName = 'avdhp-${deploymentPrefixLowercase}'
var avdApplicationGroupName = 'avdag-${deploymentPrefixLowercase}'
var aibManagedIdentityName = 'uai-${deploymentPrefixLowercase}-imagebuilder'
var imageDefinitionsTemSpecName = 'AVD-Image-Definition-${avdOsImage}'
var avdDefaulOstImage = json(loadTextContent('./Parameters/${avdOsImage}.json'))
var avdOsImageDefinitions = [
    json(loadTextContent('./Parameters/image-win10-21h2-office.json'))
    json(loadTextContent('./Parameters/image-win10-21h2.json'))
    json(loadTextContent('./Parameters/image-win11-21h2-office.json'))
    json(loadTextContent('./Parameters/image-win11-21h2.json'))
  ]

// =========== //
// Deployments //
// =========== //

// Resource groups
module avdServiceObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-ServiceObjects-RG-${time}'
     params: {
         name: avdServiceObjectsRgName
         location: location
     }
 }

 module avdNetworkObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Network-RG-${time}'
     params: {
         name: avdNetworkObjectsRgName
         location: location
     }
 }

 module avdComputeObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Compute-RG-${time}'
     params: {
         name: avdComputeObjectsRgName
         location: location
     }
 }

 module avdStorageObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Storage-RG-${time}'
     params: {
         name: avdStorageObjectsRgName
         location: location
     }
 }
//

// AVD management plane
module avdWorkSpace '../arm/Microsoft.DesktopVirtualization/workspaces/deploy.bicep' = {
    scope: resourceGroup(avdServiceObjectsRgName)
    name: 'AVD-WorkSpace-${time}'
    params: {
      name: avdWorkSpaceName
      location: location
      appGroupResourceIds: [
        avdApplicationGroup.outputs.resourceId
      ]
    }
    dependsOn: [
        avdServiceObjectsRg
        avdApplicationGroup
    ]
  }
  
  module avdHostPool '../arm/Microsoft.DesktopVirtualization/hostpools/deploy.bicep' = {
    scope: resourceGroup(avdServiceObjectsRgName)
    name: 'AVD-HostPool-${time}'
    params: {
      name: avdHostPoolName
      location: location
      hostpoolType: avdHostPoolType
      startVMOnConnect: avdStartVMOnConnect
      loadBalancerType: avdHostPoolloadBalancerType
      customRdpProperty: avdHostPoolRdpProperty
      validationEnviroment: false
    }
    dependsOn: [
        avdServiceObjectsRg
    ]
  }
  
  module avdApplicationGroup '../arm/Microsoft.DesktopVirtualization/applicationgroups/deploy.bicep' = {
    scope: resourceGroup(avdServiceObjectsRgName)
    name: 'AVD-ApplicationGroup-${time}'
    params: {
      name: avdApplicationGroupName
      location: location
      applicationGroupType: avdApplicationGroupType
      hostpoolName: avdHostPool.outputs.name
    }
    dependsOn: [
        avdServiceObjectsRg
        avdHostPool
    ]
  }
//

// Custom RBAC Roles
module startVMonConnectRole '../arm/Microsoft.Authorization/roleDefinitions/.bicep/nested_roleDefinitions_sub.bicep' = if (createStartVmOnConnectCustomRole) {
    name: 'Start-VM-on-Connect-Role-${time}'
    params: {
      subscriptionId: subscription().subscriptionId
      description: 'Start VM on connect (Custom)'
      roleName: 'Start VM on connect (Custom)'
      actions: [
        'Microsoft.Compute/virtualMachines/start/action'
        'Microsoft.Compute/virtualMachines/*/read'
      ]
      assignableScopes: [
        subscription().id
      ]
    }
  }

module azureImageBuilderRole '../arm/Microsoft.Authorization/roleDefinitions/.bicep/nested_roleDefinitions_sub.bicep' = if (createAibCustomRole) {
    name: 'Azure-Image-Builder-Role-${time}'
    params: {
      subscriptionId: subscription().subscriptionId
      description: 'Azure Image Builder (Custom)'
      roleName: 'Azure Image Builder (Custom)'
      actions: [
        'Microsoft.Compute/images/write'
        'Microsoft.Compute/images/read'
        'Microsoft.Compute/images/delete'
        'Microsoft.Compute/galleries/read'
        'Microsoft.Compute/galleries/images/read'
        'Microsoft.Compute/galleries/images/versions/read'
        'Microsoft.Compute/galleries/images/versions/write'
        'Microsoft.Storage/storageAccounts/blobServices/containers/read'
        'Microsoft.Storage/storageAccounts/blobServices/containers/write'
        'Microsoft.Storage/storageAccounts/blobServices/read'
        'Microsoft.ContainerInstance/containerGroups/read'
        'Microsoft.ContainerInstance/containerGroups/write'
        'Microsoft.ContainerInstance/containerGroups/start/action'
        'Microsoft.ManagedIdentity/userAssignedIdentities/*/read'
        'Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action'
        'Microsoft.Authorization/*/read'
        'Microsoft.Resources/deployments/read'
        'Microsoft.Resources/deploymentScripts/read'
        'Microsoft.Resources/deploymentScripts/write'
        'Microsoft.VirtualMachineImages/imageTemplates/run/action'
        'Microsoft.Network/virtualNetworks/read'
        'Microsoft.Network/virtualNetworks/subnets/join/action'
      ]
      assignableScopes: [
        subscription().id
      ]
    }
  }
//

// Managed identities
module imageBuilderManagedIdentity '../arm/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = if (createAibManagedIdentity) {
    scope: resourceGroup(avdServiceObjectsRgName)
    name: 'image-Builder-Managed-Identity-${time}'
    params: {
        name: aibManagedIdentityName
        location:location
    }
  }
//

// RBAC role Assignments
module azureImageBuilderRoleAssign '../arm/Microsoft.Authorization/roleAssignments/.bicep/nested_rbac_rg.bicep' = if (createAibCustomRole && createAibManagedIdentity) {
    name: 'Azure-Image-Builder-RoleAssign-${time}'
    scope: resourceGroup(avdServiceObjectsRgName)
    params: {
      roleDefinitionIdOrName: azureImageBuilderRole.outputs.resourceId
      principalId: imageBuilderManagedIdentity.outputs.principalId
      //resourceGroupName: resourceGroup(AvdServiceObjectsRgName)
    }
    dependsOn: [
        azureImageBuilderRole
        imageBuilderManagedIdentity
    ]
  }
//

// Azure Image Builder
module imageDefinitionTemplate 'Modules/template-image-definition.bicep' = {
    scope: resourceGroup(avdServiceObjectsRgName)
    name: 'Image-Definition-TemplateSpec-${time}'
    params: {
      templateSpecName: imageDefinitionsTemSpecName
      location: location
      templateSpecDisplayName: 'Image Builder Definition'
      buildDefinition: avdDefaulOstImage
      imageId: imageDefinitions[1].outputs.imageId
      imageRegions: avdImageRegionsReplicas
      managedIdentityId: imageBuilderManagedIdentity.outputs.principalId
      scriptUri: ''
    }
  }
//

// Azure Compute Gallery
//

// ======= //
// Outputs //
// ======= //

output avdServiceObjectsRgId string = avdServiceObjectsRg.outputs.resourceId
output adNetworkObjectsRgId string = avdNetworkObjectsRg.outputs.resourceId
output avdComputeObjectsRgId string = avdComputeObjectsRg.outputs.resourceId
output avdStorageObjectsRgId string = avdStorageObjectsRg.outputs.resourceId
output avdApplicationGroupId string = avdApplicationGroup.outputs.resourceId
output avdHPoolName string = avdHostPool.outputs.name
output azureImageBuilderRoleId string =  azureImageBuilderRole.outputs.resourceId
output aibManagedIdentityNameId string =  imageBuilderManagedIdentity.outputs.principalId
