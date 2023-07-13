#Azure Devops Artifact Migration from one organization multiple project to another organization multiple project 

$sourceUrl = "https://feeds.dev.azure.com" #{Source Feeds Url}
$sourcePat = "Token:n376553q4a3s3rj33yx73yihf2fppd42cbtshovpsyfwix3w4mia"
$sourcetoken=[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($sourcePat)) #{Convert Personal Access Token to Base64}
$destOrgName = "PKORGA"
$destOrgUrl ="https://feeds.dev.azure.com/PKORGA"
$destPat = "Token:n376553q4a3s3rj33yx73yihf2fppd42cbtshovpsyfwix3w4mia"
$destinationtoken = [convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($destPat)) #{Convert Personal Access Token to Base64}
$localPath="C:\Users\p.tikaram.kathane\Downloads\scriptoutput"

# To iterate source project
$srcOrg = "https://dev.azure.com/$sourceOrgName/"
$srcProject = $srcOrg + "_apis/projects"
$projectResult = Invoke-RestMethod -Uri $srcProject -Method Get -ContentType "application/json" -Headers @{Authorization = "Basic $sourcetoken"}
$projectResult.value | ForEach-Object{
      $sourceProjectName= $_.name
      Write-Host $sourceProjectName #{It provides list of project present in Source Organization}

      #To get Feeds from source organization
      $feedurl ="https://feeds.dev.azure.com/$sourceOrgName/$sourceProjectName/_apis/packaging/feeds?api-version=7.0"
      $response=Invoke-RestMethod -Uri $feedurl -Headers @{Authorization = "Basic $sourcetoken"} -Method Get -ContentType "application/json"
      Write-Output $response
      foreach ($feed in $response.value){
       $Feed1= $feed.name; #{Get list of feeds from source organization projects}

      #Fetch packages from source feed
      $packageUrl = "$sourceUrl/$sourceOrgName/$sourceProjectName/_apis/packaging/Feeds/$Feed1/packages?api-version=6.0-preview.1"
      $res = Invoke-RestMethod -Uri $packageUrl -Headers @{Authorization = "Basic $sourcetoken"} -Method Get -ContentType "application/json"
      Write-Output $res

      #To iterate dest project
      $destOrg = "https://dev.azure.com/$destOrgName/"
      $destProject = $destOrg + "_apis/projects"
      $projectResult1 = Invoke-RestMethod -Uri $destProject -Method Get -ContentType "application/json" -Headers  @{Authorization = "Basic $destinationtoken"}
       $projectResult1.value | ForEach-Object{
        $targetProject =  $_.name
        Write-Host $targetProject #{It provides list of project present in Destination Organization}
        #Creates feed in destination projects
        if($sourceProjectName -eq "$targetProject"){
            ForEach($project in $targetProject){
                 $destUrl = "$destOrgUrl/$targetProject/_apis/packaging/feeds?api-version=6.0-preview.1"
                 $destFeedName="$Feed1" 
                 $ffeedId = $destFeedName+$targetProject
                 $body = @{
                     name = $destFeedName+$targetProject
                     description = "Feed for fetching artifact"
                     project = $targetProject
                    } | ConvertTo-Json
                    Invoke-RestMethod -Uri $destUrl -Headers @{Authorization = "Basic $destinationtoken"} -Method Post -Body $body -ContentType "application/json"

                    #Get unique feedId from feedName
                    $destfeedurl ="https://feeds.dev.azure.com/$destOrgName/$targetProject/_apis/packaging/feeds/$ffeedId ?api-version=7.0"
                    $response1=Invoke-RestMethod -Uri $destfeedurl -Headers @{Authorization = "Basic $destinationtoken"} -Method Get -ContentType "application/json"
                    Write-Output $response1
                    $feedid = $response1.id

                    #To push packages
                      foreach ($package in $res.value) {
                            $packageName1 = $package.name;
                               foreach($versionItem in $package.versions){
                                     if($versionItem.isLatest){
                                          $latestPackageVersion = $versionItem.version;
                                          $packageDownloadUrl = "https://pkgs.dev.azure.com/$sourceOrgName/$sourceProjectName/_apis/packaging/feeds/$Feed1/nuget/packages/$packageName1/versions/$latestPackageVersion/content?api-version=7.0-preview.1"
                                          Invoke-RestMethod -Uri $packageDownloadUrl -Headers @{Authorization = "Basic $sourcetoken"} -Method Get -ContentType "application/octet-stream" -OutFile $LocalPath+$packageName1.nuget
                                         nuget push $LocalPath+$packageName1.nuget -Source https://pkgs.dev.azure.com/$destOrgName/$targetProject/_packaging/$feedid/nuget/v3/index.json -ApiKey $destPat -SkipDuplicate
                                     }                             
                                   }
                              }
                         }                            
                    }                      
               }                                                     
          }                                        
}


