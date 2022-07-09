# Set constants
[String]$PageUri = 'https://cloud.army/resources/podcast'
[String]$pageDataUri = 'https://cloud.army/page-data/resources/podcast/page-data.json'
[String]$RssOpenFormat = "<?xml version=""1.0"" encoding=""UTF-8""?><rss version=""2.0"" xmlns:itunes=""http://www.itunes.com/dtds/podcast-1.0.dtd""><channel><title>{0}</title><link>{1}</link><description>{2}</description><itunes:summary>{2}</itunes:summary><itunes:author>Cloud.Army</itunes:author><itunes:owner><itunes:name>{0}</itunes:name><itunes:email>INFO@CLOUD.ARMY</itunes:email></itunes:owner><itunes:new-feed-url>https://cloudarmyrss.blob.core.windows.net/rss/feed.xml</itunes:new-feed-url><language>en</language><image><url>https://cloud.army/static/62884ca96a1867904a94fbaee105c0ba/a002b/23424854-a2fe-463a-a900-2da86dd4d4b2_ca-base.webp</url><title>{0}</title><link>{1}</link></image><itunes:image href=""https://cloud.army/static/62884ca96a1867904a94fbaee105c0ba/a002b/23424854-a2fe-463a-a900-2da86dd4d4b2_ca-base.webp""/><copyright></copyright><pubDate>{3:yyyy}-{3:MM}-{3:dd}T{3:HH}:{3:mm}:{3:ss}Z</pubDate><itunes:category text=""News""/><itunes:explicit>no</itunes:explicit>"
[String]$RssCloseFormat = "</channel></rss>"

# Download Page
Write-Verbose "Downloading Uri $PageUri"
$page = (Invoke-WebRequest -Uri $PageUri).Content

# Clean Page so it can be processed
Write-Verbose "Processing Page $PageUri"

if ($page -match "\<title[^>]*>([^<]+)</title>"){$FeedTitle = [System.Web.HttpUtility]::HtmlEncode(($Matches[1].trim()  -replace '`n', ' ')) }

# remove CDATA
$cleanerPage = $page -replace "<!\[CDATA[^>]+>", ""
# remove head        
$cleanerPage = $cleanerPage -replace "<head>.+</head>", ""
# remove doctype
$cleanerPage = $cleanerPage -replace "<!DOCTYPE[^>]+>", ""
# remove scripts
$cleanerPage = $cleanerPage -replace "<script[^<]+</script>", ""
# remove self contained images
$cleanerPage = $cleanerPage -replace "<img[^>]+/>", ""
# remove true comments
$cleanerPage = $cleanerPage -replace "<!--[^>]+-->", ""        
# remove styles
$cleanerPage = $cleanerPage -replace " *style=""[^""]+"" *", " "
# remove problamatic height inline style
$cleanerPage = $cleanerPage -replace " *height=""[^"" ]+["" ]", ""
# remove problamatic width inline style
$cleanerPage = $cleanerPage -replace " *width=""[^"" ]+["" ]", ""
# remove problamatic scrolling inline style
$cleanerPage = $cleanerPage -replace " *scrolling=""[^"" ]+["" ]", ""
# remove problamatic frameborder inline style
$cleanerPage = $cleanerPage -replace " *frameborder=""[^"" ]+["" ]", ""
# remove problamatic Share and & in iFrame URL
$cleanerPage = $cleanerPage -replace "\?&hide_share=true""", """"

# convert to rss node set
$rssPage = [xml]$cleanerPage # converts well
Write-Verbose "Converted $PageUri to XML"

$description = [System.Web.HttpUtility]::HtmlEncode(($rssPage.SelectSingleNode("//div[@class='description']").'#text'.trim() -replace '`n', ' '))
# select the infowrapper nodes from page to get episodes

# Get RSS feed information
Write-Verbose "Getting pagdedata JSON from $pageDataUri"

# using Pagedata to create episode collection
$pagedata = (Invoke-WebRequest -Uri $pageDataUri).Content | ConvertFrom-Json -Depth 20
$pageDate = $pagedata.result.pageContext.lastModDate.ToUniversalTime()
$ItemCollection = $pagedata.result.pageContext.allPodcasts.collection | Sort-Object -Property number -Descending

Write-Verbose "Processing collection with $($ItemCollection.Count) items from pagedata"

# creating RSS feed data
$RssCollection = @()
$RssCollection += $RssOpenFormat -f $FeedTitle, $PageUri, $description, $pageDate
$RssCollection += $ItemCollection | Get-RSSEntryForPageDataItem
$RssCollection += $RssCloseFormat        
$rss = $RssCollection -join ''

Write-Verbose "RSS feed created with length $($rss.length)"

$rss | Out-File -Path "feed.rss"
