// ==============================================================================
// Jobs for Jails: Twitter/X Simulation JavaScript for Qualtrics
// ==============================================================================
// Purpose: Create realistic Twitter/X interface for social media experiment
// Author: Charles Crabtree
// ==============================================================================

Qualtrics.SurveyEngine.addOnload(function() {
    
    // ==============================================================================
    // TREATMENT CONDITIONS
    // ==============================================================================
    
    // Get treatment assignment from embedded data
    var treatment = "${e://Field/twitter_treatment}";
    
    // Tweet content variations
    var tweetContent = {
        
        // Detention + No Jobs framing
        detention_no_jobs: {
            author: "Local News 12",
            handle: "@localnews12",
            verified: true,
            avatar: "https://via.placeholder.com/48/1DA1F2/FFFFFF?text=LN",
            text: "BREAKING: Federal government announces plans to build new ICE detention center in [COUNTY]. The facility will house undocumented immigrants awaiting deportation hearings. Construction expected to begin next year.",
            image: null,
            time: "2h",
            retweets: "1,247",
            quotes: "892",
            likes: "3,456",
            views: "245K"
        },
        
        // Detention + Jobs framing
        detention_jobs: {
            author: "Local News 12",
            handle: "@localnews12",
            verified: true,
            avatar: "https://via.placeholder.com/48/1DA1F2/FFFFFF?text=LN",
            text: "BREAKING: Federal government announces plans to build new ICE detention center in [COUNTY]. The facility will create 350 permanent jobs and bring $25M annually to local economy. Over 500 construction jobs expected.",
            image: null,
            time: "2h",
            retweets: "2,156",
            quotes: "1,034",
            likes: "5,892",
            views: "312K"
        },
        
        // Processing + No Jobs framing
        processing_no_jobs: {
            author: "Local News 12",
            handle: "@localnews12",
            verified: true,
            avatar: "https://via.placeholder.com/48/1DA1F2/FFFFFF?text=LN",
            text: "BREAKING: Federal government announces plans to build new immigration processing center in [COUNTY]. The facility will handle administrative immigration cases. Construction expected to begin next year.",
            image: null,
            time: "2h",
            retweets: "987",
            quotes: "654",
            likes: "2,891",
            views: "198K"
        },
        
        // Processing + Jobs framing
        processing_jobs: {
            author: "Local News 12",
            handle: "@localnews12",
            verified: true,
            avatar: "https://via.placeholder.com/48/1DA1F2/FFFFFF?text=LN",
            text: "BREAKING: Federal government announces plans to build new immigration processing center in [COUNTY]. The facility will create 350 permanent jobs and bring $25M annually to local economy. Over 500 construction jobs expected.",
            image: null,
            time: "2h",
            retweets: "1,834",
            quotes: "923",
            likes: "4,567",
            views: "278K"
        },
        
        // ICE raid announcement
        ice_raid_jobs: {
            author: "ICE",
            handle: "@ICEgov",
            verified: true,
            avatar: "https://via.placeholder.com/48/003366/FFFFFF?text=ICE",
            text: "ICE announces expanded operations in [COUNTY] as part of ongoing enforcement efforts. New processing facility will create 350+ local jobs. We remain committed to enforcing immigration laws while supporting local communities.",
            image: null,
            time: "4h",
            retweets: "3,421",
            quotes: "2,156",
            likes: "8,934",
            views: "567K"
        },
        
        ice_raid_no_jobs: {
            author: "ICE",
            handle: "@ICEgov",
            verified: true,
            avatar: "https://via.placeholder.com/48/003366/FFFFFF?text=ICE",
            text: "ICE announces expanded operations in [COUNTY] as part of ongoing enforcement efforts. Operations will target individuals who have violated immigration laws. We remain committed to enforcing immigration laws.",
            image: null,
            time: "4h",
            retweets: "2,876",
            quotes: "1,945",
            likes: "6,234",
            views: "423K"
        }
    };
    
    // Get tweet based on treatment
    var tweet = tweetContent[treatment] || tweetContent.detention_no_jobs;
    
    // Replace county placeholder with respondent's county (from embedded data)
    var county = "${e://Field/respondent_county}" || "your county";
    tweet.text = tweet.text.replace(/\[COUNTY\]/g, county);
    
    // ==============================================================================
    // BUILD TWITTER/X INTERFACE HTML
    // ==============================================================================
    
    var twitterHTML = `
        <div class="twitter-container" style="max-width:550px; margin:0 auto; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
            
            <!-- Tweet Card -->
            <div class="tweet-card" style="background:#fff; border:1px solid #e1e8ed; border-radius:16px; padding:16px; margin-bottom:20px;">
                
                <!-- Header -->
                <div class="tweet-header" style="display:flex; align-items:flex-start; margin-bottom:12px;">
                    <img src="${tweet.avatar}" alt="Avatar" style="width:48px; height:48px; border-radius:50%; margin-right:12px;">
                    <div class="tweet-author">
                        <div style="display:flex; align-items:center;">
                            <span style="font-weight:700; font-size:15px;">${tweet.author}</span>
                            ${tweet.verified ? '<svg viewBox="0 0 22 22" style="width:18px; height:18px; margin-left:4px; fill:#1DA1F2;"><path d="M20.396 11c-.018-.646-.215-1.275-.57-1.816-.354-.54-.852-.972-1.438-1.246.223-.607.27-1.264.14-1.897-.131-.634-.437-1.218-.882-1.687-.47-.445-1.053-.75-1.687-.882-.633-.13-1.29-.083-1.897.14-.273-.587-.704-1.086-1.245-1.44S11.647 1.62 11 1.604c-.646.017-1.273.213-1.813.568s-.969.854-1.24 1.44c-.608-.223-1.267-.272-1.902-.14-.635.13-1.22.436-1.69.882-.445.47-.749 1.055-.878 1.688-.13.633-.08 1.29.144 1.896-.587.274-1.087.705-1.443 1.245-.356.54-.555 1.17-.574 1.817.02.647.218 1.276.574 1.817.356.54.856.972 1.443 1.245-.224.606-.274 1.263-.144 1.896.13.634.433 1.218.877 1.688.47.443 1.054.747 1.687.878.633.132 1.29.084 1.897-.136.274.586.705 1.084 1.246 1.439.54.354 1.17.551 1.816.569.647-.016 1.276-.213 1.817-.567s.972-.854 1.245-1.44c.604.239 1.266.296 1.903.164.636-.132 1.22-.447 1.68-.907.46-.46.776-1.044.908-1.681s.075-1.299-.165-1.903c.586-.274 1.084-.705 1.439-1.246.354-.54.551-1.17.569-1.816zM9.662 14.85l-3.429-3.428 1.293-1.302 2.072 2.072 4.4-4.794 1.347 1.246z"></path></svg>' : ''}
                        </div>
                        <span style="color:#536471; font-size:15px;">${tweet.handle} · ${tweet.time}</span>
                    </div>
                </div>
                
                <!-- Tweet Text -->
                <div class="tweet-text" style="font-size:15px; line-height:1.4; margin-bottom:12px; color:#0f1419;">
                    ${tweet.text}
                </div>
                
                ${tweet.image ? `<img src="${tweet.image}" style="width:100%; border-radius:16px; margin-bottom:12px;">` : ''}
                
                <!-- Engagement Stats -->
                <div class="tweet-stats" style="display:flex; gap:16px; color:#536471; font-size:13px; padding:12px 0; border-top:1px solid #e1e8ed; border-bottom:1px solid #e1e8ed;">
                    <span><strong style="color:#0f1419;">${tweet.retweets}</strong> Reposts</span>
                    <span><strong style="color:#0f1419;">${tweet.quotes}</strong> Quotes</span>
                    <span><strong style="color:#0f1419;">${tweet.likes}</strong> Likes</span>
                    <span><strong style="color:#0f1419;">${tweet.views}</strong> Views</span>
                </div>
                
                <!-- Action Buttons -->
                <div class="tweet-actions" style="display:flex; justify-content:space-around; padding-top:12px;">
                    
                    <!-- Reply -->
                    <button class="tweet-action-btn" id="btn-reply" style="display:flex; align-items:center; gap:8px; background:none; border:none; color:#536471; cursor:pointer; padding:8px 12px; border-radius:9999px; transition:all 0.2s;">
                        <svg viewBox="0 0 24 24" style="width:20px; height:20px; fill:currentColor;"><path d="M1.751 10c0-4.42 3.584-8 8.005-8h4.366c4.49 0 8.129 3.64 8.129 8.13 0 2.96-1.607 5.68-4.196 7.11l-8.054 4.46v-3.69h-.067c-4.49.1-8.183-3.51-8.183-8.01zm8.005-6c-3.317 0-6.005 2.69-6.005 6 0 3.37 2.77 6.08 6.138 6.01l.351-.01h1.761v2.3l5.087-2.81c1.951-1.08 3.163-3.13 3.163-5.36 0-3.39-2.744-6.13-6.129-6.13H9.756z"></path></svg>
                        <span>Reply</span>
                    </button>
                    
                    <!-- Repost -->
                    <button class="tweet-action-btn" id="btn-repost" data-active="false" style="display:flex; align-items:center; gap:8px; background:none; border:none; color:#536471; cursor:pointer; padding:8px 12px; border-radius:9999px; transition:all 0.2s;">
                        <svg viewBox="0 0 24 24" style="width:20px; height:20px; fill:currentColor;"><path d="M4.5 3.88l4.432 4.14-1.364 1.46L5.5 7.55V16c0 1.1.896 2 2 2H13v2H7.5c-2.209 0-4-1.79-4-4V7.55L1.432 9.48.068 8.02 4.5 3.88zM16.5 6H11V4h5.5c2.209 0 4 1.79 4 4v8.45l2.068-1.93 1.364 1.46-4.432 4.14-4.432-4.14 1.364-1.46 2.068 1.93V8c0-1.1-.896-2-2-2z"></path></svg>
                        <span>Repost</span>
                    </button>
                    
                    <!-- Like -->
                    <button class="tweet-action-btn" id="btn-like" data-active="false" style="display:flex; align-items:center; gap:8px; background:none; border:none; color:#536471; cursor:pointer; padding:8px 12px; border-radius:9999px; transition:all 0.2s;">
                        <svg viewBox="0 0 24 24" style="width:20px; height:20px; fill:currentColor;"><path d="M16.697 5.5c-1.222-.06-2.679.51-3.89 2.16l-.805 1.09-.806-1.09C9.984 6.01 8.526 5.44 7.304 5.5c-1.243.07-2.349.78-2.91 1.91-.552 1.12-.633 2.78.479 4.82 1.074 1.97 3.257 4.27 7.129 6.61 3.87-2.34 6.052-4.64 7.126-6.61 1.111-2.04 1.03-3.7.477-4.82-.561-1.13-1.666-1.84-2.908-1.91zm4.187 7.69c-1.351 2.48-4.001 5.12-8.379 7.67l-.503.3-.504-.3c-4.379-2.55-7.029-5.19-8.382-7.67-1.36-2.5-1.41-4.86-.514-6.67.887-1.79 2.647-2.91 4.601-3.01 1.651-.09 3.368.56 4.798 2.01 1.429-1.45 3.146-2.1 4.796-2.01 1.954.1 3.714 1.22 4.601 3.01.896 1.81.846 4.17-.514 6.67z"></path></svg>
                        <span>Like</span>
                    </button>
                    
                    <!-- Bookmark -->
                    <button class="tweet-action-btn" id="btn-bookmark" data-active="false" style="display:flex; align-items:center; gap:8px; background:none; border:none; color:#536471; cursor:pointer; padding:8px 12px; border-radius:9999px; transition:all 0.2s;">
                        <svg viewBox="0 0 24 24" style="width:20px; height:20px; fill:currentColor;"><path d="M4 4.5C4 3.12 5.119 2 6.5 2h11C18.881 2 20 3.12 20 4.5v18.44l-8-5.71-8 5.71V4.5zM6.5 4c-.276 0-.5.22-.5.5v14.56l6-4.29 6 4.29V4.5c0-.28-.224-.5-.5-.5h-11z"></path></svg>
                        <span>Save</span>
                    </button>
                    
                </div>
                
            </div>
            
            <!-- Instruction -->
            <p style="text-align:center; color:#536471; font-size:14px; margin-top:16px;">
                Please interact with this post as you normally would on social media, then answer the question below.
            </p>
            
        </div>
    `;
    
    // ==============================================================================
    // INSERT INTO QUESTION
    // ==============================================================================
    
    var questionContainer = this.getQuestionContainer();
    var questionText = questionContainer.querySelector('.QuestionText');
    
    if (questionText) {
        questionText.innerHTML = twitterHTML;
    }
    
    // ==============================================================================
    // BUTTON INTERACTION HANDLERS
    // ==============================================================================
    
    // Track interactions
    var interactions = {
        liked: false,
        reposted: false,
        bookmarked: false,
        replied: false
    };
    
    // Like button
    var likeBtn = document.getElementById('btn-like');
    if (likeBtn) {
        likeBtn.addEventListener('click', function() {
            interactions.liked = !interactions.liked;
            this.setAttribute('data-active', interactions.liked);
            if (interactions.liked) {
                this.style.color = '#F91880';
                this.querySelector('svg').innerHTML = '<path d="M20.884 13.19c-1.351 2.48-4.001 5.12-8.379 7.67l-.503.3-.504-.3c-4.379-2.55-7.029-5.19-8.382-7.67-1.36-2.5-1.41-4.86-.514-6.67.887-1.79 2.647-2.91 4.601-3.01 1.651-.09 3.368.56 4.798 2.01 1.429-1.45 3.146-2.1 4.796-2.01 1.954.1 3.714 1.22 4.601 3.01.896 1.81.846 4.17-.514 6.67z"></path>';
            } else {
                this.style.color = '#536471';
                this.querySelector('svg').innerHTML = '<path d="M16.697 5.5c-1.222-.06-2.679.51-3.89 2.16l-.805 1.09-.806-1.09C9.984 6.01 8.526 5.44 7.304 5.5c-1.243.07-2.349.78-2.91 1.91-.552 1.12-.633 2.78.479 4.82 1.074 1.97 3.257 4.27 7.129 6.61 3.87-2.34 6.052-4.64 7.126-6.61 1.111-2.04 1.03-3.7.477-4.82-.561-1.13-1.666-1.84-2.908-1.91zm4.187 7.69c-1.351 2.48-4.001 5.12-8.379 7.67l-.503.3-.504-.3c-4.379-2.55-7.029-5.19-8.382-7.67-1.36-2.5-1.41-4.86-.514-6.67.887-1.79 2.647-2.91 4.601-3.01 1.651-.09 3.368.56 4.798 2.01 1.429-1.45 3.146-2.1 4.796-2.01 1.954.1 3.714 1.22 4.601 3.01.896 1.81.846 4.17-.514 6.67z"></path>';
            }
            Qualtrics.SurveyEngine.setEmbeddedData('twitter_liked', interactions.liked ? '1' : '0');
        });
    }
    
    // Repost button
    var repostBtn = document.getElementById('btn-repost');
    if (repostBtn) {
        repostBtn.addEventListener('click', function() {
            interactions.reposted = !interactions.reposted;
            this.setAttribute('data-active', interactions.reposted);
            this.style.color = interactions.reposted ? '#00BA7C' : '#536471';
            Qualtrics.SurveyEngine.setEmbeddedData('twitter_reposted', interactions.reposted ? '1' : '0');
        });
    }
    
    // Bookmark button
    var bookmarkBtn = document.getElementById('btn-bookmark');
    if (bookmarkBtn) {
        bookmarkBtn.addEventListener('click', function() {
            interactions.bookmarked = !interactions.bookmarked;
            this.setAttribute('data-active', interactions.bookmarked);
            this.style.color = interactions.bookmarked ? '#1DA1F2' : '#536471';
            Qualtrics.SurveyEngine.setEmbeddedData('twitter_bookmarked', interactions.bookmarked ? '1' : '0');
        });
    }
    
    // Reply button (just tracks click, doesn't open anything)
    var replyBtn = document.getElementById('btn-reply');
    if (replyBtn) {
        replyBtn.addEventListener('click', function() {
            interactions.replied = true;
            this.style.color = '#1DA1F2';
            Qualtrics.SurveyEngine.setEmbeddedData('twitter_replied', '1');
        });
    }
    
    // Store treatment condition
    Qualtrics.SurveyEngine.setEmbeddedData('twitter_treatment_shown', treatment);
    Qualtrics.SurveyEngine.setEmbeddedData('twitter_tweet_text', tweet.text);
    
});

Qualtrics.SurveyEngine.addOnReady(function() {
    // Add hover effects
    var style = document.createElement('style');
    style.textContent = `
        .tweet-action-btn:hover {
            background-color: rgba(29, 155, 240, 0.1) !important;
        }
        #btn-like:hover {
            background-color: rgba(249, 24, 128, 0.1) !important;
        }
        #btn-repost:hover {
            background-color: rgba(0, 186, 124, 0.1) !important;
        }
        .tweet-card {
            box-shadow: 0 0 0 1px rgba(0,0,0,0.05);
        }
        .tweet-card:hover {
            background-color: #fafafa;
        }
    `;
    document.head.appendChild(style);
});

Qualtrics.SurveyEngine.addOnUnload(function() {
    // Nothing needed on unload
});
