BeforeAll {
    $serviceConfigurationPath = '/etc/systemd/system/fabio.service'
    $beforeRulesContent = Get-Content '/etc/ufw/before.rules' | Out-String
}

Describe 'The fabio application' {
    Context 'is installed' {
        It 'with binaries in /usr/local/bin' {
            '/usr/local/bin/fabio' | Should -Exist
        }

        It 'with default configuration in /etc/fabio.d/fabio.properties' {
            '/etc/fabio.d/fabio.properties' | Should -Exist
        }
    }

    Context 'has been daemonized' {
        It 'has a systemd configuration' {
            if (-not (Test-Path $serviceConfigurationPath))
            {
               $false | Should -Be $true
            }
        }

        It 'with a systemd service' {
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
            $serviceFileContent | Should -Be ($expectedContent -replace "`r", "")

            $systemctlOutput = & systemctl status fabio
            $systemctlOutput | Should -Not -Be $null
            $systemctlOutput.GetType().FullName | Should -Be 'System.Object[]'
            $systemctlOutput.Length | Should -BeGreaterThan 3
            $systemctlOutput[0] | Should -Match 'fabio.service - fabio'
        }

        It 'that is enabled' {
            $systemctlOutput = & systemctl status fabio
            $systemctlOutput[1] | Should -Match 'Loaded:\sloaded\s\(.*;\senabled;.*\)'

        }

        It 'and is running' {
            $systemctlOutput = & systemctl status fabio
            $systemctlOutput[2] | Should -Match 'Active:\sactive\s\(running\).*'
        }
    }

    Context 'can be contacted' {
        It 'responds to HTTP calls' {
            $response = Invoke-WebRequest -Uri http://localhost:9998 -UseBasicParsing
            $response.StatusCode | Should -Be 200
        }
    }

    Context 'has a redirect setup' {
        It 'for port 80' {
            $beforeRulesContent | Should -Match '-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 7080'
        }

        It 'for port 443' {
            $beforeRulesContent | Should -Match '-A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 7443'
        }
    }
}
