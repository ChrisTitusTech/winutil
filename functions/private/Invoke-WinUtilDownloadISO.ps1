function Invoke-WinUtilDownloadISO {
    # https://github.com/AveYo/MediaCreationTool.bat/blob/main/MediaCreationTool.bat

    ::# show more responsive MCT + PRE pseudo-menu dialog or separate choice dialog instances if either MCT or PRE are set
    if "%MCT%%PRE%"=="" call :choices2 MCT "%VERSIONS%" %dV% "MCT Version" PRE "%PRESETS%" %dP% "MCT Preset" 11 white 0x005a9e 320
    if %MCT%0 lss 1 if %PRE%0 gtr 1 call :choices MCT "%VERSIONS%" %dV% "MCT Version" 11 white 0x005a9e 320
    if %MCT%0 gtr 1 if %PRE%0 lss 1 call :choices PRE "%PRESETS%"  %dP% "MCT Preset"  11 white 0x005a9e 320
    if %MCT%0 gtr 1 if %PRE%0 lss 1 goto choice-0 = cancel
    goto choice-%MCT%

    :choice-17
    set "VER=22631" & set "VID=11_23H2" & set "CB=22631.2861.231204-0538.23H2_ni_release_svc_refresh" & set "CT=2023/12/" & set "CC=2.0"
    set "CAB=https://download.microsoft.com/download/6/2/b/62b47bc5-1b28-4bfa-9422-e7a098d326d4/products_win11_20231208.cab"
    set "EXE=https://download.microsoft.com/download/e/c/d/ecd532eb-bed0-465a-9b7a-330066bec3ce/MediaCreationTool_Win11_23H2.exe"
    goto process ::# refreshed 22621 base with integrated 23H2 enablement package

    :choice-16
    set "VER=22621" & set "VID=11_22H2" & set "CB=22621.1702.230505-1222.ni_release_svc_refresh" & set "CT=2023/05/" & set "CC=2.0"
    set "CAB=https://download.microsoft.com/download/b/1/9/b19bd7fd-78c4-4f88-8c40-3e52aee143c2/products_win11_20230510.cab.cab"
    set "EXE=https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66749/mediacreationtool.exe"
    goto process ::# windows 11 22H2

    :choice-15
    set "VER=22000" & set "VID=11_21H2" & set "CB=22000.318.211104-1236.co_release_svc_refresh" & set "CT=2021/11/" & set "CC=2.0"
    set "CAB=https://download.microsoft.com/download/1/b/4/1b4e06e2-767a-4c9a-9899-230fe94ba530/products_Win11_20211115.cab"
    set "EXE=https://software-download.microsoft.com/download/pr/888969d5-f34g-4e03-ac9d-1f9786c69161/MediaCreationToolW11.exe"
    goto process ::# windows 11 : usability and ui downgrade, and even more ChrEdge bloat (but somewhat snappier multitasking)
}