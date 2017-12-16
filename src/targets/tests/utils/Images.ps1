function Get-ImageDimensions
{
    param(
        [string]$Path
    )

    $png = New-Object System.Drawing.Bitmap $Path

    return @{
        Width = $png.Width;
        Height = $png.Height;
    }

    $png.Dispose()
}

function Test-ImageDimensions
{
    param(
        [string]$Path,
        $Width,
        $Height
    )

    $actual = Get-ImageDimensions $Path

    $actual.Width | Should Be $Width
    $actual.Height | Should Be $Height
}