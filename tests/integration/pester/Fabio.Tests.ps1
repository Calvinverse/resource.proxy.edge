Describe 'The fabio application' {
    Context 'is installed' {
        It 'with binaries in /usr/local/bin' {
            '/usr/local/bin/fabio' | Should Exist
        }

        It 'with default configuration in /etc/fabio.d/fabio.properties' {
            '/etc/fabio.d/fabio.properties' | Should Exist
        }
    }

    Context 'has been daemonized' {
        $serviceConfigurationPath = '/etc/systemd/system/fabio.service'
        if (-not (Test-Path $serviceConfigurationPath))
        {
            It 'has a systemd configuration' {
               $false | Should Be $true
            }
        }

        $expectedContent = @'
[Service]
ExecStart = /usr/local/bin/fabio -cfg /etc/fabio.d/fabio.properties
RestartSec = 5
Restart = always
User = fabio

[Unit]
Description = Fabio
Documentation = https://github.com/fabiolb/fabio
Requires = network-online.target
After = network-online.target
StartLimitIntervalSec = 0

[Install]
WantedBy = multi-user.target

'@
        $serviceFileContent = Get-Content $serviceConfigurationPath | Out-String
        $systemctlOutput = & systemctl status fabio
        It 'with a systemd service' {
            $serviceFileContent | Should Be ($expectedContent -replace "`r", "")

            $systemctlOutput | Should Not Be $null
            $systemctlOutput.GetType().FullName | Should Be 'System.Object[]'
            $systemctlOutput.Length | Should BeGreaterThan 3
            $systemctlOutput[0] | Should Match 'fabio.service - fabio'
        }

        It 'that is enabled' {
            $systemctlOutput[1] | Should Match 'Loaded:\sloaded\s\(.*;\senabled;.*\)'

        }

        It 'and is running' {
            $systemctlOutput[2] | Should Match 'Active:\sactive\s\(running\).*'
        }
    }

    Context 'can be contacted' {
        $response = Invoke-WebRequest -Uri http://localhost:9998 -UseBasicParsing
        It 'responds to HTTP calls' {
            $response.StatusCode | Should Be 200
        }
    }

    Context 'has a redirect setup' {
        $beforeRulesContent = Get-Content '/etc/ufw/before.rules' | Out-String
        It 'for port 80' {
            $beforeRulesContent | Should Match '-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 7080'
        }

        It 'for port 443' {
            $beforeRulesContent | Should Match '-A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 7443'
        }
    }
}
