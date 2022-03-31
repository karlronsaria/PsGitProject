function Format-PsGitLog {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $InputString
    )

    Begin {
        $global:PS_GIT_INDENT = "    "

        function Get-ArrayTrimFirstAndLast {
            Param(
               [String[]]
               $InputString
            )

            if ($null -eq $InputString) {
                return $null
            }

            $isArray = $InputString -is [Object[]] -or $InputString -is [String[]]

            if (-not $isArray -or $InputString.Count -le 1) {
                $result = if ([String]::IsNullOrWhiteSpace($InputString)) {
                    $null
                } else {
                    $InputString
                }

                return $result
            }

            if ([String]::IsNullOrWhiteSpace($InputString[$InputString.Count - 1])) {
                $InputString = $InputString[0 .. ($InputString.Count - 2)]
            }

            if ([String]::IsNullOrWhiteSpace($InputString[0])) {
                $InputString = $InputString[1 .. ($InputString.Count - 1)]
            }

            return $InputString
        }

        function script:Get-GitLogToString {
            Param(
                [PsCustomObject]
                $InputObject
            )

            $message = $InputObject.Message | foreach {
                "$($global:PS_GIT_INDENT)$_"
            } | Out-String

            return @"
commit $($InputObject.Commit)
Author: $($InputObject.AuthorName) <$($InputObject.AuthorEmail)>
Date:   $($InputObject.DateTimeString)

$message
"@
        }

        function New-PsGitLog {
            $what = [PsCustomObject]@{
                Commit = ""
                AuthorName = ""
                AuthorEmail = ""
                DateTimeString = ""
                Message = @()
            }

            $what | Add-Member `
                -MemberType ScriptMethod `
                -Name ToString `
                -Force `
                -Value {
                    script:Get-GitLogToString $this
                }

            return $what
        }

        $what = New-PsGitLog
        $firstItemProcessed = $false
    }

    Process {
        # foreach ($index in (0 .. ($InputString.Count - 1))) {
        #     $line = $InputString[$index]

        foreach ($line in $InputString) {
            $capture = [Regex]::Match($line, "(?<=^commit\s+)\w+")

            if ($capture.Success) {
                if ($firstItemProcessed) {
                    $what.Message = Get-ArrayTrimFirstAndLast `
                        -InputString $what.Message

                    Write-Output $what
                    $what = New-PsGitLog
                }

                $firstItemProcessed = $true
                $what.Commit = $capture.Value
                continue
            }

            $capture = [Regex]::Match($line, "^Author\:\s+(?<name>\S+)\s+\<(?<email>[^<>]+)\>")

            if ($capture.Success) {
                $what.AuthorName = $capture.Groups['name'].Value
                $what.AuthorEmail = $capture.Groups['email'].Value
                continue
            }

            $capture = [Regex]::Match($line, "(?<=^Date\:\s+)\S.*")

            if ($capture.Success) {
                $what.DateTimeString = $capture.Value
                continue
            }

            $capture = [Regex]::Match($line, "(?<=^$($global:PS_GIT_INDENT)).*")

            if ($capture.Success) {
                $what.Message += @($capture.Value)
            }
        }
    }

    End {
        $what.Message = Get-ArrayTrimFirstAndLast `
            -InputString $what.Message

        Write-Output $what
    }
}

function Invoke-PsGitReset {
    Param(
        [PsCustomObject]
        $InputObject,

        [Switch]
        $WhatIf
    )

    $cmd = "git reset $($InputObject.Commit)"

    if ($WhatIf) {
        return $cmd
    }

    Invoke-Expression $cmd
}

