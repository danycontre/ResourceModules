targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Required. The name of the resource group to deploy')
param DeploymentPrefix string = 'AVD'

@description('Required. The location to deploy into')
param location string = deployment().location

@allowed([
    'Personal'
    'Pooled'
  ])
@description('Optional. AVD host pool type (Default: Pooled)')
param AvdHostPoolType string = 'Pooled' 

@allowed([
    'BreadthFirst'
    'DepthFirst'
  ])
@description('Optional. AVD host pool load balacing type (Default: BreadthFirst)')
param AvdHostPoolloadBalancerType string = 'BreadthFirst' 

@description('Optional. AVD host pool start VM on connect (Default: true)')
param AvdStartVMOnConnect bool = true

@allowed([
    'Desktop'
    'RemoteApp'
  ])
@description('Optional. AVD application group type (Default: Desktop)')
param AvdApplicationGroupType string = 'Desktop' 

@description('Optional. AVD host pool custom RDP properties')
param AvdHostPoolRdpProperty string = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2'

@description('Create custom Start VM on Connect Role')
param CreateStartVmOnConnectCustomRole bool = true

@description('Create custom Azure Image Builder Role')
param CreateAzureImageBuilderCustomRole bool = true

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// =========== //
// Variable declaration //
// =========== //
var DeploymentPrefixLowercase = toLower(DeploymentPrefix)
var AvdServiceObjectsRgName = 'rg-${DeploymentPrefixLowercase}-avd-service-objects'
var AvdNetworkObjectsRgName = 'rg-${DeploymentPrefixLowercase}-avd-network'
var AvdComputeObjectsRgName = 'rg-${DeploymentPrefixLowercase}-avd-compute'
var AvdStorageObjectsRgName = 'rg-${DeploymentPrefixLowercase}-avd-storage'
var AvdWorkSpaceName = 'avdws-${DeploymentPrefixLowercase}'
var AvdHostPoolName = 'avdhp-${DeploymentPrefixLowercase}'
var AvdApplicationGroupName = 'avdag-${DeploymentPrefixLowercase}'

// =========== //
// Deployments //
// =========== //

// Resource groups
module AvdServiceObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-ServiceObjects-RG-${time}'
     params: {
         name: AvdServiceObjectsRgName
         location: location
     }
 }

 module AvdNetworkObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Network-RG-${time}'
     params: {
         name: AvdNetworkObjectsRgName
         location: location
     }
 }

 module AvdComputeObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Compute-RG-${time}'
     params: {
         name: AvdComputeObjectsRgName
         location: location
     }
 }

 module AvdStorageObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Storage-RG-${time}'
     params: {
         name: AvdStorageObjectsRgName
         location: location
     }
 }
//

// AVD management plane
module AvdWorkSpace '../arm/Microsoft.DesktopVirtualization/workspaces/deploy.bicep' = {
    scope: resourceGroup(AvdServiceObjectsRgName)
    name: 'AVD-WorkSpace-${time}'
    params: {
      name: AvdWorkSpaceName
      location: location
      appGroupResourceIds: [
        AvdApplicationGroup.outputs.resourceId
      ]
    }
    dependsOn: [
        AvdServiceObjectsRg
        AvdApplicationGroup
    ]
  }
  
  module AvdHostPool '../arm/Microsoft.DesktopVirtualization/hostpools/deploy.bicep' = {
    scope: resourceGroup(AvdServiceObjectsRgName)
    name: 'AVD-HostPool-${time}'
    params: {
      name: AvdHostPoolName
      location: location
      hostpoolType: AvdHostPoolType
      startVMOnConnect: AvdStartVMOnConnect
      loadBalancerType: AvdHostPoolloadBalancerType
      customRdpProperty: AvdHostPoolRdpProperty
      //validationEnviroment: false
    }
    dependsOn: [
        AvdServiceObjectsRg
    ]
  }
  
  module AvdApplicationGroup '../arm/Microsoft.DesktopVirtualization/applicationgroups/deploy.bicep' = {
    scope: resourceGroup(AvdServiceObjectsRgName)
    name: 'AVD-ApplicationGroup-${time}'
    params: {
      name: AvdApplicationGroupName
      location: location
      applicationGroupType: AvdApplicationGroupType
      hostpoolName: AvdHostPool.outputs.name
    }
    dependsOn: [
        AvdServiceObjectsRg
        AvdHostPool
    ]
  }
//

// Custom RBAC Roles
module StartVMonConnectRole '../arm/Microsoft.Authorization/roleDefinitions/.bicep/nested_roleDefinitions_sub.bicep' = if (CreateStartVmOnConnectCustomRole) {
    name: 'Start-VM-onConnect-Role-${time}'
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

module AzureImageBuilderRole '../arm/Microsoft.Authorization/roleDefinitions/.bicep/nested_roleDefinitions_sub.bicep' = if (CreateAzureImageBuilderCustomRole) {
    name: 'AzureImageBuilder-Role-${time}'
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

// RBAC role Assignments
module AzureImageBuilderRoleAssign '../arm/Microsoft.Authorization/roleAssignments/.bicep/nested_rbac_rg.bicep' = if (CreateAzureImageBuilderCustomRole) {
    name: 'AzureImageBuilder-RoleAssign-${time}'
    scope: resourceGroup(AvdServiceObjectsRgName)
    params: {
      roleDefinitionIdOrName: AzureImageBuilderRole.outputs.resourceId
      principalId: imageBuilderIdentity.outputs.identityPrincipalId
    }
  }
  
  module AzureImageBuilderRoleAssignExisting '../arm/Microsoft.Authorization/roleAssignments/.bicep/nested_rbac_rg.bicep' = if (!CreateAzureImageBuilderCustomRole) {
    name: 'AzureImageBuilder-RoleAssignExisting-${time}'
    scope: resourceGroup(AvdServiceObjectsRgName)
    params: {
      roleDefinitionId: guid(AzureImageBuilderRole.outputs.name, subscription().id)
      principalId: imageBuilderIdentity.outputs.identityPrincipalId
    }
  }
//

// ======= //
// Outputs //
// ======= //

output AvdServiceObjectsRgId string = AvdServiceObjectsRg.outputs.resourceId
output AvdNetworkObjectsRgId string = AvdNetworkObjectsRg.outputs.resourceId
output AvdComputeObjectsRgId string = AvdComputeObjectsRg.outputs.resourceId
output AvdStorageObjectsRgId string = AvdStorageObjectsRg.outputs.resourceId
output AvdApplicationGroupId string = AvdApplicationGroup.outputs.resourceId
output AvdHPoolName string = AvdHostPool.outputs.name
output AzureImageBuilderRoleId string =  AzureImageBuilderRole.outputs.resourceId
