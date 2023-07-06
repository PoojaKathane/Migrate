$sourceOrgName = "ptikaramkathane"
$sourceProjectName = "DevPK"
$feedName = "MyFeed"
$sourcePat = "PoojaToken:6ck3b2detw2jzzyp2xd5b4z62cqaur6s7csbceykd7pwsolbppeq"
$sourceUrl = "https://feeds.dev.azure.com"
$sourceorgurl="https://dev.azure.com/ptikaramkathane/DevPK"
$destOrgName = "testdestorg"
$destOrgUrl ="https://feeds.dev.azure.com/testdestorg"
$destProjectName = "DestProject1"
$destFeedName = "Feed"
$destPat = "PoojaToken:6ck3b2detw2jzzyp2xd5b4z62cqaur6s7csbceykd7pwsolbppeq"
$token = [convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($destPat))
#Create feed in destination project
$destUrl = "$destOrgUrl/$destProjectName/_apis/packaging/feeds?api-version=6.0-preview.1"

$body = @{

    name = $destFeedName
    description = "Feed for fetching artifact"
    project = $destProjectName
} | ConvertTo-Json

Invoke-RestMethod -Uri $destUrl -Headers @{Authorization = "Basic $token"} -Method Post -Body $body -ContentType "application/json"

#To get Feeds
$feedurl ="https://feeds.dev.azure.com/$sourceOrgName/$sourceProjectName/_apis/packaging/feeds?api-version=7.0"
$response=Invoke-RestMethod -Uri $feedurl -Headers @{Authorization = "Basic $token"} -Method Get -ContentType "application/json"
Write-Output $response

#Fetch packages from source feed
$packageUrl = "$sourceUrl/$sourceOrgName/$sourceProjectName/_apis/packaging/Feeds/$feedName/packages?api-version=6.0-preview.1"
$res = Invoke-RestMethod -Uri $packageUrl -Headers @{Authorization = "Basic $token"} -Method Get -ContentType "application/json"
Write-Output $res

 foreach ($feed in $response.value){
   $Feed1= $feed.name;
    foreach ($package in $res.value) {
       $packageName1 = $package.name;
       foreach($versionItem in $package.versions){
        if($versionItem.isLatest){
            $latestPackageVersion = $versionItem.version;
            $packageDownloadUrl = "https://pkgs.dev.azure.com/ptikaramkathane/DevPK/_apis/packaging/feeds/$Feed1/nuget/packages/$packageName1/versions/$latestPackageVersion/content?api-version=7.0-preview.1"
            Invoke-RestMethod -Uri $packageDownloadUrl -Headers @{Authorization = "Basic $token"} -Method Get -ContentType "application/octet-stream" -OutFile "C:\Users\p.tikaram.kathane\Desktop\output\$packageName1.nuget"
            nuget push C:\Users\p.tikaram.kathane\OneDrive - Accenture\output\$packageName1.nuget -Source https://pkgs.dev.azure.com/$destOrgName/$destProjectName/_packaging/$destFeedName/nuget/v3/index.json -ApiKey $destPat -SkipDuplicate

            }
       }
}
}

 



 

 