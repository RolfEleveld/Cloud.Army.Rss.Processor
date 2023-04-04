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
        $rssItemFormat = "<item><title>{0}</title><description>{1}</description><itunes:subtitle>cloud.army</itunes:subtitle><itunes:summary>{1}</itunes:summary><pubDate>{2:yyyy}-{2:MM}-{2:dd}T{2:HH}:{2:mm}:{2:ss}Z</pubDate><itunes:duration>{3}</itunes:duration><enclosure url=""{4}"" length=""42465365"" type=""audio/mpeg""/><guid isPermaLink=""false"">{5}</guid><link>{6}</link><itunes:explicit>no</itunes:explicit><itunes:image>{7}</itunes:image><itunes:author>cloud.army</itunes:author></item>"
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
        
        $rssItemText = $rssItemFormat -f $itemTitle, $itemDescription, $itemDate, $itemDuration, $itemAudio, $itemGuid, $itemLink, $itemImage

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
    )
    Begin {
        [String]$PageUri = 'https://cloud.army/resources/podcast'
        [String]$pageDataUri = 'https://cloud.army/page-data/resources/podcast/page-data.json'
        [String]$RssOpenFormat = "<?xml version=""1.0"" encoding=""UTF-8""?><rss version=""2.0"" xmlns:itunes=""http://www.itunes.com/dtds/podcast-1.0.dtd""><channel><title>{0}</title><link>{1}</link><description>{2}</description><itunes:summary>{2}</itunes:summary><itunes:author>Cloud.Army</itunes:author><itunes:owner><itunes:name>{0}</itunes:name><itunes:email>INFO@CLOUD.ARMY</itunes:email></itunes:owner><itunes:new-feed-url>https://cloudarmyrss.blob.core.windows.net/rss/feed.xml</itunes:new-feed-url><language>en</language><image><url>https://cloud.army/static/62884ca96a1867904a94fbaee105c0ba/a002b/23424854-a2fe-463a-a900-2da86dd4d4b2_ca-base.webp</url><title>{0}</title><link>{1}</link></image><itunes:image href=""https://cloud.army/static/62884ca96a1867904a94fbaee105c0ba/a002b/23424854-a2fe-463a-a900-2da86dd4d4b2_ca-base.webp""/><copyright></copyright><pubDate>{3:yyyy}-{3:MM}-{3:dd}T{3:HH}:{3:mm}:{3:ss}Z</pubDate><itunes:category text=""News""/><itunes:explicit>no</itunes:explicit>"
        [String]$RssCloseFormat = "</channel></rss>"
    }
    Process {
        Write-Verbose "Downloading Uri $PageUri"
        $page = (Invoke-WebRequest -Uri $PageUri).Content

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

        return $rss
    }
    End {
    }
}

Get-RSSFeedFromCloudArmyWebSite | Out-File -FilePath "feed.rss" -Encoding utf8
