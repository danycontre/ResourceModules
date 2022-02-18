targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Required. ID of the parent management group')
param ParentManagementGroupId string = 'c7cb8e56-3c8d-431c-a94c-866e27a25b45'

@description('Required. The name of the resource group to deploy')
param DeploymentPrefix string = 'AVD'

@description('Required. The location to deploy into')
param location string = deployment().location

@allowed([
    'Personal'
    'Pooled'
  ])
@description('Optional. AVD host pool type (Default: Pooled)')
param AVDHostPoolType string = 'Pooled' 

@allowed([
    'BreadthFirst'
    'DepthFirst'
  ])
@description('Optional. AVD host pool load balacing type (Default: BreadthFirst)')
param AVDHostPoolloadBalancerType string = 'BreadthFirst' 

@description('Optional. AVD host pool start VM on connect (Default: true)')
param AVDStartVMOnConnect bool = true

@allowed([
    'Desktop'
    'RemoteApp'
  ])
@description('Optional. AVD application group type (Default: Desktop)')
param AVDApplicationGroupType string = 'Desktop' 

@description('Optional. AVD host pool custom RDP properties')
param AVDHostPoolRdpProperty string = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2'

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// =========== //
// Variable declaration //
// =========== //

var DeploymentPrefixLowercase = toLower(DeploymentPrefix)
var AVDServiceObjectsRGName = 'rg-${DeploymentPrefixLowercase}-avd-service-objects'
var AVDNetworkObjectsRGName = 'rg-${DeploymentPrefixLowercase}-avd-network'
var AVDComputeObjectsRGName = 'rg-${DeploymentPrefixLowercase}-avd-compute'
var AVDStorageObjectsRGName = 'rg-${DeploymentPrefixLowercase}-avd-storage'
var AVDWorkSpaceName = 'avdws-${DeploymentPrefixLowercase}'
var AVDHostPoolName = 'avdhp-${DeploymentPrefixLowercase}'
var AVDApplicationGroupName = 'avdag-${DeploymentPrefixLowercase}'

// =========== //
// Deployments //
// =========== //

// Resource groups
module AVDServiceObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-ServiceObjects-RG-${time}'
     params: {
         name: AVDServiceObjectsRGName
         location: location
     }
 }

 module AVDNetworkObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Network-RG-${time}'
     params: {
         name: AVDNetworkObjectsRGName
         location: location
     }
 }

 module AVDComputeObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Compute-RG-${time}'
     params: {
         name: AVDComputeObjectsRGName
         location: location
     }
 }

 module AVDStorageObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Storage-RG-${time}'
     params: {
         name: AVDStorageObjectsRGName
         location: location
     }
 }
//

// AVD management plane
module AVDWorkSpace '../arm/Microsoft.DesktopVirtualization/workspaces/deploy.bicep' = {
    scope: resourceGroup(AVDServiceObjectsRGName)
    name: 'AVD-WorkSpace-${time}'
    params: {
      name: AVDWorkSpaceName
      location: location
      appGroupResourceIds: [
        AVDApplicationGroup.outputs.resourceId
      ]
    }
    dependsOn: [
        AVDServiceObjectsRG
        AVDApplicationGroup
    ]
  }
  
  module AVDHostPool '../arm/Microsoft.DesktopVirtualization/hostpools/deploy.bicep' = {
    scope: resourceGroup(AVDServiceObjectsRGName)
    name: 'AVD-HostPool-${time}'
    params: {
      name: AVDHostPoolName
      location: location
      hostpoolType: AVDHostPoolType
      startVMOnConnect: AVDStartVMOnConnect
      loadBalancerType: AVDHostPoolloadBalancerType
      customRdpProperty: AVDHostPoolRdpProperty
    }
    dependsOn: [
        AVDServiceObjectsRG
    ]
  }
  
  module AVDApplicationGroup '../arm/Microsoft.DesktopVirtualization/applicationgroups/deploy.bicep' = {
    scope: resourceGroup(AVDServiceObjectsRGName)
    name: 'AVD-ApplicationGroup-${time}'
    params: {
      name: AVDApplicationGroupName
      location: location
      applicationGroupType: AVDApplicationGroupType
      hostpoolName: AVDHostPool.outputs.name
    }
    dependsOn: [
        AVDServiceObjectsRG
        AVDHostPool
    ]
  }
//

// Custom RBAC Roles
module StartVMonConnectRole '../arm/Microsoft.Authorization/roleDefinitions/deploy.bicep' = {
    name: 'Start-VM-onConnect-Role-${time}'
    params: {
      subscriptionId: subscription().id
      roleName: 'Start VM on connect (Custom)'
      location: location
      actions: [
        'Microsoft.Compute/virtualMachines/start/action'
        'Microsoft.Compute/virtualMachines/*/read'
      ]
      assignableScopes: [
        subscription().id
      ]
    }
  }
  
module AzureImageBuilderRole '../arm/Microsoft.Authorization/roleDefinitions/deploy.bicep' = {
    name: 'AzureImageBuilder-Role-${time}'
    params: {
      subscriptionId: subscription().id
      roleName: 'Azure Image Builder (Custom)'
      location: location
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
//module aibRoleAssign 'Modules/role-assign.bicep' = if (createAibRole) {
//    name: 'aibRoleAssign-${time}'
//    scope: avdRg
//    params: {
//      roleDefinitionId: createAibRole ? aibRole.outputs.roleId : ''
//      principalId: imageBuilderIdentity.outputs.identityPrincipalId
//    }
//  }
//  
//  module aibRoleAssignExisting 'Modules/role-assign.bicep' = if (!createAibRole) {
//    name: 'aibRoleAssignExt-${time}'
//    scope: avdRg
//    params: {
//      roleDefinitionId: guid(aibRoleDef.Name, subscription().id)
//      principalId: imageBuilderIdentity.outputs.identityPrincipalId
//    }
//  }
//

// ======= //
// Outputs //
// ======= //

output AVDServiceObjectsRGID string = AVDServiceObjectsRG.outputs.resourceId
output AVDNetworkObjectsRGID string = AVDNetworkObjectsRG.outputs.resourceId
output AVDComputeObjectsRGID string = AVDComputeObjectsRG.outputs.resourceId
output AVDStorageObjectsRGID string = AVDStorageObjectsRG.outputs.resourceId
output AVDApplicationGroupID string = AVDApplicationGroup.outputs.resourceId
output AVDHPoolName string = AVDHostPool.outputs.name
