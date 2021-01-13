
# this is the python stuff stuffed into powershell
# https://docs.frame.nutanix.com/frame-apis/admin-api.html?highlight=api

function set-FrameCapacity {
    param (
        [string]
        [Parameter(Mandatory = $true, Position=0)]
        $bufferSVR,
        [string]
        [Parameter(Mandatory = $true, Position=1)]
        $maxSVR, 
        [string]
        [Parameter(Mandatory = $true, Position=2)]
        $minSVR
    )    
            # Client credentials 
            $client_id = #redacted
            $client_secret = #redacted

            # Create signature content
            $stime = get-date -UFormat %s
            $timestamp = [math]::Round($stime)
            $passphrase = "$timestamp" + $client_id

            # generate signature
            $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
            $hmacsha.key = [Text.Encoding]::UTF8.GetBytes($client_secret)
            $signature = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($passphrase))
            # do this nonsense to actually output hex values
            $signature = [System.BitConverter]::ToString($signature).Replace('-','').ToLower()

            # this is the data for the headers to actually auth during request 
            $headers = @{
                'X-Frame-ClientId' = $client_id
                'X-Frame-Timestamp' = $timestamp
                'X-Frame-Signature' = $signature
            }

            # these are the values to change when POSTing 
            $content = @{
                'buffer_servers' = $bufferSVR
                'max_servers' = $maxSVR
                'min_servers' = $minSVR
            }

            # this uri is pulled after hunting through account api data
            $uri = #redacted

            # here is the curl 
            $Result = Invoke-WebRequest -Uri $Uri -Method 'POST'-Headers $headers -Body $content

}

# example
# set-FrameCapacity -bufferSVR 0 -maxSVR 30 -minSVR 0