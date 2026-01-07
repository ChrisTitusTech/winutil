# Set Services to Manual

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Turns a bunch of system services to manual that don't need to be running all the time. This is pretty harmless as if the service is needed, it will simply start on demand.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Set Services to Manual",
  "Description": "Turns a bunch of system services to manual that don't need to be running all the time. This is pretty harmless as if the service is needed, it will simply start on demand.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a014_",
  "service": [
    {
      "Name": "AJRouter",
      "StartupType": "Disabled",
      "OriginalType": "Manual"
    },
    {
      "Name": "ALG",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "AppIDSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "AppMgmt",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "AppReadiness",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "AppVClient",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "AppXSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Appinfo",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "AssignedAccessManagerSvc",
      "StartupType": "Disabled",
      "OriginalType": "Manual"
    },
    {
      "Name": "AudioEndpointBuilder",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AudioSrv",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Audiosrv",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AxInstSV",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "BDESVC",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "BFE",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "BITS",
      "StartupType": "AutomaticDelayedStart",
      "OriginalType": "Automatic"
    },
    {
      "Name": "BTAGService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "BcastDVRUserService_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "BluetoothUserService_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "BrokerInfrastructure",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Browser",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "BthAvctpSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "BthHFSrv",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CDPSvc",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CDPUserSvc_*",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "COMSysApp",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "CaptureService_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "CertPropSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "ClipSVC",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "ConsentUxUserSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "CoreMessagingRegistrar",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CredentialEnrollmentManagerUserSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "CryptSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CscService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DPS",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DcomLaunch",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DcpSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DevQueryBroker",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DeviceAssociationBrokerSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DeviceAssociationService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DeviceInstall",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DevicePickerUserSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DevicesFlowUserSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Dhcp",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DiagTrack",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DialogBlockingService",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "DispBrokerDesktopSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DisplayEnhancementService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DmEnrollmentSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Dnscache",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DoSvc",
      "StartupType": "AutomaticDelayedStart",
      "OriginalType": "Automatic"
    },
    {
      "Name": "DsSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DsmSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "DusmSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "EFS",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "EapHost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "EntAppSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "EventLog",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "EventSystem",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "FDResPub",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Fax",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "FontCache",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "FrameServer",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "FrameServerMonitor",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "GraphicsPerfSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "HomeGroupListener",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "HomeGroupProvider",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "HvHost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "IEEtwCollectorService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "IKEEXT",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "InstallService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "InventorySvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "IpxlatCfgSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "KeyIso",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "KtmRm",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "LSM",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "LanmanServer",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "LanmanWorkstation",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "LicenseManager",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "LxpSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MSDTC",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MSiSCSI",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MapsBroker",
      "StartupType": "AutomaticDelayedStart",
      "OriginalType": "Automatic"
    },
    {
      "Name": "McpManagementService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MessagingService_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MicrosoftEdgeElevationService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MixedRealityOpenXRSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "MpsSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "MsKeyboardFilter",
      "StartupType": "Manual",
      "OriginalType": "Disabled"
    },
    {
      "Name": "NPSMSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NaturalAuthentication",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NcaSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NcbService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NcdAutoSetup",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NetSetupSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NetTcpPortSharing",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "Netlogon",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Netman",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NgcCtnrSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NgcSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "NlaSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "OneSyncSvc_*",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "P9RdrService_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PNRPAutoReg",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PNRPsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PcaSvc",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "PeerDistSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PenService_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PerfHost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PhoneSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PimIndexMaintenanceSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PlugPlay",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PolicyAgent",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Power",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "PrintNotify",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "PrintWorkflowUserSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "ProfSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "PushToInstall",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "QWAVE",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "RasAuto",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "RasMan",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "RemoteAccess",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "RemoteRegistry",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "RetailDemo",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "RmSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "RpcEptMapper",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "RpcLocator",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "RpcSs",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SCPolicySvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SCardSvr",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SDRSVC",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SEMgrSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SENS",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SNMPTRAP",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SNMPTrap",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SSDPSRV",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SamSs",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "ScDeviceEnum",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Schedule",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SecurityHealthService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Sense",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SensorDataService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SensorService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SensrSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SessionEnv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SgrmBroker",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SharedAccess",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "SharedRealitySvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "ShellHWDetection",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SmsRouter",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Spooler",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SstpSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "StateRepository",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "StiSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "StorSvc",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SysMain",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "SystemEventsBroker",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "TabletInputService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TapiSrv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TermService",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "TextInputManagementService",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Themes",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "TieringEngineService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TimeBroker",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TimeBrokerSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TokenBroker",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TrkWks",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "TroubleshootingSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "TrustedInstaller",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "UI0Detect",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "UdkUserSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "UevAgentService",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "UmRdpService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "UnistoreSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "UserDataSvc_*",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "UserManager",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "UsoSvc",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "VGAuthService",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "VMTools",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "VSS",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "VacSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "VaultSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "W32Time",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WEPHOSTSVC",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WFDSConMgrSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WMPNetworkSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WManSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WPDBusEnum",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WSService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WSearch",
      "StartupType": "AutomaticDelayedStart",
      "OriginalType": "Automatic"
    },
    {
      "Name": "WaaSMedicSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WalletService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WarpJITSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WbioSrvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Wcmsvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "WcsPlugInService",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WdNisSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WdiServiceHost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WdiSystemHost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WebClient",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Wecsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WerSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WiaRpc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WinDefend",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "WinHttpAutoProxySvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WinRM",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "Winmgmt",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "WlanSvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "WpcMonSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "WpnService",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "WpnUserService_*",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "XblAuthManager",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "XblGameSave",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "XboxGipSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "XboxNetApiSvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "autotimesvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "bthserv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "camsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "cbdhsvc_*",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "cloudidsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "dcsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "defragsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "diagnosticshub.standardcollector.service",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "diagsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "dmwappushservice",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "dot3svc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "edgeupdate",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "edgeupdatem",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "embeddedmode",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "fdPHost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "fhsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "gpsvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "hidserv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "icssvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "iphlpsvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "lfsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "lltdsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "lmhosts",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "mpssvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "msiserver",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "netprofm",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "nsi",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "p2pimsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "p2psvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "perceptionsimulation",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "pla",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "seclogon",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "shpamsvc",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "smphost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "spectrum",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "sppsvc",
      "StartupType": "AutomaticDelayedStart",
      "OriginalType": "Automatic"
    },
    {
      "Name": "ssh-agent",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "svsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "swprv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "tiledatamodelsvc",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "tzautoupdate",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "uhssvc",
      "StartupType": "Disabled",
      "OriginalType": "Disabled"
    },
    {
      "Name": "upnphost",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vds",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vm3dservice",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "vmicguestinterface",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmicheartbeat",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmickvpexchange",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmicrdv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmicshutdown",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmictimesync",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmicvmsession",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmicvss",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "vmvss",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wbengine",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wcncsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "webthreatdefsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "webthreatdefusersvc_*",
      "StartupType": "Automatic",
      "OriginalType": "Automatic"
    },
    {
      "Name": "wercplsupport",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wisvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wlidsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wlpasvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wmiApSrv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "workfolderssvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wscsvc",
      "StartupType": "AutomaticDelayedStart",
      "OriginalType": "Automatic"
    },
    {
      "Name": "wuauserv",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    },
    {
      "Name": "wudfsvc",
      "StartupType": "Manual",
      "OriginalType": "Manual"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Services"
}
```

</details>

## Service Changes

Windows services are background processes for system functions or applications. Setting some to manual optimizes performance by starting them only when needed.

You can find information about services on [Wikipedia](https://www.wikiwand.com/en/Windows_service) and [Microsoft's Website](https://learn.microsoft.com/en-us/dotnet/framework/windows-services/introduction-to-windows-service-applications).

### Service Name: AJRouter

**Startup Type:** Disabled

**Original Type:** Manual

### Service Name: ALG

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: AppIDSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: AppMgmt

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: AppReadiness

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: AppVClient

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: AppXSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Appinfo

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: AssignedAccessManagerSvc

**Startup Type:** Disabled

**Original Type:** Manual

### Service Name: AudioEndpointBuilder

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: AudioSrv

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: Audiosrv

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: AxInstSV

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: BDESVC

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: BFE

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: BITS

**Startup Type:** AutomaticDelayedStart

**Original Type:** Automatic

### Service Name: BTAGService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: BcastDVRUserService_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: BluetoothUserService_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: BrokerInfrastructure

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: Browser

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: BthAvctpSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: BthHFSrv

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: CDPSvc

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: CDPUserSvc_*

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: COMSysApp

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: CaptureService_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: CertPropSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: ClipSVC

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: ConsentUxUserSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: CoreMessagingRegistrar

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: CredentialEnrollmentManagerUserSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: CryptSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: CscService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DPS

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: DcomLaunch

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: DcpSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DevQueryBroker

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DeviceAssociationBrokerSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DeviceAssociationService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DeviceInstall

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DevicePickerUserSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DevicesFlowUserSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Dhcp

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: DiagTrack

**Startup Type:** Disabled

**Original Type:** Automatic

### Service Name: DialogBlockingService

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: DispBrokerDesktopSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: DisplayEnhancementService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DmEnrollmentSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Dnscache

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: DoSvc

**Startup Type:** AutomaticDelayedStart

**Original Type:** Automatic

### Service Name: DsSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DsmSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: DusmSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: EFS

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: EapHost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: EntAppSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: EventLog

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: EventSystem

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: FDResPub

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Fax

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: FontCache

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: FrameServer

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: FrameServerMonitor

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: GraphicsPerfSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: HomeGroupListener

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: HomeGroupProvider

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: HvHost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: IEEtwCollectorService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: IKEEXT

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: InstallService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: InventorySvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: IpxlatCfgSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: KeyIso

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: KtmRm

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: LSM

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: LanmanServer

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: LanmanWorkstation

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: LicenseManager

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: LxpSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MSDTC

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MSiSCSI

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MapsBroker

**Startup Type:** AutomaticDelayedStart

**Original Type:** Automatic

### Service Name: McpManagementService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MessagingService_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MicrosoftEdgeElevationService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MixedRealityOpenXRSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: MpsSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: MsKeyboardFilter

**Startup Type:** Manual

**Original Type:** Disabled

### Service Name: NPSMSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NaturalAuthentication

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NcaSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NcbService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NcdAutoSetup

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NetSetupSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NetTcpPortSharing

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: Netlogon

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: Netman

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NgcCtnrSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NgcSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: NlaSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: OneSyncSvc_*

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: P9RdrService_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PNRPAutoReg

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PNRPsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PcaSvc

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: PeerDistSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PenService_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PerfHost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PhoneSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PimIndexMaintenanceSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PlugPlay

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PolicyAgent

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Power

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: PrintNotify

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: PrintWorkflowUserSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: ProfSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: PushToInstall

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: QWAVE

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: RasAuto

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: RasMan

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: RemoteAccess

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: RemoteRegistry

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: RetailDemo

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: RmSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: RpcEptMapper

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: RpcLocator

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: RpcSs

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SCPolicySvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SCardSvr

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SDRSVC

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SEMgrSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SENS

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SNMPTRAP

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SNMPTrap

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SSDPSRV

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SamSs

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: ScDeviceEnum

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Schedule

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SecurityHealthService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Sense

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SensorDataService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SensorService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SensrSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SessionEnv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SgrmBroker

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SharedAccess

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: SharedRealitySvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: ShellHWDetection

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SmsRouter

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Spooler

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SstpSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: StateRepository

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: StiSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: StorSvc

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: SysMain

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: SystemEventsBroker

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: TabletInputService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TapiSrv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TermService

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: TextInputManagementService

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: Themes

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: TieringEngineService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TimeBroker

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TimeBrokerSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TokenBroker

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TrkWks

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: TroubleshootingSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: TrustedInstaller

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: UI0Detect

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: UdkUserSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: UevAgentService

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: UmRdpService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: UnistoreSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: UserDataSvc_*

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: UserManager

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: UsoSvc

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: VGAuthService

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: VMTools

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: VSS

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: VacSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: VaultSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: W32Time

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WEPHOSTSVC

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WFDSConMgrSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WMPNetworkSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WManSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WPDBusEnum

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WSService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WSearch

**Startup Type:** AutomaticDelayedStart

**Original Type:** Automatic

### Service Name: WaaSMedicSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WalletService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WarpJITSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WbioSrvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Wcmsvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: WcsPlugInService

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WdNisSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WdiServiceHost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WdiSystemHost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WebClient

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Wecsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WerSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WiaRpc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WinDefend

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: WinHttpAutoProxySvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WinRM

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: Winmgmt

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: WlanSvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: WpcMonSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: WpnService

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: WpnUserService_*

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: XblAuthManager

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: XblGameSave

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: XboxGipSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: XboxNetApiSvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: autotimesvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: bthserv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: camsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: cbdhsvc_*

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: cloudidsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: dcsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: defragsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: diagnosticshub.standardcollector.service

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: diagsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: dmwappushservice

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: dot3svc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: edgeupdate

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: edgeupdatem

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: embeddedmode

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: fdPHost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: fhsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: gpsvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: hidserv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: icssvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: iphlpsvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: lfsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: lltdsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: lmhosts

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: mpssvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: msiserver

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: netprofm

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: nsi

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: p2pimsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: p2psvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: perceptionsimulation

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: pla

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: seclogon

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: shpamsvc

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: smphost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: spectrum

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: sppsvc

**Startup Type:** AutomaticDelayedStart

**Original Type:** Automatic

### Service Name: ssh-agent

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: svsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: swprv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: tiledatamodelsvc

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: tzautoupdate

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: uhssvc

**Startup Type:** Disabled

**Original Type:** Disabled

### Service Name: upnphost

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vds

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vm3dservice

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: vmicguestinterface

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmicheartbeat

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmickvpexchange

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmicrdv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmicshutdown

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmictimesync

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmicvmsession

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmicvss

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: vmvss

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wbengine

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wcncsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: webthreatdefsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: webthreatdefusersvc_*

**Startup Type:** Automatic

**Original Type:** Automatic

### Service Name: wercplsupport

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wisvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wlidsvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wlpasvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wmiApSrv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: workfolderssvc

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wscsvc

**Startup Type:** AutomaticDelayedStart

**Original Type:** Automatic

### Service Name: wuauserv

**Startup Type:** Manual

**Original Type:** Manual

### Service Name: wudfsvc

**Startup Type:** Manual

**Original Type:** Manual



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

