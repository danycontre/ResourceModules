targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Required. The name of the resource group to deploy')
param DeploymentPrefix string = 'AVD'

@description('Optional. The location to deploy into')
param location string = deployment().location

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
var AVDWorkSpaceName = 'avdws-${DeploymentPrefixLowercase}-${time}'
var AVDHostPoolName = 'avdhp-${DeploymentPrefixLowercase}-${time}'
var AVDApplicationGroupName = 'avdag-${DeploymentPrefixLowercase}-${time}'

// =========== //
// Deployments //
// =========== //

// Resource groups
module AVDServiceObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-ServiceObjects-RG'
     params: {
         name: AVDServiceObjectsRGName
         location: location
     }
 }

 module AVDNetworkObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Network-RG'
     params: {
         name: AVDNetworkObjectsRGName
         location: location
     }
 }

 module AVDComputeObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Compute-RG'
     params: {
         name: AVDComputeObjectsRGName
         location: location
     }
 }

 module AVDStorageObjectsRG '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
  name: 'AVD-Storage-RG'
     params: {
         name: AVDStorageObjectsRGName
         location: location
     }
 }
//

// AVD management plane
module AVDWorkSpace '../arm/Microsoft.DesktopVirtualization/workspaces/deploy.bicep' = {
    scope: AVDServiceObjectsRGName
    name: AVDWorkSpaceName
    params: {
      name: 'workspace-${workspaceName}'
      appGroupResourceIds: [
        applicationGroup.outputs.appGroupResourceId
      ]
    }
  }
  
  module AVDHostPool '../arm/Microsoft.DesktopVirtualization/hostpools/deploy.bicep' = {
    scope: AVDServiceObjectsRGName
    name: AVDHostPoolName
    params: {
      name: 'hostpool-${hostPoolName}'
      hostpoolType: hostPoolType
      startVMOnConnect: true
    }
  }
  
  module AVDApplicationGroup '../arm/Microsoft.DesktopVirtualization/applicationgroups/deploy.bicep' = {
    scope: AVDServiceObjectsRGName
    name: AVDApplicationGroupName
    params: {
      appGroupType: 'Desktop'
      hostpoolName: hostPool.outputs.hostPoolName
      name: 'app-${hostPoolName}'
    }
  }
  //

// ======= //
// Outputs //
// ======= //

output AVDServiceObjectsRG string = AVDServiceObjectsRG.outputs.resourceId
output AVDNetworkObjectsRG string = AVDNetworkObjectsRG.outputs.resourceId
output AVDComputeObjectsRG string = AVDComputeObjectsRG.outputs.resourceId
output AVDStorageObjectsRG string = AVDStorageObjectsRG.outputs.resourceId
