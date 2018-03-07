Describe 'The firewall' {
    $ufwOutput = & sudo ufw status

    Context 'on the machine' {
        It 'should return a status' {
            $ufwOutput | Should Not Be $null
            $ufwOutput.GetType().FullName | Should Be 'System.Object[]'
            $ufwOutput.Length | Should Be 37
        }

        It 'should be enabled' {
            $ufwOutput[0] | Should Be 'Status: active'
        }
    }

    Context 'should allow SSH' {
        It 'on port 22' {
            ($ufwOutput | Where-Object {$_ -match '(22/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }
    }

    Context 'should allow consul' {
        It 'on port 8300' {
            ($ufwOutput | Where-Object {$_ -match '(8300/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on TCP port 8301' {
            ($ufwOutput | Where-Object {$_ -match '(8301/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on UDP port 8301' {
            ($ufwOutput | Where-Object {$_ -match '(8301/udp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on TCP port 8302' {
            ($ufwOutput | Where-Object {$_ -match '(8302/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on UDP port 8302' {
            ($ufwOutput | Where-Object {$_ -match '(8302/udp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on port 8500' {
            ($ufwOutput | Where-Object {$_ -match '(8500/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on UDP port 8600' {
            ($ufwOutput | Where-Object {$_ -match '(8600/udp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }
    }

    Context 'should allow fabio' {
        It 'on port 80' {
            ($ufwOutput | Where-Object {$_ -match '(80/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on port 443' {
            ($ufwOutput | Where-Object {$_ -match '(443/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on port 7080' {
            ($ufwOutput | Where-Object {$_ -match '(7080/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on port 7443' {
            ($ufwOutput | Where-Object {$_ -match '(7443/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on port 9998' {
            ($ufwOutput | Where-Object {$_ -match '(9998/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }
    }

    Context 'should allow telegraf' {
        It 'on TCP port 8125' {
            ($ufwOutput | Where-Object {$_ -match '(8125/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }
    }

    Context 'should allow unbound' {
        It 'on TCP port 53' {
            ($ufwOutput | Where-Object {$_ -match '(53/tcp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }

        It 'on UDP port 53' {
            ($ufwOutput | Where-Object {$_ -match '(53/udp)\s*(ALLOW)\s*(Anywhere)'} ) | Should Not Be $null
        }
    }
}
