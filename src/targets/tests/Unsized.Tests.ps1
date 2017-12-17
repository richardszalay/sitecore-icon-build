. "$PSScriptRoot/utils/MSBuild.ps1"
. "$PSScriptRoot/utils/Images.ps1"

$fixtures = @{
    unsized = @{
        Project = "$PSScriptRoot/fixtures/unsized/SitecoreIcons.TestFixture.csproj";
    }
    
}

Describe "Unsized icons - default configuration" {
    
    Context "building a project with unsized sitecore icons" {
        $projectPath = $fixtures.unsized.Project
        $projectDir = Split-Path $projectPath -Parent
        $defaultArtifactDir = Join-Path $projectDir "obj\Debug\sitecoreIcons"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "Configuration" = "Debug";
        }

        It "should create an archive for each icon set" {
            $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"

            Test-Path $set1OutputPath | Should Be $true
        }

        It "should resize the images into the target dimensions" {
            $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"
            $expandedSet1OutputPath = [io.path]::ChangeExtension($set1OutputPath, $null).TrimEnd('.') + "-tmp"

            Expand-Archive $set1OutputPath -DestinationPath $expandedSet1OutputPath

            Test-Path (Join-Path $expandedSet1OutputPath "Set1\16x16\icon1.png") | Should Be $true
            Test-Path (Join-Path $expandedSet1OutputPath "Set1\24x24\icon1.png") | Should Be $true
            Test-ImageDimensions (Join-Path $expandedSet1OutputPath "Set1\24x24\icon1.png") 24 24
            Test-Path (Join-Path $expandedSet1OutputPath "Set1\32x32\icon1.png") | Should Be $true
            Test-ImageDimensions (Join-Path $expandedSet1OutputPath "Set1\32x32\icon1.png") 32 32
            Test-Path (Join-Path $expandedSet1OutputPath "Set1\48x48\icon1.png") | Should Be $true
            Test-ImageDimensions (Join-Path $expandedSet1OutputPath "Set1\48x48\icon1.png") 48 48
            Test-Path (Join-Path $expandedSet1OutputPath "Set1\64x64\icon1.png") | Should Be $true
            Test-ImageDimensions (Join-Path $expandedSet1OutputPath "Set1\64x64\icon1.png") 64 64
            Test-Path (Join-Path $expandedSet1OutputPath "Set1\128x128\icon1.png") | Should Be $true
            Test-ImageDimensions (Join-Path $expandedSet1OutputPath "Set1\128x128\icon1.png") 128 128
        }

        It "should not replace any sized images" {
            $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"
            $expandedSet1OutputPath = [io.path]::ChangeExtension($set1OutputPath, '').TrimEnd('.') + "-tmp"

            $sizedImageSource = Join-Path (Split-Path $fixtures.unsized.Project -Parent) `
                "sitecore\shell\Themes\Standard\Set1\16x16\icon1.png"

            $sizedImageSourceHash = (Get-FileHash $sizedImageSource -Algorithm MD5).Hash

            Expand-Archive $set1OutputPath -DestinationPath $expandedSet1OutputPath -Force

            $sizedImageInArchive = (Join-Path $expandedSet1OutputPath "Set1\16x16\icon1.png")

            Test-Path $sizedImageInArchive | Should Be $true

            (Get-FileHash $sizedImageInArchive -Algorithm MD5).Hash | Should Be $sizedImageSourceHash
        }
    }

    Context "cleaning the project" {
        $projectPath = $fixtures.unsized.Project
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

    Context "building a project with unchanged unsized sitecore icons" {
        $projectPath = $fixtures.unsized.Project
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

    Context "building a project with changed unsized sitecore icons" {
        $projectPath = $fixtures.unsized.Project
        $projectDir = Split-Path $projectPath -Parent
        $defaultArtifactDir = Join-Path $projectDir "obj\Debug\sitecoreIcons"
        $set1OutputPath = Join-Path $defaultArtifactDir "Set1.zip"
        
        Invoke-MSBuild -Project $projectPath -Properties @{
            "Configuration" = "Debug";
        }

        $firstWrite = (Get-Item $set1OutputPath).LastWriteTime

        (Get-Item "$projectDir\sitecore\shell\Themes\Standard\Set1\icon1.png").LastWriteTime = Get-Date

        Invoke-MSBuild -Project $projectPath -TargetName "Build" -Properties @{
            "Configuration" = "Debug";
        }

        It "should recreate the icon set archive" {
            $result = (Get-Item $set1OutputPath).LastWriteTime

            $result | Should Not Be $firstWrite
        }
    }

    Context "publishing a project with unsized sitecore icons" {
        $projectPath = $fixtures.unsized.Project
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

