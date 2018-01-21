function Get-IpAddress
{
    $ErrorActionPreference = 'Stop'

    $output = & /sbin/ifconfig eth0
    $line = $output |
        Where-Object { $_.Contains('inet addr:') } |
        Select-Object -First 1

    $line = $line.Trim()
    $line = $line.SubString('inet addr:'.Length)
    return $line.SubString(0, $line.IndexOf(' '))
}

function Initialize-Environment
{
    $ErrorActionPreference = 'Stop'

    try
    {
        $consulVersion = '1.0.2'
        Start-TestConsul -consulVersion $consulVersion

        Install-Vault -vaultVersion '0.9.1'
        Start-TestVault

        Write-Output "Waiting for 10 seconds for consul and vault to start ..."
        Start-Sleep -Seconds 10

        Join-Cluster -consulVersion $consulVersion

        Set-VaultSecrets
        Set-ConsulKV -consulVersion $consulVersion

        Write-Output "Giving consul-template 30 seconds to process the data ..."
        Start-Sleep -Seconds 30
    }
    catch
    {
        $currentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        try
        {
            Write-Error $errorRecord.Exception
            Write-Error $errorRecord.ScriptStackTrace
            Write-Error $errorRecord.InvocationInfo.PositionMessage
        }
        finally
        {
            $ErrorActionPreference = $currentErrorActionPreference
        }

        # rethrow the error
        throw $_.Exception
    }
}

function Install-Vault
{
    [CmdletBinding()]
    param(
        [string] $vaultVersion
    )

    $ErrorActionPreference = 'Stop'

    & wget "https://releases.hashicorp.com/vault/$($vaultVersion)/vault_$($vaultVersion)_linux_amd64.zip" --output-document /test/vault.zip
    & unzip /test/vault.zip -d /test/vault
}

function Join-Cluster
{
    [CmdletBinding()]
    param(
        [string] $consulVersion
    )

    $ErrorActionPreference = 'Stop'

    Write-Output "Joining the local consul ..."

    # connect to the actual local consul instance
    $ipAddress = Get-IpAddress
    Write-Output "Joining: $($ipAddress):8351"

    Start-Process -FilePath "/opt/consul/$($consulVersion)/consul" -ArgumentList "join $($ipAddress):8351"

    Write-Output "Getting members for client"
    & /opt/consul/$($consulVersion)/consul members

    Write-Output "Getting members for server"
    & /opt/consul/$($consulVersion)/consul members -http-addr=http://127.0.0.1:8550
}

function Set-ConsulKV
{
    $ErrorActionPreference = 'Stop'

    Write-Output "Setting consul key-values ..."

    # Load config/services/consul
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/consul/datacenter 'test-integration'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/consul/domain 'integrationtest'

    # Load config/services/metrics
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/metrics/protocols/opentsdb/host 'opentsdb.metrics'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/metrics/protocols/opentsdb/port '4242'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/metrics/protocols/statsd/host 'statsd.metrics'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/metrics/protocols/statsd/port '1234'

    # load config/services/queue
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/http/host 'http.queue'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/http/port '15672'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/amqp/host 'amqp.queue'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/queue/protocols/amqp/port '5672'

    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/queue/logs/syslog/username 'testuser'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/queue/logs/syslog/vhost 'testlogs'

    # Load config/services/vault
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/secrets/protocols/http/host 'secrets'
    & /opt/consul/$($consulVersion)/consul kv put -http-addr=http://127.0.0.1:8550 config/services/secrets/protocols/http/port '8200'
}

function Set-VaultSecrets
{
    $ErrorActionPreference = 'Stop'

    Write-Output 'Setting vault secrets ...'

    # secret/services/queue/logs/syslog
}

function Start-TestConsul
{
    [CmdletBinding()]
    param(
        [string] $consulVersion
    )

    $ErrorActionPreference = 'Stop'

    Write-Output "Starting consul ..."
    $process = Start-Process `
        -FilePath "/opt/consul/$($consulVersion)/consul" `
        -ArgumentList "agent -config-file /test/pester/consul/server.json" `
        -PassThru `
        -RedirectStandardOutput /test/pester/consul/consuloutput.out `
        -RedirectStandardError /test/pester/consul/consulerror.out
}

function Start-TestVault
{
    [CmdletBinding()]
    param(
    )

    $ErrorActionPreference = 'Stop'

    Write-Output "Starting vault ..."
    $process = Start-Process `
        -FilePath "/test/vault/vault" `
        -ArgumentList "-dev" `
        -PassThru `
        -RedirectStandardOutput /test/vault/vaultoutput.out `
        -RedirectStandardError /test/vault/vaulterror.out
}
