# Test-RSSFeed.ps1
# Helper script to test the RSS feed and create a proper podcast icon

param(
    [Switch]$TestValidation,
    [Switch]$CreateIcon,
    [Switch]$DownloadIcon
)

function Test-RSSFeedValidation {
    <#
    .SYNOPSIS
    Validates the RSS feed for podcast readers compatibility
    #>
    
    if (-not (Test-Path "feed.rss")) {
        Write-Warning "feed.rss not found. Run MakeFeed.ps1 first."
        return
    }
    
    Write-Host "Testing RSS feed validation..." -ForegroundColor Yellow
    
    try {
        # Load the RSS feed as XML
        [xml]$rss = Get-Content "feed.rss" -Raw
        
        # Check required elements
        $checks = @()
        
        # Channel-level checks
        $checks += @{
            Name = "Channel Title"
            Test = $rss.rss.channel.title -ne $null
            Value = $rss.rss.channel.title
        }
        
        $checks += @{
            Name = "Channel Description"
            Test = $rss.rss.channel.description -ne $null
            Value = $rss.rss.channel.description.Length -gt 0
        }
        
        $checks += @{
            Name = "iTunes Image"
            Test = $rss.rss.channel.'itunes:image' -ne $null
            Value = $rss.rss.channel.'itunes:image'.href
        }
        
        $checks += @{
            Name = "Standard Image"
            Test = $rss.rss.channel.image -ne $null
            Value = $rss.rss.channel.image.url
        }
        
        $checks += @{
            Name = "Language"
            Test = $rss.rss.channel.language -ne $null
            Value = $rss.rss.channel.language
        }
        
        $checks += @{
            Name = "iTunes Categories"
            Test = $rss.rss.channel.'itunes:category' -ne $null
            Value = $rss.rss.channel.'itunes:category'.Count
        }
        
        # Episode-level checks
        $episodeCount = $rss.rss.channel.item.Count
        $checks += @{
            Name = "Episode Count"
            Test = $episodeCount -gt 0
            Value = $episodeCount
        }
        
        if ($episodeCount -gt 0) {
            $firstEpisode = $rss.rss.channel.item[0]
            $checks += @{
                Name = "Episode Enclosure"
                Test = $firstEpisode.enclosure -ne $null
                Value = $firstEpisode.enclosure.url
            }
            
            $checks += @{
                Name = "Episode GUID"
                Test = $firstEpisode.guid -ne $null
                Value = $firstEpisode.guid.'#text'
            }
            
            $checks += @{
                Name = "Episode iTunes Image"
                Test = $firstEpisode.'itunes:image' -ne $null
                Value = $firstEpisode.'itunes:image'.href
            }
        }
        
        # Display results
        Write-Host "`nRSS Feed Validation Results:" -ForegroundColor Green
        Write-Host "=" * 40
        
        foreach ($check in $checks) {
            $status = if ($check.Test) { "✓ PASS" } else { "✗ FAIL" }
            $color = if ($check.Test) { "Green" } else { "Red" }
            Write-Host "$($check.Name): $status" -ForegroundColor $color
            if ($check.Value -and $check.Test) {
                Write-Host "  Value: $($check.Value)" -ForegroundColor Gray
            }
        }
        
        # Icon-specific warnings
        if ($rss.rss.channel.image.url -match "\.webp$") {
            Write-Warning "Channel image is WebP format. Consider converting to PNG/JPG for better podcast reader compatibility."
        }
        
        if ($rss.rss.channel.image.width -eq $null -or $rss.rss.channel.image.height -eq $null) {
            Write-Warning "Channel image missing width/height attributes. Adding these helps with podcast reader compatibility."
        }
        
    }
    catch {
        Write-Error "Failed to validate RSS feed: $($_.Exception.Message)"
    }
}

function Get-PodcastIconFromWebP {
    <#
    .SYNOPSIS
    Downloads the current WebP icon and provides instructions for converting to PNG
    #>
    
    Write-Host "Downloading current WebP icon..." -ForegroundColor Yellow
    
    $webpUrl = "https://cloud.army/static/62884ca96a1867904a94fbaee105c0ba/a002b/23424854-a2fe-463a-a900-2da86dd4d4b2_ca-base.webp"
    $webpPath = "cloud-army-icon.webp"
    
    try {
        Invoke-WebRequest -Uri $webpUrl -OutFile $webpPath -ErrorAction Stop
        Write-Host "✓ Downloaded: $webpPath" -ForegroundColor Green
        
        Write-Host "`nTo convert to PNG for better podcast compatibility:" -ForegroundColor Yellow
        Write-Host "1. Use an online converter like https://cloudconvert.com/webp-to-png"
        Write-Host "2. Or use ImageMagick: magick cloud-army-icon.webp cloud-army-podcast-icon.png"
        Write-Host "3. Or use PowerShell with .NET (if System.Drawing is available)"
        Write-Host "4. Recommended size: 1400x1400 pixels (minimum 1400x1400 for iTunes)"
        
        # Try to get image dimensions
        try {
            Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
            $img = [System.Drawing.Image]::FromFile((Resolve-Path $webpPath))
            Write-Host "Current image dimensions: $($img.Width)x$($img.Height)" -ForegroundColor Cyan
            $img.Dispose()
        }
        catch {
            Write-Host "Could not read image dimensions (System.Drawing not available)" -ForegroundColor Gray
        }
        
    }
    catch {
        Write-Error "Failed to download WebP icon: $($_.Exception.Message)"
    }
}

function Show-Usage {
    Write-Host "Test-RSSFeed.ps1 - Helper script for RSS feed testing and icon creation" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\Test-RSSFeed.ps1 -TestValidation    # Validate the RSS feed"
    Write-Host "  .\Test-RSSFeed.ps1 -DownloadIcon      # Download current WebP icon"
    Write-Host "  .\Test-RSSFeed.ps1 -TestValidation -DownloadIcon  # Do both"
    Write-Host ""
    Write-Host "Icon Requirements for Podcast Readers:" -ForegroundColor Yellow
    Write-Host "- Format: PNG or JPG (not WebP)"
    Write-Host "- Size: 1400x1400 pixels minimum (3000x3000 recommended)"
    Write-Host "- Square aspect ratio"
    Write-Host "- RGB color space"
    Write-Host "- No transparency"
}

# Main execution
if ($TestValidation) {
    Test-RSSFeedValidation
}

if ($DownloadIcon) {
    Get-PodcastIconFromWebP
}

if (-not $TestValidation -and -not $DownloadIcon) {
    Show-Usage
}
