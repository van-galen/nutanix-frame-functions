# have users in a lot of groups but need to put them in one group that can't be nested?
# running this on a recurring basis will kee the one large group up to date and then the one large group can be used in other configs
# in my use case i wanted to send send an Azure group identifier as a SAML attribute to to provide access to a specific app profile  
# $coursecode - in env there are groups that follow a subject_###_* format
# $cooldates - subject_###_*_YEAR####_ in that same string
# $filepath - local workspace on server where scheduled task runs
# $megagroup - the display name of the Azure group I'm targeting 

function set-AppAzureaccess (
    $coursecodes, $cooldates, $filepath, $megagroup
    ) {

        #look up the azure group used in saml claim with the friendly name
        $targetgroup = Get-AzureADGroup -Filter "DisplayName eq '$megagroup'" -All $true

        #set file to dump objectids to for group membership reconciliation
        New-Item -Path "$filepath" -force

        # for each of the dates from the friendly names of the groups grab
        foreach ($cooldate in $cooldates){
                foreach ($coursesection in $coursecodes){
                    $thestuff = Get-AzureADGroup -All $true -Filter "startswith(DisplayName,'$coursesection')"
                    $coolcourses = $thestuff.displayname | select-string $cooldate
                            foreach ($coolcourse in $coolcourses){
                                $autousers = Get-AzureADGroup -Filter "DisplayName eq '$coolcourse'" -All $true | Get-AzureADGroupMember -All $true | Select-Object -expandproperty ObjectId
                                $autousers | Out-File -FilePath "$filepath" -Append
                            }
                }
            }

        $CorrectMembers = Get-Content -path "$filepath" | Select-Object -Unique
        $CurrentMembers = Get-AzureADGroup -ObjectId $targetgroup.ObjectId | Get-AzureADGroupMember -All $true | Select-Object -expandproperty ObjectId

             if ($CurrentMembers -eq $null){

                ForEach ($member in $CorrectMembers) {
                                Add-AzureADGroupMember -ObjectId $targetgroup.ObjectId -RefObjectId $member
                            }
             }
            
             else {
                    # #reconcile lists 
                        $comparisons = Compare-Object $CurrentMembers $CorrectMembers
                        
                        $AddMembers = $comparisons | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object InputObject
                        $RemoveMembers = $comparisons | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object InputObject
                
                        ForEach ($Removal in $RemoveMembers.InputObject) {                
                                Remove-AzureADGroupMember -ObjectId $targetgroup.ObjectId -MemberId $removal
                                }
                            
                        ForEach ($Addition in $AddMembers.InputObject) {
                                Add-AzureADGroupMember -ObjectId $targetgroup.ObjectId -RefObjectId $Addition                                
                            }

                 }
            
}

### Connect to Azure - uncomment and populate stuff below to actually run connect to your azure enviroment and then run function

# $cloudcred = $null
# $cloudcred = import-CliXml https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-clixml?view=powershell-7.1
# Connect-AzureAD -Credential $cloudcred

# example:
# set-AppAzureaccess COURSE_1234 2021 C:\name-for-file-in-scratch-space display-name-of-azure-group-used-for-SSO

