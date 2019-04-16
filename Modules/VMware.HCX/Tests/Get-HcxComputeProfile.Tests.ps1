Remove-Module -Name 'VMware.HCX' -ErrorAction 'SilentlyContinue'
Import-Module -Name './VMware.HCX.psd1' -Force

InModuleScope VMware.HCX {
    Describe "Get-HcxComputeProfile" -Tag 'Unit' {
        $server = "hcxent.mock.local"
        $hcxAuthToken = '8f389452:5e32:48e3:aad5:2debbdacf53e'
        $headers = @{
            "x-hm-authorization" = "$hcxAuthToken"
            "Content-Type"       = "application/json"
            "Accept"             = "application/json"
        }

        $global:hcxConnection = new-object PSObject -Property @{
            'Server'  = "https://$server/hybridity/api";
            'headers' = $headers
        }
        
        It 'returns a Compute Profile when there is only one' {
            $MockedResponse = @{
                "StatusCode" = 200
                "Content"    = Get-Content ./Tests/ComputeProfiles-Single.json | Out-String
            }
            Mock -CommandName Invoke-WebRequest -Mockwith { $MockedResponse }
            
            $ComputeProfiles = Get-HcxComputeProfile
            
            $ComputeProfiles.count | Should -Be 1
            $ComputeProfiles.name | Should -Be "Mock Compute Profile"
            $ComputeProfiles.State | Should -Be "VALID"
            $ComputeProfiles.Compute.Type | Should -Be "ClusterComputeResource"
            $ComputeProfiles.Compute.Name | Should -Be "MockComputeContainer"
            $ComputeProfiles.services.name | Should -Be @("INTERCONNECT", "WANOPT", "VMOTION", "BULK_MIGRATION")
            $ComputeProfiles.deploymentContainer.Compute.Type | Should -Be "ClusterComputeResource"
            $ComputeProfiles.deploymentContainer.Compute.Name | Should -Be "MockComputeContainer"
            $ComputeProfiles.deploymentContainer.Storage.Type | Should -Be "Datastore"
            $ComputeProfiles.deploymentContainer.Storage.Name | Should -Be "MockDatastore"
            $ComputeProfiles.networks.name | Should -Be @("vmotion_network", "management_network")
            $ComputeProfiles.networks.tags | Should -Be @("vmotion", "management", "uplink", "replication")

            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -Scope It -ParameterFilter {
                $Uri -eq "$($global:hcxConnection.Server)/interconnect/computeProfiles" `
                    -And `
                    $Method -eq "Get"
            }
        }
        
        It 'returns multiple Compute Profiles when there is more than one' {
            $MockedResponse = @{
                "StatusCode" = 200
                "Content"    = Get-Content ./Tests/ComputeProfiles-Multiple.json | Out-String
            }
            Mock -CommandName Invoke-WebRequest -Mockwith { $MockedResponse }
            
            $ComputeProfiles = Get-HcxComputeProfile
            
            $ComputeProfiles.count | Should -Be 2
            $ComputeProfiles.name[0] | Should -Be "Mock Compute Profile"
            $ComputeProfiles.name[1] | Should -Be "Mock2 Compute Profile"
            
            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -Scope It -ParameterFilter {
                $Uri -eq "$($global:hcxConnection.Server)/interconnect/computeProfiles" `
                    -And `
                    $Method -eq "Get"
            }
        }

        It 'throws if there are no Compute Profiles' {
            $MockedResponse = @{
                "status"  = 404
                "error"   = "Not Found"
                "message" = "No message available"
                "path"    = "/hybridity/api/interconnect/computeProfiles"
            }
            Mock -CommandName Invoke-WebRequest -Mockwith { $MockedResponse }
            { Get-HcxComputeProfile } | Should -Throw
            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly 1 -Scope It -ParameterFilter {
                $Uri -eq "$($global:hcxConnection.Server)/interconnect/computeProfiles" `
                    -And `
                    $Method -eq "Get"
            }
        }

    }
}