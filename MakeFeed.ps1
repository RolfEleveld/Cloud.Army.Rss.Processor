function Get-RSSEntryForPageDataItem {
    [CmdletBinding(DefaultParameterSetName = 'Cloud.Army parameters',
        PositionalBinding = $false,
        HelpUri = 'http://www.Example.com/Cloud.Army/PageItemProcessor',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Page item object containing the properties of the audio entries as per below example:
        # updated_at         : 20 Apr 2022 06:46:15
        # type               : full
        # token              : 4H9_EqBx
        # title              : When Nudging Meets Neuro
        # status             : published
        # slug               : when-nudging-meets-neuro
        # season             : @{href=https://api.simplecast.com/seasons/cc3a6559-0c7a-452a-8e4b-9fc31401c596; number=1}
        # scheduled_for      : 
        # published_at       : 20 Apr 2022 06:46:15
        # number             : 10
        # is_hidden          : False
        # image_url          : https://image.simplecastcdn.com/images/c90f408a-5ad2-44da-9f08-87bca56f4d02/3d51b187-e713-4ac3-936f-46f950f6bed6/51t8-e-it8l-sl500.jpg
        # image_path         : /prod/images/c90f408a-5ad2-44da-9f08-87bca56f4d02/3d51b187-e713-4ac3-936f-46f950f6bed6/51t8-e-it8l-sl500.jpg
        # id                 : edd15487-f366-43fd-aa68-0bd6a4e3935a
        # href               : https://api.simplecast.com/episodes/edd15487-f366-43fd-aa68-0bd6a4e3935a
        # guid               : 4b00b46c-6da9-4760-8db0-839cc7c9ff89
        # feeds              : 
        # enclosure_url      : https://cdn.simplecast.com/audio/86b6c8c7-7146-4aa5-bed1-a0cce1dafe46/episodes/edd15487-f366-43fd-aa68-0bd6a4e3935a/audio/a2dbaee6-26e0-40d9-b874-8260ba95cc62/default_tc.mp3
        # duration           : 2851
        # description        : In this episode, Richard talks to Rory Sutherland, vice chairman at Ogilvy UK and the author of Alchemy: The Power of Ideas that Don't Make Sense. Rory discusses the power of nudging as  
        #                     a marketing strategy, combining the variety of efforts organizations can use to move customers toward making buying decisions. This leads to a discussion on the role of neuroscience to   
        #                     make those nudges more effective by understanding how people respond to the various nudge approaches - no one size fits all!
        # days_since_release : 35
        # audio_status       : transcoded
        # analytics          : 
        # embedInfo          : @{href=https://api.simplecast.com/oembed?url=https%3A%2F%2Fpodcast.cloud.army%2Fepisodes%2Fwhen-nudging-meets-neuro; width=444; version=1.0; type=rich; title=When Nudging Meets Neuro;    
        #                     thumbnail_width=300; thumbnail_url=https://image.simplecastcdn.com/images/c90f408a-5ad2-44da-9f08-87bca56f4d02/3d51b187-e713-4ac3-936f-46f950f6bed6/51t8-e-it8l-sl500.jpg;
        #                     thumbnail_height=300; provider_url=https://simplecast.com; provider_name=Simplecast; html=<iframe src="https://player.simplecast.com/edd15487-f366-43fd-aa68-0bd6a4e3935a" height="200"    
        #                     width="100%" title="When Nudging Meets Neuro" frameborder="0" scrolling="no"></iframe>; height=200; description=In this episode, Richard talks to Rory Sutherland, vice chairman at        
        #                     Ogilvy UK and the author of Alchemy: The Power of Ideas that Don't Make Sense. Rory discusses the power of nudging as a marketing strategy, combining the variety of efforts
        #                     organizations can use to move customers toward making buying decisions. This leads to a discussion on the role of neuroscience to make those nudges more effective by understanding how 
        #                     people respond to the various nudge approaches - no one size fits all!}
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0,
            ParameterSetName = 'Cloud.Army parameters')]
        [ValidateNotNull()]        
        [PSObject]$Item
    )
    Begin {
        $rssItemFormat = "<item><title>{0}</title><description>{1}</description><itunes:subtitle>cloud.army</itunes:subtitle><itunes:summary>{1}</itunes:summary><pubDate>{2:yyyy}-{2:MM}-{2:dd}T{2:HH}:{2:mm}:{2:ss}Z</pubDate><itunes:duration>{3}</itunes:duration><enclosure url=""{4}"" length=""{8}"" type=""audio/mpeg""/><guid isPermaLink=""false"">{5}</guid><link>{6}</link><itunes:explicit>no</itunes:explicit><itunes:image href=""{7}""/><itunes:author>cloud.army</itunes:author></item>"
    }
    Process {
        $itemTitle = [System.Web.HttpUtility]::HtmlEncode("$($item.number) $($item.title)".Trim())
        $itemLink = $item.href
        $itemDate = $item.published_at.ToUniversalTime()
        $itemDescription = [System.Web.HttpUtility]::HtmlEncode(($item.description.Trim() -replace '`n', ' '))
        $itemGuid = $item.guid
        $itemAudio = $item.enclosure_url
        $itemImage = $item.image_url
        $itemDuration = $item.duration
        
        # Get actual file size if possible, otherwise use a reasonable default
        $itemLength = if ($item.audio_file_size) { $item.audio_file_size } else { "25000000" }  # ~25MB default
        
        $rssItemText = $rssItemFormat -f $itemTitle, $itemDescription, $itemDate, $itemDuration, $itemAudio, $itemGuid, $itemLink, $itemImage, $itemLength

        Write-Verbose "Item $itemTitle added to feed"

        return $rssItemText
    }
    End {
    }    
}
function Get-RSSFeedFromCloudArmyWebSite {
    [CmdletBinding(DefaultParameterSetName = 'Cloud.Army parameters',
        PositionalBinding = $false,
        HelpUri = 'http://www.Example.com/Cloud.Army/PageProcessor',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Optional: Custom feed icon URL
        [String]$CustomFeedIconUrl = $null,
        
        # Optional: Maximum number of episodes to include
        [Int]$MaxEpisodes = 50
    )
    Begin {
        [String]$PageUri = 'https://cloud.army/resources/podcast'
        [String]$pageDataUri = 'https://cloud.army/page-data/resources/podcast/page-data.json'
        # Define feed icon URL - using a PNG/JPG version instead of WebP for better compatibility
        [String]$FeedIconUrl = if ($CustomFeedIconUrl) { 
            $CustomFeedIconUrl 
        } else {             
            "data:image/png;base64,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"  # This can be supplemented with a png file link
        }
        
        [String]$RssOpenFormat = "<?xml version=""1.0"" encoding=""UTF-8""?><rss version=""2.0"" xmlns:itunes=""http://www.itunes.com/dtds/podcast-1.0.dtd"" xmlns:atom=""http://www.w3.org/2005/Atom""><channel><title>{0}</title><link>{1}</link><description>{2}</description><itunes:summary>{2}</itunes:summary><itunes:author>Cloud.Army</itunes:author><itunes:owner><itunes:name>{0}</itunes:name><itunes:email>info@cloud.army</itunes:email></itunes:owner><itunes:new-feed-url>https://cloudarmyrss.blob.core.windows.net/rss/feed.xml</itunes:new-feed-url><language>en</language><image><url>{4}</url><title>{0}</title><link>{1}</link><width>144</width><height>144</height></image><itunes:image href=""{4}""/><atom:link href=""https://cloudarmyrss.blob.core.windows.net/rss/feed.xml"" rel=""self"" type=""application/rss+xml""/><copyright>© Cloud.Army</copyright><pubDate>{3:yyyy}-{3:MM}-{3:dd}T{3:HH}:{3:mm}:{3:ss}Z</pubDate><itunes:category text=""Technology""/><itunes:category text=""Business""/><itunes:explicit>no</itunes:explicit>"
        [String]$RssCloseFormat = "</channel></rss>"
    }
    Process {
        try {
            Write-Verbose "Downloading Uri $PageUri"
            $page = (Invoke-WebRequest -Uri $PageUri -ErrorAction Stop).Content

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

        Write-Verbose "Getting pagdedata JSON from $pageDataUri"

            # using Pagedata to create episode collection
            $pagedata = (Invoke-WebRequest -Uri $pageDataUri -ErrorAction Stop).Content | ConvertFrom-Json -Depth 20
            $pageDate = $pagedata.result.pageContext.lastModDate.ToUniversalTime()
            $ItemCollection = $pagedata.result.pageContext.allPodcasts.collection | Sort-Object -Property number -Descending
            
            # Limit the number of episodes if MaxEpisodes is specified
            if ($MaxEpisodes -gt 0) {
                $ItemCollection = $ItemCollection | Select-Object -First $MaxEpisodes
            }

        Write-Verbose "Processing collection with $($ItemCollection.Count) items from pagedata"

        # creating RSS feed data
        $RssCollection = @()
        $RssCollection += $RssOpenFormat -f $FeedTitle, $PageUri, $description, $pageDate, $FeedIconUrl
        $RssCollection += $ItemCollection | Get-RSSEntryForPageDataItem
        $RssCollection += $RssCloseFormat        
        $rss = $RssCollection -join ''

            Write-Verbose "RSS feed created with length $($rss.length)"

            return $rss
        }
        catch {
            Write-Error "Failed to create RSS feed: $($_.Exception.Message)"
            throw
        }
    }
    End {
    }
}

# Generate the RSS feed with error handling
try {
    Write-Host "Generating CloudArmy Podcast RSS feed..."
    $rssContent = Get-RSSFeedFromCloudArmyWebSite -Verbose
    $rssContent | Out-File -FilePath "feed.rss" -Encoding utf8
    Write-Host "RSS feed successfully created: feed.rss"
    Write-Host "Feed length: $($rssContent.Length) characters"
}
catch {
    Write-Error "Failed to generate RSS feed: $($_.Exception.Message)"
    exit 1
}
