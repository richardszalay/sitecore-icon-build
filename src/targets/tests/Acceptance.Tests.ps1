. "$PSScriptRoot/utils/WebConfig.ps1"
. "$PSScriptRoot/utils/MSBuild.ps1"
. "$PSScriptRoot/utils/MSDeploy.ps1"

$fixtures = @{
    default = @{
        Project = "$PSScriptRoot\fixtures/default/SitecoreIcons.TestFixture.csproj";
    }
    
}

Describe "Default configuration" {

    Context "building a project with sized sitecore icons" {
        $projectPath = $fixtures.default.Project
        $projectDir = Split-Path $projectPath -Parent
        $defaultArtifactDir = Join-Path $projectDir "obj\Debug\sitecoreIcons"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "Configuration" = "Debug";
        }

        It "should create an archive for each icon set" {
            $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"

            Test-Path $set1OutputPath | Should Be $true
        }

        It "should include the sized icons in the generated icon set" {
            $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"
            $expandedSet1OutputPath = [io.path]::ChangeExtension($set1OutputPath, '')

            Expand-Archive $set1OutputPath -DestinationPath $expandedSet1OutputPath

            Test-Path (Join-Path $expandedSet1OutputPath "16x16\icon1.png") | Should Be $true
            Test-Path (Join-Path $expandedSet1OutputPath "24x24\icon1.png") | Should Be $true
            Test-Path (Join-Path $expandedSet1OutputPath "32x32\icon1.png") | Should Be $true
        }
    }

    Context "cleaning the project" {
        $projectPath = $fixtures.default.Project
        $projectDir = Split-Path $projectPath -Parent
        $defaultArtifactDir = Join-Path $projectDir "obj\Debug\sitecoreIcons"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "Configuration" = "Debug";
        }

        Invoke-MSBuild -Project $projectPath -TargetName "Clean" -Properties @{
            "Configuration" = "Debug";
        }

        It "should clean the artifact dir" {
            $result = Test-Path $defaultArtifactDir

            $result | Should Be $false
        }
    }

    Context "building a project with unchanged sized sitecore icons" {
        $projectPath = $fixtures.default.Project
        $projectDir = Split-Path $projectPath -Parent
        $defaultArtifactDir = Join-Path $projectDir "obj\Debug\sitecoreIcons"
        $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "Configuration" = "Debug";
        }

        $firstWrite = (Get-Item $set1OutputPath).LastWriteTime

        Invoke-MSBuild -Project $projectPath -TargetName "Build" -Properties @{
            "Configuration" = "Debug";
        }

        It "should not recreate the icon set archive" {
            $result = (Get-Item $set1OutputPath).LastWriteTime

            $result | Should Be $firstWrite
        }
    }

    Context "publishing a project with sized sitecore icons" {
        $projectPath = $fixtures.default.Project
        $projectDir = Split-Path $projectPath -Parent
        $publishDir = Join-Path $projectDir "obj\publishOutput"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "Configuration" = "Debug";
            "DeployOnBuild" = "true";
            "DeployDefaultTarget" = "WebPublish";
            "WebPublishMethod" = "FileSystem";
            "DeleteExistingFiles" = "True";
            "DeployAsIisApp" = "false";
            "publishUrl" = $publishDir;
        }

        It "should publish the icon set archive" {
            $set1PublishedArchivePath = Join-Path $publishDir "sitecore\shell\Themes\Standard\Set1.zip"

            Test-Path $set1PublishedArchivePath | Should Be $true
        }

        It "should not publish the source icons" {
            $set1PublishedSourcePath = Join-Path $publishDir "sitecore\shell\Themes\Standard\Set1"

            Test-Path $set1PublishedSourcePath | Should Be $false
        }
    }
}