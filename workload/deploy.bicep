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
/*
@allowed([
    'win10-21h2-office'
    'win10-21h2'
    'win11-21h2-office'
    'win11-21h2'
])
@description('Optional. AVD OS image source')
param avdOsImage string = 'win10-21h2'
*/
@description('Regions to replicate AVD images')
param avdImageRegionsReplicas array = [
    'EastUs'
]

@description('Create azure image Builder managed identity')
param createAibManagedIdentity bool = true

@description('Create new virtual network (Default: true)')
param createAvdVnet bool = true

@description('AVD virtual network address prefixes (Default: 10.0.0.0/23)')
param avdVnetworkAddressPrefixes array = [
    '10.0.0.0/23'
]

@description('AVD virtual network subnet address prefix (Default: 10.0.0.0/23)')
param avdVnetworkSubnetAddressPrefix string = '10.0.0.0/23'

@description('Provide existing virtual network hub URI')
param HubVnetId string = '/subscriptions/bf8ce47f-27f8-4e3d-9fce-ef902d0c2845/resourceGroups/d2l-network-eastus-cs01/providers/Microsoft.Network/virtualNetworks/d2l-default-eastus'

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// =========== //
// Variable declaration //
// =========== //
var deploymentPrefixLowercase = toLower(deploymentPrefix)
var locationLowercase = toLower(location)
//
// Resource groups lenth limit 90 characters')
var avdServiceObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-service-objects'
var avdNetworkObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-network'
var avdComputeObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-pool-compute'
var avdStorageObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-storage'
//var avdSharedWipRgName = 'rg-${location}-avd-shared-wip'
//var avdSharedReadyRgName = 'rg-${location}-avd-shared-ready'
var avdSharedAibRgName = 'rg-${locationLowercase}-avd-shared-aib'
var avdSharedAcgRgName = 'rg-${locationLowercase}-avd-shared-acg'
//
var avdVnetworkName = 'vnet-${locationLowercase}-avd-${deploymentPrefixLowercase}'
var avdVnetworkSubnetName = 'avd-${deploymentPrefixLowercase}'
var avdNetworksecurityGroupName = 'nsg-${locationLowercase}-avd-${deploymentPrefixLowercase}'
var avdVNetworkPeeringName = 'avd-${deploymentPrefixLowercase}-hub-${locationLowercase}'
var avdWorkSpaceName = 'avdws-${deploymentPrefixLowercase}'
var avdHostPoolName = 'avdhp-${deploymentPrefixLowercase}'
var avdApplicationGroupName = 'avdag-${deploymentPrefixLowercase}'
var aibManagedIdentityName = 'uai-avd-aib'
var imageDefinitionsTemSpecName = 'AVD-Image-Definition-${avdOsImage}'

//var avdDefaulOstImage = json(loadTextContent('./Parameters/${avdOsImage}.json'))
var avdOsImage = json(loadTextContent('./Parameters/image-win10-21h2.json'))
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
// AVD shared services subscription RGs
module avdSharedAibRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    //scope: shared sub here
    name: 'AVD-RG-AIB-${time}'
    params: {
        name: avdSharedAibRgName
        location: location
    }
}

module avdSharedAcgRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    //scope: shared sub here
    name: 'AVD-RG-ACG-${time}'
    params: {
        name: avdSharedAcgRgName
        location: location
    }
}
//
// AVD Workload subscription RGs
module avdServiceObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    //scope: workload sub here
    name: 'AVD-RG-ServiceObjects-${time}'
    params: {
        name: avdServiceObjectsRgName
        location: location
    }
}

module avdNetworkObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = if (createAvdVnet) {
    //scope: workload sub here
    name: 'AVD-RG-Network-${time}'
    params: {
        name: avdNetworkObjectsRgName
        location: location
    }
}

module avdComputeObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    //scope: workload sub here
    name: 'AVD-RG-Compute-${time}'
    params: {
        name: avdComputeObjectsRgName
        location: location
    }
}

module avdStorageObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    //scope: workload sub here
    name: 'AVD-RG-Storage-${time}'
    params: {
        name: avdStorageObjectsRgName
        location: location
    }
}
//

// Networking
module avdNetworksecurityGroup '../arm/Microsoft.Network/networkSecurityGroups/deploy.bicep' = if(createAvdVnet) {
    scope: resourceGroup(avdNetworkObjectsRgName)
    name: 'AVD-NSG-${time}'
    params: {
        name: avdNetworksecurityGroupName
        location: location
    }
    dependsOn: [
        avdNetworkObjectsRg
    ]
}

module avdVirtualNetwork '../arm/Microsoft.Network/virtualNetworks/deploy.bicep' = if(createAvdVnet) {
    scope: resourceGroup(avdNetworkObjectsRgName)
    name: 'AVD-vNet-${time}'
    params: {
        name: avdVnetworkName
        location: location
        addressPrefixes: avdVnetworkAddressPrefixes
        subnets: [
            {
                name: avdVnetworkSubnetName
                addressPrefix: avdVnetworkSubnetAddressPrefix
                privateEndpointNetworkPolicies: 'Disabled'
                privateLinkServiceNetworkPolicies: 'Enabled'
                networkSecurityGroupName: avdNetworksecurityGroupName
                //routeTableName:
            }
        ]
    }
    dependsOn: [
        avdNetworkObjectsRg
        avdNetworksecurityGroup
    ]
}

module avdVirtualNetworkPeering '../arm/Microsoft.Network/virtualNetworks/virtualNetworkPeerings/deploy.bicep' = if(createAvdVnet) {
    scope: resourceGroup(avdNetworkObjectsRgName)
    name: 'AVD-vNet-Peerings-${time}'
    params: {
        name: avdVNetworkPeeringName
        remoteVirtualNetworkId: HubVnetId
        localVnetName: avdVirtualNetwork.outputs.name
        allowForwardedTraffic: true
        allowVirtualNetworkAccess: true
        //useRemoteGateways: true
        allowGatewayTransit: false
    }
    dependsOn: [
        avdNetworkObjectsRg
        avdVirtualNetwork
    ]
}

module hubVirtualNetworkPeering '../arm/Microsoft.Network/virtualNetworks/virtualNetworkPeerings/deploy.bicep' = if(createAvdVnet) {
    scope: subscription('bf8ce47f-27f8-4e3d-9fce-ef902d0c2845')
    name: 'Hub-vNet-Peerings-${time}'
    params: {
        name: avdVNetworkPeeringName
        remoteVirtualNetworkId: avdVirtualNetwork.outputs.resourceId
        localVnetName: HubVnetId
        allowForwardedTraffic: true
        allowVirtualNetworkAccess: true
        //useRemoteGateways: true
        allowGatewayTransit: false
    }
    dependsOn: [
        avdVirtualNetworkPeering
        avdVirtualNetwork
    ]
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
        //validationEnviroment: false
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

// RBAC Roles
module startVMonConnectRole '../arm/Microsoft.Authorization/roleDefinitions/.bicep/nested_roleDefinitions_sub.bicep' = if (createStartVmOnConnectCustomRole) {
    name: 'Start-VM-on-Connect-Role-${time}'
    params: {
        subscriptionId: subscription().subscriptionId
        description: 'Start VM on connect AVD'
        roleName: 'Start VM on connect-AVD'
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
        description: 'Azure Image Builder AVD'
        roleName: 'Azure Image Builder-AVD'
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
    scope: resourceGroup(avdSharedAibRgName)
    name: 'image-Builder-Managed-Identity-${time}'
    params: {
        name: aibManagedIdentityName
        location: location
    }
}
//
/*
// RBAC role Assignments
module azureImageBuilderRoleAssign '../arm/Microsoft.Authorization/roleAssignments/.bicep/nested_rbac_rg.bicep' = if (createAibCustomRole && createAibManagedIdentity) {
    name: 'Azure-Image-Builder-RoleAssign-${time}'
    scope: resourceGroup(avdSharedAibRgName)
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
    scope: resourceGroup(avdSharedAibRgName)
    name: 'Image-Definition-TemplateSpec-${time}'
    params: {
      templateSpecName: imageDefinitionsTemSpecName
      location: location
      templateSpecDisplayName: 'Image Builder Definition ${avdOsImage}'
      buildDefinition: avdOsImage
      imageId: avdOsImageDefinitions[2].outputs.imageId
      imageRegions: avdImageRegionsReplicas
      managedIdentityId: imageBuilderManagedIdentity.outputs.principalId
      scriptUri: ''
    }
  }
//
*/
// Azure Compute Gallery
//

// ======= //
// Outputs //
// ======= //

output avdSharedAibRgId string = avdSharedAibRg.outputs.resourceId
output avdSharedAcgRgId string = avdSharedAcgRg.outputs.resourceId
output avdServiceObjectsRgId string = avdServiceObjectsRg.outputs.resourceId
output adNetworkObjectsRgId string = avdNetworkObjectsRg.outputs.resourceId
output avdComputeObjectsRgId string = avdComputeObjectsRg.outputs.resourceId
output avdStorageObjectsRgId string = avdStorageObjectsRg.outputs.resourceId
output avdApplicationGroupId string = avdApplicationGroup.outputs.resourceId
output avdHPoolName string = avdHostPool.outputs.name
output azureImageBuilderRoleId string = azureImageBuilderRole.outputs.resourceId
output aibManagedIdentityNameId string = imageBuilderManagedIdentity.outputs.principalId
output avdVirtualNetworkId string = avdVirtualNetwork.outputs.resourceId
output avdNetworksecurityGroupId string = avdNetworksecurityGroup.outputs.resourceId
output avdVirtualNetworkPeering string = avdVirtualNetworkPeering.outputs.resourceId
output hubVirtualNetworkPeering string = hubVirtualNetworkPeering.outputs.resourceId
