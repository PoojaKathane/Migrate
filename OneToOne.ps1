#Azure Devops Artifact Migration from one organization project to another organization project 
$sourceOrgName = {Source Organization Name}
$sourceProjectName = {Source Project Name}
$sourcePat = {Source Personal Access Token}
$Sourcetoken=[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($sourcePat)) #{Convert Personal Access Token to Base64}
$sourceUrl = "https://feeds.dev.azure.com" #{Source Feeds Url}
$destOrgName = {Destination Organization Name}
$destOrgUrl ={Destination Organization Url}
$destProjectName = {Destination Project Name}
$destPat = {Destination Personal Access Token}
$destinationtoken  = [convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($destPat))
#To get Feeds from source organization
$feedurl ="https://feeds.dev.azure.com/$sourceOrgName/$sourceProjectName/_apis/packaging/feeds?api-version=7.0"
$response=Invoke-RestMethod -Uri $feedurl -Headers @{Authorization = "Basic $Sourcetoken"} -Method Get -ContentType "application/json"
Write-Output $response
   foreach ($feed in $response.value){
       $Feed1= $feed.name;
       #Fetch packages from source feed
       $packageUrl = "$sourceUrl/$sourceOrgName/$sourceProjectName/_apis/packaging/Feeds/$Feed1/packages?api-version=6.0-preview.1"
       $res = Invoke-RestMethod -Uri $packageUrl -Headers @{Authorization = "Basic $Sourcetoken"} -Method Get -ContentType "application/json"
       Write-Output $res
       #Create Feed in dest prpject
       $destUrl = "$destOrgUrl/$destProjectName/_apis/packaging/feeds?api-version=6.0-preview.1"
       $destFeedName="$Feed1"
       $body = @{
            name = $destFeedName
            description = "Feed for fetching artifact"
            project = $destProjectName
         } | ConvertTo-Json
         Invoke-RestMethod -Uri $destUrl -Headers @{Authorization = "Basic $destinationtoken"} -Method Post -Body $body -ContentType "application/json"

         #To push packages
         foreach ($package in $res.value) {
            $packageName1 = $package.name;
               foreach($versionItem in $package.versions){
                   if($versionItem.isLatest){
                        $latestPackageVersion = $versionItem.version;
                        $packageDownloadUrl = "https://pkgs.dev.azure.com/$sourceOrgName/$sourceProjectName/_apis/packaging/feeds/$Feed1/nuget/packages/$packageName1/versions/$latestPackageVersion/content?api-version=7.0-preview.1"
                        Invoke-RestMethod -Uri $packageDownloadUrl -Headers @{Authorization = "Basic $Sourcetoken"} -Method Get -ContentType "application/octet-stream" -OutFile $LocalPath+$packageName1.nuget
                        nuget push $LocalPath+$packageName1.nuget -Source https://pkgs.dev.azure.com/$destOrgName/$destProjectName/_packaging/$destFeedName/nuget/v3/index.json -ApiKey $destPat-SkipDuplicate
                 }
            }
      }
}


