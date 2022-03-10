targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Required. AVD shared services subscription ID')
param avdShrdlSubscriptionId string = ''

@description('Required. AVD wrokload subscription ID')
param avdWrklSubscriptionId string = ''

@minLength(2)
@maxLength(4)
@description('Required. The name of the resource group to deploy')
param deploymentPrefix string = 'App1'

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
param avdStartVMOnConnect bool = false

@allowed([
    'Desktop'
    'RemoteApp'
])
@description('Optional. AVD application group type (Default: Desktop)')
param avdApplicationGroupType string = 'Desktop'

@description('Optional. AVD host pool Custom RDP properties')
param avdHostPoolRdpProperty string = 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2'

@description('Optional. Fslogix file share size (Default: 5TB)')
param avdFslogixFileShareQuotaSize string = '51200'

@description('Create custom Start VM on connect role')
param createStartVmOnConnectCustomRole bool = true

@description('Required. AVD session host local credentials')
param avdVmLocalUserName string = ''
@secure()
param avdVmLocalUserPassword string = ''

@description('Required. AVD session host domain join credentials')
param avdDomainJoinUserName string = ''
@secure()
param avdDomainJoinUserPassword string = ''

@description('Optional. OU path to join AVd VMs')
param avdOuPath string = ''

@description('Id to grant access to on AVD workload key vault secrets')
param avdWrklSecretAccess string = ''

@description('Deploy new session hosts (defualt: false)')
param avdDeploySessionHosts bool = true

@minValue(1)
@maxValue(500)
@description('Cuantity of session hosts to deploy')
param avdDeploySessionHostsCount int = 1

@description('Optional. Creates an availability zone and adds the VMs to it. Cannot be used in combination with availability set nor scale set. (Defualt: true)')
param avdUseAvailabilityZones bool = true

@description('Optional. This property can be used by user in the request to enable or disable the Host Encryption for the virtual machine. This will enable the encryption for all the disks including Resource/Temp disk at host itself. For security reasons, it is recommended to set encryptionAtHost to True. Restrictions: Cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
param encryptionAtHost bool = false

@description('Session host VM size (Defualt: Standard_D2s_v4) ')
param avdSessionHostsSize string = 'Standard_D2s_v4'

@description('OS disk type for session host (Defualt: Standard_LRS) ')
param avdSessionHostDiskType string = 'Standard_LRS'

@allowed([
    'eastus'
    'eastus2'
    'westcentralus'
    'westus'
    'westus2'
    'westus3'
    'southcentralus'
    'northeurope'
    'westeurope'
    'southeastasia'
    'australiasoutheast'
    'australiaeast'
    'uksouth'
    'ukwest'
])

@description('Azure image builder location (Defualt: eastus2)')
param aiblocation string = 'eastus2'

@description('Create custom azure image builder role')
param createAibCustomRole bool = true

@allowed([
    'win10_21h2_office'
    'win10_21h2'
    'win11_21h2_office'
    'win11_21h2'
])
@description('Required. AVD OS image source (Default: win10-21h2)')
param avdOsImage string = 'win10_21h2'

@description('Set to deploy image from Azure Compute Gallery')
param useSharedImage bool

@description('Regions to replicate AVD images (Defualt: eastus2)')
param avdImageRegionsReplicas array = [
    'eastus2'
]

@description('Create azure image Builder managed identity')
param createAibManagedIdentity bool = true

@description('Create new virtual network (Default: true)')
param createAvdVnet bool

@description('Existing virtual network subscription')
param existingVnetSubscriptionId string = ''

@description('Existing virtual network resource group')
param existingVnetRgName string = ''

@description('Existing virtual network')
param existingVnetName string = ''

@description('Existing hub virtual network subscription')
param existingHubVnetSubscriptionId string

@description('Existing hub virtual network resource group')
param existingHubVnetRgName string = ''

@description('Existing hub virtual network')
param existingHubVnetName string = ''

@description('Existing virtual network subnet (subnet requires PrivateEndpointNetworkPolicies property to be disabled)')
param existingVnetSubnetName string = ''

@description('AVD virtual network address prefixes (Default: 10.0.0.0/23)')
param avdVnetworkAddressPrefixes array = [
    '10.0.0.0/23'
]

@description('AVD virtual network subnet address prefix (Default: 10.0.0.0/23)')
param avdVnetworkSubnetAddressPrefix string = '10.0.0.0/23'

@description('Are custom DNS servers accessible form the hub (defualt: true)')
param customDnsAvailable bool = true

@description('custom DNS servers IPs (defualt: 10.10.10.5, 10.10.10.6)')
param customDnsIps array = []

@description('Does the hub contains a virtual network gateway (defualt: true)')
param vNetworkGatewayOnHub bool = true

@description('Do not modify, used to set unique value for resource deployment')
param time string = utcNow()

// =========== //
// Variable declaration //
// =========== //
var deploymentPrefixLowercase = toLower(deploymentPrefix)
var locationLowercase = toLower(location)
var avdDomainJoinUserPasswordSecretName = split(avdDomainJoinUserName, '@')
var Domain = last(split(avdDomainJoinUserName, '@'))
var avdServiceObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-service-objects' // max length limit 90 characters
var avdNetworkObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-network' // max length limit 90 characters
var avdComputeObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-pool-compute' // max length limit 90 characters
var avdStorageObjectsRgName = 'rg-${locationLowercase}-avd-${deploymentPrefixLowercase}-storage' // max length limit 90 characters
var avdSharedResourcesRgName = 'rg-${locationLowercase}-avd-shared-resources'
var imageGalleryName = 'avdgallery${locationLowercase}'
var existingVnetResourceId = '/subscriptions/${existingVnetSubscriptionId}/resourceGroups/${existingVnetRgName}/providers/Microsoft.Network/virtualNetworks/${existingVnetName}'
var hubVnetId = '/subscriptions/${existingHubVnetSubscriptionId}/resourceGroups/${existingHubVnetRgName}/providers/Microsoft.Network/virtualNetworks/${existingHubVnetName}'
var avdVnetworkName = 'vnet-${locationLowercase}-avd-${deploymentPrefixLowercase}'
var avdVnetworkSubnetName = 'avd-${deploymentPrefixLowercase}'
var avdNetworksecurityGroupName = 'nsg-${locationLowercase}-avd-${deploymentPrefixLowercase}'
var avdRouteTableName = 'udr-${locationLowercase}-avd-${deploymentPrefixLowercase}'
var avdApplicationsecurityGroupName = 'asg-${locationLowercase}-avd-${deploymentPrefixLowercase}'
var avdVNetworkPeeringName = '${uniqueString(deploymentPrefixLowercase, location)}-virtualNetworkPeering-avd-${deploymentPrefixLowercase}'
var avdWorkSpaceName = 'avdws-${deploymentPrefixLowercase}'
var avdHostPoolName = 'avdhp-${deploymentPrefixLowercase}'
var avdApplicationGroupName = 'avdag-${deploymentPrefixLowercase}'
var aibManagedIdentityName = 'avd-uai-aib'
var imageDefinitionsTemSpecName = 'AVDImageDefinition_${avdOsImage}'
var imageTemplateBuildName = 'AVD-Image-Template-Build'
var avdEnterpriseApplicationId = '486795c7-d929-4b48-a99e-3c5329d4ce86' // needs to be queried.
//var hyperVGeneration = 'V2'
var avdOsImageDefinitions = {
    'win10_21h2_office': {
        name: 'Windows10_21H2_Office'
        osType: 'Windows'
        osState: 'Generalized'
        offer: 'office-365'
        publisher: 'MicrosoftWindowsDesktop'
        sku: 'win10-21h2-avd-m365'
        hyperVGeneration: 'V1'
    }
    'win10_21h2': {
        name: 'Windows10_21H2'
        osType: 'Windows'
        osState: 'Generalized'
        offer: 'Windows-10'
        publisher: 'MicrosoftWindowsDesktop'
        sku: '21h2-avd'
        hyperVGeneration: 'V1'
    }
    'win11_21h2_office': {
        name: 'Windows11_21H2'
        osType: 'Windows'
        osState: 'Generalized'
        offer: 'windows-11'
        publisher: 'MicrosoftWindowsDesktop'
        sku: 'win11-21h2-avd-m365'
        hyperVGeneration: 'V2'
    }
    'win11_21h2': {
        name: 'Windows11_21H2'
        osType: 'Windows'
        osState: 'Generalized'
        offer: 'windows-11'
        publisher: 'MicrosoftWindowsDesktop'
        sku: 'win11-21h2-avd'
        hyperVGeneration: 'V2'
    }
}

var marketPlaceGalleryWindows = {
    'win10_21h2_office': {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'office-365'
        sku: 'win10-21h2-avd-m365'
        version: 'latest'
    }

    'win10_21h2': {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '21h2-avd'
        version: 'latest'
    }

    'win11_21h2_office': {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'office-365'
        sku: 'win11-21h2-avd-m365'
        version: 'latest'
    }

    'win11_21h2': {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-21h2-avd'
        version: 'latest'
    }
}

var baseScriptUri = 'https://raw.githubusercontent.com/nataliakon/ResourceModules/AVD-Accelerator/workload/'
var fslogixScriptUri = '${baseScriptUri}Scripts/Set-FSLogixRegKeys.ps1'
var fsLogixScript = './Set-FSLogixRegKeys.ps1'
var fslogixSharePath = '\\\\${avdFslogixStorageName}.file.${environment().suffixes.storage}\\${avdFslogixFileShareName}'
var FsLogixScriptArguments = '-volumeshare ${fslogixSharePath}'
var avdAgentPackageLocation = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_01-20-2022.zip'
var avdFslogixStorageName = '${uniqueString(deploymentPrefixLowercase, locationLowercase)}fslogix${deploymentPrefixLowercase}'
var avdFslogixFileShareName = 'fslogix-${deploymentPrefixLowercase}'
var avdSharedSResourcesStorageName = '${uniqueString(deploymentPrefixLowercase, locationLowercase)}avdshared'
var avdSharedSResourcesAibContainerName = 'aib-${deploymentPrefixLowercase}'
var avdSharedSResourcesScriptsContainerName = 'scripts-${deploymentPrefixLowercase}'
var avdSharedServicesKvName = 'avd-${uniqueString(deploymentPrefixLowercase, locationLowercase)}-shared' // max length limit 24 characters
var avdWrklKvName = 'avd-${uniqueString(deploymentPrefixLowercase, locationLowercase)}-${deploymentPrefixLowercase}' // max length limit 24 characters
var avdSessionHostNamePrefix = 'avdsh-${deploymentPrefix}'
var avdAvailabilitySetName = 'avdas-${deploymentPrefix}'
var allAvailabilityZones = pickZones('Microsoft.Compute', 'virtualMachines', location, 3)

// =========== //
// Deployments //
// =========== //

// Resource groups
// AVD shared services subscription RGs
module avdSharedResourcesRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    scope: subscription(avdShrdlSubscriptionId)
    name: 'AVD-RG-Shared-Resources-${time}'
    params: {
        name: avdSharedResourcesRgName
        location: location
    }
}
// AVD Workload subscription RGs
module avdServiceObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    scope: subscription(avdWrklSubscriptionId)
    name: 'AVD-RG-ServiceObjects-${time}'
    params: {
        name: avdServiceObjectsRgName
        location: location
    }
}

module avdNetworkObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = if (createAvdVnet) {
    scope: subscription(avdWrklSubscriptionId)
    name: 'AVD-RG-Network-${time}'
    params: {
        name: avdNetworkObjectsRgName
        location: location
    }
}

module avdComputeObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    scope: subscription(avdWrklSubscriptionId)
    name: 'AVD-RG-Compute-${time}'
    params: {
        name: avdComputeObjectsRgName
        location: location
    }
}

module avdStorageObjectsRg '../arm/Microsoft.Resources/resourceGroups/deploy.bicep' = {
    scope: subscription(avdWrklSubscriptionId)
    name: 'AVD-RG-Storage-${time}'
    params: {
        name: avdStorageObjectsRgName
        location: location
    }
}
//

// Networking
module avdNetworksecurityGroup '../arm/Microsoft.Network/networkSecurityGroups/deploy.bicep' = if (createAvdVnet) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdNetworkObjectsRgName}')
    name: 'AVD-NSG-${time}'
    params: {
        name: avdNetworksecurityGroupName
        location: location
    }
    dependsOn: [
        avdNetworkObjectsRg
    ]
}

module avdApplicationSecurityGroup '../arm/Microsoft.Network/applicationSecurityGroups/deploy.bicep' = if (createAvdVnet) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdNetworkObjectsRgName}')
    name: 'AVD-ASG-${time}'
    params: {
        name: avdApplicationsecurityGroupName
        location: location
    }
    dependsOn: [
        avdNetworkObjectsRg
    ]
}

module avdRouteTable '../arm/Microsoft.Network/routeTables/deploy.bicep' = if (createAvdVnet) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdNetworkObjectsRgName}')
    name: 'AVD-UDR-${time}'
    params: {
        name: avdRouteTableName
        location: location
    }
    dependsOn: [
        avdNetworkObjectsRg
    ]
}

module avdVirtualNetwork '../arm/Microsoft.Network/virtualNetworks/deploy.bicep' = if (createAvdVnet) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdNetworkObjectsRgName}')
    name: 'AVD-vNet-${time}'
    params: {
        name: avdVnetworkName
        location: location
        addressPrefixes: avdVnetworkAddressPrefixes
        dnsServers: customDnsAvailable ? customDnsIps : []
        virtualNetworkPeerings: [
            {
                remoteVirtualNetworkId: hubVnetId
                name: avdVNetworkPeeringName
                allowForwardedTraffic: true
                allowGatewayTransit: false
                allowVirtualNetworkAccess: true
                doNotVerifyRemoteGateways: true
                useRemoteGateways: vNetworkGatewayOnHub ? true : false
                remotePeeringEnabled: true
                remotePeeringName: avdVNetworkPeeringName
                remotePeeringAllowForwardedTraffic: true
                remotePeeringAllowGatewayTransit: vNetworkGatewayOnHub ? true : false
                remotePeeringAllowVirtualNetworkAccess: true
                remotePeeringDoNotVerifyRemoteGateways: true
                remotePeeringUseRemoteGateways: false
            }
        ]
        subnets: [
            {
                name: avdVnetworkSubnetName
                addressPrefix: avdVnetworkSubnetAddressPrefix
                privateEndpointNetworkPolicies: 'Disabled'
                privateLinkServiceNetworkPolicies: 'Enabled'
                networkSecurityGroupName: avdNetworksecurityGroupName
                routeTableName: avdRouteTableName
            }
        ]
    }
    dependsOn: [
        avdNetworkObjectsRg
        avdNetworksecurityGroup
        avdApplicationSecurityGroup
        avdRouteTable
    ]
}
//

// AVD management plane
module avdWorkSpace '../arm/Microsoft.DesktopVirtualization/workspaces/deploy.bicep' = {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdServiceObjectsRgName}')
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
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdServiceObjectsRgName}')
    name: 'AVD-HostPool-${time}'
    params: {
        name: avdHostPoolName
        location: location
        hostpoolType: avdHostPoolType
        startVMOnConnect: avdStartVMOnConnect
        loadBalancerType: avdHostPoolloadBalancerType
        customRdpProperty: avdHostPoolRdpProperty
    }
    dependsOn: [
        avdServiceObjectsRg
    ]
}
/*
module hostpoolToken '../arm/Microsoft.Resources/deploymentScripts/deploy.bicep' = if (useSharedImage) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdServiceObjectsRgName}')
    name: 'AVD-Host-Pool-Token-${time}'
    params: {
        name: 'imageTemplateBuildName-${avdOsImage}'
        location: aiblocation
        azPowerShellVersion: '6.2'
        cleanupPreference: 'OnSuccess'
        userAssignedIdentities: {
            '${imageBuilderManagedIdentity.outputs.resourceId}': {}
        }
        scriptContent: ''
    }
    dependsOn: [
        avdHostPool
    ]
}
*/
module avdApplicationGroup '../arm/Microsoft.DesktopVirtualization/applicationgroups/deploy.bicep' = {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdServiceObjectsRgName}')
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
module startVMonConnectRole '../arm/Microsoft.Authorization/roleDefinitions/subscription/deploy.bicep' = if (createStartVmOnConnectCustomRole) {
    scope: subscription(avdWrklSubscriptionId)
    name: 'Start-VM-on-Connect-Role-${time}'
    params: {
        subscriptionId: avdWrklSubscriptionId
        description: 'Start VM on connect AVD'
        roleName: 'Start VM on connect - AVD'
        actions: [
            'Microsoft.Compute/virtualMachines/start/action'
            'Microsoft.Compute/virtualMachines/*/read'
        ]
        assignableScopes: [
            '/subscriptions/${avdWrklSubscriptionId}'
        ]
    }
}

module azureImageBuilderRole '../arm/Microsoft.Authorization/roleDefinitions/subscription/deploy.bicep' = if (createAibCustomRole) {
    scope: subscription(avdShrdlSubscriptionId)
    name: 'Azure-Image-Builder-Role-${time}'
    params: {
        subscriptionId: avdShrdlSubscriptionId
        description: 'Azure Image Builder AVD'
        roleName: 'Azure Image Builder - AVD'
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
            'Microsoft.VirtualMachineImages/imageTemplates/read'
            'Microsoft.Network/virtualNetworks/read'
            'Microsoft.Network/virtualNetworks/subnets/join/action'
        ]
        assignableScopes: [
            '/subscriptions/${avdShrdlSubscriptionId}'
        ]
    }
}
//

// Managed identities
module imageBuilderManagedIdentity '../arm/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = if (createAibManagedIdentity) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'image-Builder-Managed-Identity-${time}'
    params: {
        name: aibManagedIdentityName
        location: location
    }
    dependsOn: [
        avdSharedResourcesRg
    ]
}
//

// Enterprise applications
//

// RBAC role Assignments
module azureImageBuilderRoleAssign '../arm/Microsoft.Authorization/roleAssignments/resourceGroup/deploy.bicep' = if (createAibCustomRole && createAibManagedIdentity) {
    name: 'Azure-Image-Builder-RoleAssign-${time}'
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    params: {
        roleDefinitionIdOrName: createAibCustomRole ? azureImageBuilderRole.outputs.resourceId : ''
        principalId: createAibManagedIdentity ? imageBuilderManagedIdentity.outputs.principalId : ''
    }
    dependsOn: [
        azureImageBuilderRole
        imageBuilderManagedIdentity
    ]
}
/*
module azureImageBuilderRoleAssignExisting '../arm/Microsoft.Authorization/roleAssignments/.bicep/nested_rbac_rg.bicep' = if (!createAibCustomRole && createAibManagedIdentity) {
    name: 'Azure-Image-Builder-RoleAssign-${time}'
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    params: {
        roleDefinitionIdOrName: createAibCustomRole ? azureImageBuilderRole.outputs.resourceId : ''
        principalId: imageBuilderManagedIdentity.outputs.principalId
    }
    dependsOn: [
        azureImageBuilderRole
        imageBuilderManagedIdentity
    ]
}
*/
module startVMonConnectRoleAssign '../arm/Microsoft.Authorization/roleAssignments/resourceGroup/deploy.bicep' = if (createStartVmOnConnectCustomRole) {
    name: 'Start-VM-OnConnect-RoleAssign-${time}'
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdComputeObjectsRgName}')
    params: {
        roleDefinitionIdOrName: createStartVmOnConnectCustomRole ? startVMonConnectRole.outputs.resourceId : ''
        principalId: avdEnterpriseApplicationId
    }
    dependsOn: [
        avdServiceObjectsRg
        startVMonConnectRole
    ]
}

// Custom images: Azure Image Builder deployment. Azure Compute Gallery --> Image Template Definition --> Image Template --> Build and Publish Template --> Create VMs
// Azure Compute Gallery
module azureComputeGallery '../arm/Microsoft.Compute/galleries/deploy.bicep' = if (useSharedImage) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'Deploy-Azure-Compute-Gallery-${time}'
    params: {
        name: imageGalleryName
        location: location

        galleryDescription: 'Azure Virtual Desktops Images'
    }
    dependsOn: [
        avdSharedResourcesRg
    ]
}
//

// Image Template Definition
module avdImageTemplataDefinition '../arm/Microsoft.Compute/galleries/images/deploy.bicep' = if (useSharedImage) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'Deploy-AVD-Image-Template-Definition-${time}'
    params: {
        galleryName: useSharedImage ? azureComputeGallery.outputs.name : ''
        name: imageDefinitionsTemSpecName
        osState: avdOsImageDefinitions[avdOsImage].osState
        osType: avdOsImageDefinitions[avdOsImage].osType
        publisher: avdOsImageDefinitions[avdOsImage].publisher
        offer: avdOsImageDefinitions[avdOsImage].offer
        sku: avdOsImageDefinitions[avdOsImage].sku
        location: aiblocation
        hyperVGeneration: avdOsImageDefinitions[avdOsImage].hyperVGeneration
    }
    dependsOn: [
        azureComputeGallery
        avdSharedResourcesRg
    ]
}

//

// Create Image Template
module imageTemplate '../arm/Microsoft.VirtualMachineImages/imageTemplates/deploy.bicep' = if (useSharedImage) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'AVD-Deploy-Image-Template-${time}'
    params: {
        name: imageDefinitionsTemSpecName
        userMsiName: createAibManagedIdentity ? imageBuilderManagedIdentity.outputs.name : ''
        userMsiResourceGroup: createAibManagedIdentity ? imageBuilderManagedIdentity.outputs.resourceGroupName : ''
        location: aiblocation
        imageReplicationRegions: avdImageRegionsReplicas
        sigImageDefinitionId: useSharedImage ? avdImageTemplataDefinition.outputs.resourceId : ''
        customizationSteps: [
            {
                type: 'PowerShell'
                name: 'OptimizeOS'
                runElevated: true
                runAsSystem: true
                scriptUri: '${baseScriptUri}Scripts/Optimize_OS_for_AVD.ps1' // need to update value to accelerator github after
            }

            {
                type: 'WindowsRestart'
                restartCheckCommand: 'write-host "restarting post Optimizations"'
                restartTimeout: '5m'
            }

            {
                type: 'WindowsUpdate'
                searchCriteria: 'IsInstalled=0'
                filters: [
                    'exclude:$_.Title -like \'*Preview*\''
                    'include:$true'
                ]
                updateLimit: 40
            }
        ]
        imageSource: {
            type: 'PlatformImage'
            publisher: avdOsImageDefinitions[avdOsImage].publisher
            offer: avdOsImageDefinitions[avdOsImage].offer
            sku: avdOsImageDefinitions[avdOsImage].sku
            version: 'latest'
        }
    }
    dependsOn: [
        avdImageTemplataDefinition
        azureComputeGallery
        avdSharedResourcesRg
        azureImageBuilderRoleAssign
    ]
}
//

// Build Image Template
module imageTemplateBuild '../arm/Microsoft.Resources/deploymentScripts/deploy.bicep' = if (useSharedImage) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'AVD-Build-Image-Template-${time}'
    params: {
        name: 'imageTemplateBuildName-${avdOsImage}'
        location: aiblocation
        azPowerShellVersion: '6.2'
        cleanupPreference: 'OnSuccess'
        userAssignedIdentities: createAibManagedIdentity ? {
            '${imageBuilderManagedIdentity.outputs.resourceId}': {}
        } : {}
        scriptContent: useSharedImage ? imageTemplate.outputs.runThisCommand : ''
    }
    dependsOn: [
        imageTemplate
        avdSharedResourcesRg
        azureImageBuilderRoleAssign
    ]
}

// Execute Deployment script to check the status of the image build.

module imageTemplateBuildCheck '../arm/Microsoft.Resources/deploymentScripts/deploy.bicep' = if (useSharedImage) {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'AVD-Build-Image-Template-Check-Build-${time}'
    params: {
        name: 'imageTemplateBuildCheckName-${avdOsImage}'
        location: aiblocation
        timeout: 'PT6H'
        azPowerShellVersion: '7.2'
        cleanupPreference: 'OnSuccess'
        userAssignedIdentities: createAibManagedIdentity ? {
            '${imageBuilderManagedIdentity.outputs.resourceId}': {}
        } : {}
        arguments: '-resourceGroupName \'${avdSharedResourcesRgName}\' -imageTemplateName \'${imageTemplate.outputs.name}\''
        scriptContent: useSharedImage ? '''
        param(
        [string] [Parameter(Mandatory=$true)] $resourceGroupName,
        [string] [Parameter(Mandatory=$true)] $imageTemplateName
        )
            $ErrorActionPreference = "Stop"
            Install-Module -Name Az.ImageBuilder -Force
            $DeploymentScriptOutputs = @{}
        $getStatus=$(Get-AzImageBuilderTemplate -ResourceGroupName $resourceGroupName -Name $imageTemplateName)
        $status=$getStatus.LastRunStatusRunState
        $statusMessage=$getStatus.LastRunStatusMessage
            do {
            $now=(Get-Date)
            Write-Host "Getting the current time: $now"
            $getStatus=$(Get-AzImageBuilderTemplate -ResourceGroupName $resourceGroupName -Name $imageTemplateName)
            $status=$getStatus.LastRunStatusRunState
            Write-Host "Current status of the image build $imageTemplateName is: $status"
            $DeploymentScriptOutputs=$now
            $DeploymentScriptOutputs=$status
            if ($status -eq "Failed") {
                Write-Host "Build failed for image template: $imageTemplateName. Check the Packer logs"
                $DeploymentScriptOutputs="Build Failed"
                throw "Build Failed"
            }
            if ($status -eq "Canceled") {
                Write-Host "User canceled the build. Delete the Image template definition: $imageTemplateName"
                throw "User canceled the build."
            }
            if ($status -eq "Succeeded") {
                Write-Host "Success. Image template definition: $imageTemplateName is finished "
                break
            }
            # Sleep for 2 minutes
            Write-Host "Sleeping for 2 min"
            $DeploymentScriptOutputs="Sleeping for 2 minutes"
            Start-Sleep 120
        }
        until ($status -eq "Succeeded")

        ''' : ''
    }
    dependsOn: [
        imageTemplate
        avdSharedResourcesRg
        azureImageBuilderRoleAssign
        imageTemplateBuild
    ]
}

//

// Key vaults
module avdWrklKeyVault '../arm/Microsoft.KeyVault/vaults/deploy.bicep' = {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdServiceObjectsRgName}')
    name: 'AVD-Workload-KeyVault-${time}'
    params: {
        name: avdWrklKvName
        location: location
        enableRbacAuthorization: false
        softDeleteRetentionInDays: 7
        networkAcls: {
            bypass: 'AzureServices'
            defaultAction: 'Deny'
            virtualNetworkRules: []
            ipRules: []
        }
        privateEndpoints: [
            {
                subnetResourceId: createAvdVnet ? '${avdVirtualNetwork.outputs.resourceId}/subnets/${avdVnetworkSubnetName}' : '${existingVnetResourceId}/subnets/${existingVnetSubnetName}'
                service: 'vault'
            }
        ]
        secrets: {
            secureList: [
                {
                    name: 'avdVmLocalUserPassword'
                    value: avdVmLocalUserPassword
                    contentType: 'Session host local user credentials'
                }
                {
                    name: 'avdVmLocalUserName'
                    value: avdVmLocalUserName
                    contentType: 'Session host local user credentials'
                }
                {
                    name: 'avdDomainJoinUserName'
                    value: avdDomainJoinUserName
                    contentType: 'Domain join credentials'
                }
                {
                    name: 'avdDomainJoinUserPassword'
                    value: avdDomainJoinUserPassword
                    contentType: 'Domain join credentials'
                }
            ]
        }
        accessPolicies: [
            {
                objectId: avdWrklSecretAccess
                permissions: {
                    secrets: [
                        'get'
                        'list'
                    ]
                }
            }
        ]
    }
    dependsOn: [
        avdComputeObjectsRg
    ]
}

module avdSharedServicesKeyVault '../arm/Microsoft.KeyVault/vaults/deploy.bicep' = {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'AVD-Shared-Services-KeyVault-${time}'
    params: {
        name: avdSharedServicesKvName
        location: location
        enableRbacAuthorization: false
        softDeleteRetentionInDays: 7
        networkAcls: {
            bypass: 'AzureServices'
            defaultAction: 'Deny'
            virtualNetworkRules: []
            ipRules: []
        }
    }
    dependsOn: [
        avdSharedResourcesRg
    ]
}
//

// Storage
module fslogixStorage '../arm/Microsoft.Storage/storageAccounts/deploy.bicep' = {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdStorageObjectsRgName}')
    name: 'AVD-Fslogix-Storage-${time}'
    params: {
        name: avdFslogixStorageName
        location: location
        storageAccountSku: 'Premium_LRS' // ZRS not available everywhere. Change it to Param.
        allowBlobPublicAccess: false
        //azureFilesIdentityBasedAuthentication:
        storageAccountKind: 'FileStorage'
        storageAccountAccessTier: 'Hot'
        networkAcls: {
            bypass: 'AzureServices'
            defaultAction: 'Deny'
            virtualNetworkRules: []
            ipRules: []
        }
        fileServices: {
            shares: [
                {
                    name: avdFslogixFileShareName
                    shareQuota: avdFslogixFileShareQuotaSize
                }
            ]
        }
        privateEndpoints: [
            {
                subnetResourceId: createAvdVnet ? '${avdVirtualNetwork.outputs.resourceId}/subnets/${avdVnetworkSubnetName}' : '${existingVnetResourceId}/subnets/${existingVnetSubnetName}'
                service: 'file'
            }
        ]
    }
    dependsOn: [
        avdStorageObjectsRg
    ]
}

module avdSharedServicesStorage '../arm/Microsoft.Storage/storageAccounts/deploy.bicep' = {
    scope: resourceGroup('${avdShrdlSubscriptionId}', '${avdSharedResourcesRgName}')
    name: 'AVD-Shared-Services-Storage-${time}'
    params: {
        name: avdSharedSResourcesStorageName
        location: location
        storageAccountSku: avdUseAvailabilityZones ? 'Standard_ZRS' : 'Standard_LRS'
        storageAccountKind: 'StorageV2'
        blobServices: {
            containers: [
                {
                    name: avdSharedSResourcesAibContainerName
                    publicAccess: 'None'
                }
                {
                    name: avdSharedSResourcesScriptsContainerName
                    publicAccess: 'None'
                }
            ]
        }
    }
    dependsOn: [
        avdSharedResourcesRg
    ]
}
//

// Availability set
module avdAvailabilitySet '../arm/Microsoft.Compute/availabilitySets/deploy.bicep' = if (!avdUseAvailabilityZones && avdDeploySessionHosts) {
    name: 'AVD-Availability-Set-${time}'
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdComputeObjectsRgName}')
    params: {
        name: avdAvailabilitySetName
        location: location
        availabilitySetFaultDomain: 3
        availabilitySetUpdateDomain: 5
    }
    dependsOn: [
        avdComputeObjectsRg
    ]
}

// Session hosts

// Session hosts
// Call on the KV.
resource avdWrklKeyVaultget 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = if (avdDeploySessionHosts) {
    name: avdWrklKvName
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdServiceObjectsRgName}')
}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-01-14-preview' existing = {
    name: avdHostPoolName
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdServiceObjectsRgName}')
}
module avdSessionHosts '../arm/Microsoft.Compute/virtualMachines/deploy.bicep' = [for i in range(0, avdDeploySessionHostsCount): if (avdDeploySessionHosts) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdComputeObjectsRgName}')
    name: 'AVD-Session-Host-${i}-${time}'
    //wait: 30
    //retry: 5
    params: {
        name: '${avdSessionHostNamePrefix}-${i}'
        location: location
        systemAssignedIdentity: true
        //availabilityZone: avdUseAvailabilityZones ? take(skip(allAvailabilityZones, i % length(allAvailabilityZones)), 1) : avdAvailabilityZones
        availabilityZone: avdUseAvailabilityZones ? take(skip(allAvailabilityZones, i % length(allAvailabilityZones)), 1) : []
        encryptionAtHost: encryptionAtHost
        availabilitySetName: !avdUseAvailabilityZones ? (avdDeploySessionHosts ? avdAvailabilitySet.outputs.name : '') : ''
        osType: 'Windows'
        licenseType: 'Windows_Client'
        vmSize: avdSessionHostsSize
        imageReference: useSharedImage ? json('{\'id\': \'${imageTemplate.outputs.resourceId}\'}') : marketPlaceGalleryWindows[avdOsImage]
        osDisk: {
            createOption: 'fromImage'
            deleteOption: 'Delete'
            diskSizeGB: 128
            managedDisk: {
                storageAccountType: avdSessionHostDiskType
            }
        }
        adminUsername: avdVmLocalUserName
        adminPassword: avdWrklKeyVaultget.getSecret('avdVmLocalUserPassword') //avdVmLocalUserPassword // need to update to get value from KV
        nicConfigurations: [
            {
                nicSuffix: '-nic-01'
                deleteOption: 'Delete'
                asgId: createAvdVnet ? '${avdApplicationSecurityGroup.outputs.resourceId}' : null
                ipConfigurations: [
                    {
                        name: 'ipconfig01'
                        subnetId: createAvdVnet ? '${avdVirtualNetwork.outputs.resourceId}/subnets/${avdVnetworkSubnetName}' : '${existingVnetResourceId}/subnets/${existingVnetSubnetName}'
                    }
                ]
            }
        ]
        // Join domain
        allowExtensionOperations: true
        extensionDomainJoinPassword: avdWrklKeyVaultget.getSecret('avdDomainJoinUserPassword')
        extensionDomainJoinConfig: {
            enabled: true
            settings: {
                name: Domain
                ouPath: !empty(avdOuPath) ? avdOuPath : null
                user: avdDomainJoinUserName
                restart: 'true'
                options: '3'
            }
        }
        // Enable and Configure Microsoft Malware
        extensionAntiMalwareConfig: {
            enabled: true
            settings: {
                AntimalwareEnabled: true
                RealtimeProtectionEnabled: 'true'
                ScheduledScanSettings: {
                    isEnabled: 'true'
                    day: '7' // Day of the week for scheduled scan (1-Sunday, 2-Monday, ..., 7-Saturday)
                    time: '120' // When to perform the scheduled scan, measured in minutes from midnight (0-1440). For example: 0 = 12AM, 60 = 1AM, 120 = 2AM.
                    scanType: 'Quick' //Indicates whether scheduled scan setting type is set to Quick or Full (default is Quick)
                }
                Exclusions: {
                    Extensions: '*.vhd;*.vhdx'
                    Paths: '"%ProgramFiles%\\FSLogix\\Apps\\frxdrv.sys;%ProgramFiles%\\FSLogix\\Apps\\frxccd.sys;%ProgramFiles%\\FSLogix\\Apps\\frxdrvvt.sys;%TEMP%\\*.VHD;%TEMP%\\*.VHDX;%Windir%\\TEMP\\*.VHD;%Windir%\\TEMP\\*.VHDX;\\\\server\\share\\*\\*.VHD;\\\\server\\share\\*\\*.VHDX'
                    Processes: '%ProgramFiles%\\FSLogix\\Apps\\frxccd.exe;%ProgramFiles%\\FSLogix\\Apps\\frxccds.exe;%ProgramFiles%\\FSLogix\\Apps\\frxsvc.exe'
                }
            }
        }
    }
    dependsOn: [
        avdComputeObjectsRg
        avdWrklKeyVaultget
        imageTemplateBuildCheck
    ]
}]
// Add session hosts to AVD Host pool.
module addAvdHostsToHostPool '../arm/Microsoft.Compute/virtualMachines/extensions/add-avd-session-hosts.bicep' = [for i in range(0, avdDeploySessionHostsCount): if (avdDeploySessionHosts) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdComputeObjectsRgName}')
    name: 'Add-AVD-Session-Host-${i}-to-HostPool-${time}'
    params: {
        location: location
        hostPoolToken: '${hostPool.properties.registrationInfo.token}'
        name: '${avdSessionHostNamePrefix}-${i}'
        hostPoolName: avdHostPoolName
        avdAgentPackageLocation: avdAgentPackageLocation
    }
    dependsOn: [
        avdSessionHosts
    ]
}]

// Add the registry keys for Fslogix. Alternatively can be enforced via GPOs
module configureFsLogixForAvdHosts '../arm/Microsoft.Compute/virtualMachines/extensions/configure-fslogix-session-hosts.bicep' = [for i in range(0, avdDeploySessionHostsCount): if (avdDeploySessionHosts) {
    scope: resourceGroup('${avdWrklSubscriptionId}', '${avdComputeObjectsRgName}')
    name: 'Configure-FsLogix-for-${avdSessionHostNamePrefix}-${i}-${time}'
    params: {
        location: location
        name: '${avdSessionHostNamePrefix}-${i}'
        file: fsLogixScript
        FsLogixScriptArguments: FsLogixScriptArguments
        baseScriptUri: fslogixScriptUri
    }
    dependsOn: [
        avdSessionHosts
    ]
}]

//

// ======= //
// Outputs //
// ======= //
/*
output avdSharedResourcesRgId string = avdSharedResourcesRg.outputs.resourceId
output avdServiceObjectsRgId string = avdServiceObjectsRg.outputs.resourceId
output adNetworkObjectsRgId string = avdNetworkObjectsRg.outputs.resourceId
output avdComputeObjectsRgId string = avdComputeObjectsRg.outputs.resourceId
output avdStorageObjectsRgId string = avdStorageObjectsRg.outputs.resourceId
output avdApplicationGroupId string = avdApplicationGroup.outputs.resourceId
output avdHPoolId string = avdHostPool.outputs.resourceId
output azureImageBuilderRoleId string = azureImageBuilderRole.outputs.resourceId
output aibManagedIdentityNameId string = imageBuilderManagedIdentity.outputs.principalId
output avdVirtualNetworkId string = avdVirtualNetwork.outputs.resourceId
output avdNetworksecurityGroupId string = avdNetworksecurityGroup.outputs.resourceId
output fslogixStorageId string = fslogixStorage.outputs.resourceId
*/
