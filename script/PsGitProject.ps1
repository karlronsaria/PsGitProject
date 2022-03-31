function Invoke-PsGitCommand {
    [Alias('gitcmd')]
    Param(
        [Parameter(Position = 0)]
        [String]
        $InputObject,

        [Switch]
        $WhatIf
    )

    if ($WhatIf) {
        Write-Output $InputObject
    }
    else {
        Invoke-Expression $InputObject
    }
}

<#
    .LINK
    Link: https://stackoverflow.com/questions/5785549/able-to-push-to-all-git-remotes-with-the-one-command
    Link: https://stackoverflow.com/users/9410/aristotle-pagaltzis
    Retrieved: 2022_03_24
#>
function New-PsGitProject {
    Param(
        [String]
        $Path = '.',

        [ArgumentCompleter({
            @('None', 'PsProfile', 'PsModule')
        })]
        [ValidateSet('None', 'PsProfile', 'PsModule')]
        [String]
        $PsProjectType = 'None',

        [String]
        $OriginUrl,

        [Switch]
        $WhatIf
    )

    $default = cat "$PsScriptRoot\..\json\Default.json" `
        | ConvertFrom-Json

    foreach ($resource in $default.Resources) {
        $source = (Get-Item (Join-Path "$PsScriptRoot\.." $resource)).FullName
        $destination = (Get-Item "$Path").FullName

        $cmd = "Copy-Item" `
             + " -Path '$source'" `
             + " -Destination '$destination'" `
             + " -Recurse" `
             + " -Force"

        if ($WhatIf) {
            $cmd
        }
        else {
            iex $cmd
        }
    }

    foreach ($cmd in @(
        "git init"
      , "git add ."
      , "git commit -m $($default.FirstCommitMessage)"
    )) {
        gitcmd $cmd -WhatIf:$WhatIf
    }

    $remotes = $default.ConditionalRemotes
    $remoteAll = $remotes | where Type -eq 'All'

    $commands = if ($OriginUrl) {
        @(
            "git remote add origin $OriginUrl"
          , "git remote add $($remoteAll.Name) origin-host:$OriginUrl"
        )
    } else {
        @(
            "git remote add $($remoteAll.Name)"
        )
    }

    $commands += @("git push -u origin master")

    foreach ($cmd in $commands) {
        gitcmd $cmd -WhatIf:$WhatIf
    }

    $myRemotes = $default.Remotes

    if ($PsProjectType -ne 'None') {
        $myRemotes += @($remotes | where Type -eq $PsProjectType)
    }

    $commands = foreach ($remote in $myRemotes) {
        "git remote add $($remote.Name)"

        foreach ($remotePath in $remote.Locations.Path) {
            $remotePath = iex "Write-Output `"$remotePath`""

            "git remote set-url --add $($remoteAll.Name) $($remote.Name)-host:$($remotePath)"
            "git clone $Path $remotePath"
        }
    }

    foreach ($cmd in $commands) {
        gitcmd $cmd -WhatIf:$WhatIf
    }

<#
    .TODO
    return [PsCustomObject]@{
        PushCommand = "git push $($remoteAll.Name) --all"
    }
#>
}

<#
    .TODO
#>
function New-PsGitPester {

}

