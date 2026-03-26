"""
Demo data module — provides rich fallback content when Gemini is unavailable.
Each story has a matching story arc with unique phases.
"""

DEMO_STORIES = {
    "Student": [
        {
            "storyId": "demo-ai-race",
            "storyTitle": "The Global AI Arms Race — Who Wins?",
            "summary": "OpenAI, Google, and Meta battle for AI dominance. OpenAI pledged $1B in grants while shutting down Sora. Congress pushes to pause AI data centers.",
            "tags": ["AI", "Big Tech", "Trending"],
            "momentum": "Accelerating",
            "queryTerms": "AI race OpenAI Google regulation",
            "articles": []
        },
        {
            "storyId": "demo-ev-wars",
            "storyTitle": "EV Price Wars — Nio Turns Profitable",
            "summary": "Nio posted its first-ever profit amid China's brutal EV price war. Tesla, BYD, and Nio vie for dominance in the world's largest auto market.",
            "tags": ["EV", "Markets", "China"],
            "momentum": "Heating Up",
            "queryTerms": "Nio EV profit China Tesla",
            "articles": []
        },
        {
            "storyId": "demo-social-media-law",
            "storyTitle": "Meta & YouTube Hit with $6M Damages",
            "summary": "An LA jury found Meta and YouTube liable for designing addictive platforms. A legal precedent that could reshape Big Tech worldwide.",
            "tags": ["Legal", "Meta", "Policy"],
            "momentum": "Heating Up",
            "queryTerms": "Meta YouTube addiction lawsuit",
            "articles": []
        },
        {
            "storyId": "demo-energy-shift",
            "storyTitle": "Golar LNG Taps Goldman Sachs",
            "summary": "Golar LNG starts a strategic review with Goldman Sachs to unlock value. FLNG technology is reshaping global energy infrastructure.",
            "tags": ["Energy", "M&A", "Markets"],
            "momentum": "Cooling",
            "queryTerms": "Golar LNG Goldman Sachs energy",
            "articles": []
        }
    ],
    "Investor": [
        {
            "storyId": "demo-inv-oracle",
            "storyTitle": "Oracle Under Fire — Class Action Alert",
            "summary": "Investors urged to act before April 6th deadline on possible securities fraud. Oracle's cloud AI ambitions face growing scrutiny.",
            "tags": ["Legal", "ORCL", "Alert"],
            "momentum": "Heating Up",
            "queryTerms": "Oracle lawsuit investor ORCL",
            "articles": []
        },
        {
            "storyId": "demo-inv-nio",
            "storyTitle": "Nio's Turnaround — Buy or Fade?",
            "summary": "Nio posted first-ever profit. Jim Cramer reset his outlook. But China's EV price war raises margin concerns for Q2.",
            "tags": ["EV", "Earnings", "China"],
            "momentum": "Accelerating",
            "queryTerms": "Nio earnings profit stock",
            "articles": []
        },
        {
            "storyId": "demo-inv-jbs",
            "storyTitle": "JBS Earnings Beat — Food Giant Rising",
            "summary": "JBS reported $0.40 EPS, $23B revenue — beating estimates. Shares up 2.4%. Global protein market consolidation accelerates.",
            "tags": ["Earnings", "NYSE", "Food"],
            "momentum": "Accelerating",
            "queryTerms": "JBS earnings NYSE food",
            "articles": []
        },
        {
            "storyId": "demo-inv-lng",
            "storyTitle": "Golar LNG + Goldman Sachs Review",
            "summary": "Golar hired Goldman to explore M&A options. The FLNG pure-play could unlock value via sale or strategic partnership.",
            "tags": ["Energy", "M&A", "Goldman"],
            "momentum": "Heating Up",
            "queryTerms": "Golar LNG Goldman strategic review",
            "articles": []
        }
    ]
}

# Default for personas not explicitly listed
DEMO_STORIES["Entrepreneur"] = DEMO_STORIES["Student"]
DEMO_STORIES["Professional"] = DEMO_STORIES["Investor"]


def get_demo_feed(persona: str, interests: list) -> list:
    """Return demo story clusters based on persona."""
    return DEMO_STORIES.get(persona, DEMO_STORIES["Student"])


# Story arcs — SHORT summaries that fit in 3 lines on mobile
DEMO_ARCS = {
    "demo-ai-race": {
        "phases": [
            {"phase_name": "Beginning", "title": "ChatGPT Sparks AI Gold Rush", "summary": "OpenAI's ChatGPT triggered a global scramble. Google, Meta, and startups all raced to build competing AI models.", "sentiment": "Positive", "key_players": ["OpenAI", "Google", "Meta"], "contrarian_perspective": "Most AI hype is repackaged ML for investor buzz."},
            {"phase_name": "Build-up", "title": "$200B Pours Into AI Infra", "summary": "Microsoft invested $13B in OpenAI. Google launched Gemini. Meta open-sourced Llama. Biggest capex cycle in tech history.", "sentiment": "Positive", "key_players": ["Microsoft", "NVIDIA", "Amazon"], "contrarian_perspective": "AI capex could destroy value if monetization stalls."},
            {"phase_name": "Conflict", "title": "Regulation Strikes Back", "summary": "Sanders & AOC pushed a data center moratorium. EU AI Act imposed compliance costs. Meta hit with $6M addiction verdict.", "sentiment": "Negative", "key_players": ["Bernie Sanders", "AOC"], "contrarian_perspective": "Regulation helps incumbents by raising entry barriers."},
            {"phase_name": "Turning Point", "title": "OpenAI's $1B Safety Pivot", "summary": "OpenAI killed Sora over deepfake concerns and pledged $1B in safety grants. A shift from speed to responsible scaling.", "sentiment": "Neutral", "key_players": ["Sam Altman", "OpenAI"], "contrarian_perspective": "The $1B pledge is PR to preempt regulation."},
            {"phase_name": "What Next", "title": "The AI Agent Era Begins", "summary": "Expect M&A as small AI labs get acquired. AI agents that complete complex tasks autonomously will reshape work.", "sentiment": "Positive", "key_players": ["OpenAI", "Google", "Anthropic"], "contrarian_perspective": "AI agents face massive liability issues."}
        ]
    },
    "demo-ev-wars": {
        "phases": [
            {"phase_name": "Beginning", "title": "China Bets Big on EVs", "summary": "Government subsidies created the world's largest EV market. Nio, XPeng, and Li Auto challenged Tesla's dominance.", "sentiment": "Positive", "key_players": ["Chinese Gov", "Nio", "Tesla"], "contrarian_perspective": "Most Chinese EV startups were burning cash unsustainably."},
            {"phase_name": "Build-up", "title": "Price War Erupts", "summary": "Tesla slashed prices globally. BYD's low-cost models squeezed margins. 100+ EV brands fought for limited market share.", "sentiment": "Negative", "key_players": ["Elon Musk", "BYD"], "contrarian_perspective": "Price war is healthy — kills weak players fast."},
            {"phase_name": "Conflict", "title": "Nio Burns Through Cash", "summary": "Battery swap expansion bled cash. Stock dropped 70% from peak. Investors questioned whether Nio could survive.", "sentiment": "Negative", "key_players": ["William Li (CEO)", "Investors"], "contrarian_perspective": "Battery swap network is a strategic moat others can't copy."},
            {"phase_name": "Turning Point", "title": "Nio Posts First Profit", "summary": "Cost discipline and growing deliveries converged. Jim Cramer went from bearish to cautiously optimistic.", "sentiment": "Positive", "key_players": ["Jim Cramer", "William Li"], "contrarian_perspective": "One quarter profit doesn't make a trend."},
            {"phase_name": "What Next", "title": "Expand or Focus?", "summary": "Nio must choose: double down in China or push into Europe. EU tariffs on Chinese EVs complicate expansion.", "sentiment": "Neutral", "key_players": ["Nio", "EU Commission", "BYD"], "contrarian_perspective": "EU tariffs will be negotiated down within 18 months."}
        ]
    },
    "demo-social-media-law": {
        "phases": [
            {"phase_name": "Beginning", "title": "Addiction by Design", "summary": "Internal docs showed Meta and YouTube deliberately designed addictive features targeting young users.", "sentiment": "Negative", "key_players": ["Frances Haugen", "Meta"], "contrarian_perspective": "Every product is designed to be engaging."},
            {"phase_name": "Build-up", "title": "Whistleblowers Testify", "summary": "Haugen's testimony showed Meta knew Instagram harmed teen mental health. US states filed lawsuits against Big Tech.", "sentiment": "Negative", "key_players": ["Congress", "State AGs"], "contrarian_perspective": "Social media is a scapegoat for complex health issues."},
            {"phase_name": "Conflict", "title": "LA Trial Sets Precedent", "summary": "Jury found Meta 70% and YouTube 30% liable for mental health harm. $3M compensatory + $3M punitive damages awarded.", "sentiment": "Negative", "key_players": ["LA Superior Court"], "contrarian_perspective": "Damages are trivially small for these companies."},
            {"phase_name": "Turning Point", "title": "$6M Verdict Shockwave", "summary": "Small damages, massive precedent. Thousands of similar cases pending. Aggregate liability could reach billions.", "sentiment": "Neutral", "key_players": ["Lobbyists", "Safety Advocates"], "contrarian_perspective": "Legislation will move faster than courts."},
            {"phase_name": "What Next", "title": "Age Verification Era", "summary": "Expect mandatory age verification on all platforms. AI content moderation for minors becomes standard.", "sentiment": "Positive", "key_players": ["Regulators", "Meta", "Google"], "contrarian_perspective": "Kids will easily bypass age verification."}
        ]
    },
    "demo-energy-shift": {
        "phases": [
            {"phase_name": "Beginning", "title": "The FLNG Revolution", "summary": "Golar LNG pioneered floating gas liquefaction at sea, unlocking stranded reserves previously deemed uneconomical.", "sentiment": "Positive", "key_players": ["Golar LNG", "Petronas"], "contrarian_perspective": "FLNG is too niche to reshape energy markets."},
            {"phase_name": "Build-up", "title": "Energy Crisis Boosts LNG", "summary": "Europe's pivot from Russian gas created huge LNG demand. Golar transitioned to a pure-play FLNG operator.", "sentiment": "Positive", "key_players": ["European Buyers", "Golar"], "contrarian_perspective": "LNG demand is peaking as renewables expand."},
            {"phase_name": "Conflict", "title": "Capital vs Competition", "summary": "FLNG vessels cost billions and take years. Shell and Petronas entered with deeper pockets, squeezing Golar.", "sentiment": "Negative", "key_players": ["Shell", "Petronas"], "contrarian_perspective": "Golar's size lets it move faster on niche projects."},
            {"phase_name": "Turning Point", "title": "Goldman Sachs Hired", "summary": "Board appointed Goldman to explore options: full sale, divestiture, or major partnership. Signals undervaluation.", "sentiment": "Neutral", "key_players": ["Goldman Sachs", "Golar Board"], "contrarian_perspective": "Hiring Goldman often means management wants to sell."},
            {"phase_name": "What Next", "title": "Buyout or Partnership?", "summary": "Shell, TotalEnergies, or sovereign funds are potential acquirers. Announcement expected within 6 months.", "sentiment": "Positive", "key_players": ["Shell", "TotalEnergies"], "contrarian_perspective": "Majors will build their own FLNG in-house."}
        ]
    },
    "demo-inv-oracle": {
        "phases": [
            {"phase_name": "Beginning", "title": "Oracle's Cloud AI Pivot", "summary": "Oracle invested billions in GPU clusters and OCI Gen2. Ellison positioned it as the third cloud behind AWS and Azure.", "sentiment": "Positive", "key_players": ["Larry Ellison", "Safra Catz"], "contrarian_perspective": "Oracle is too late — AWS has 10+ years of lock-in."},
            {"phase_name": "Build-up", "title": "Stock Surges on AI Hype", "summary": "Shares rallied as investors priced in massive AI demand. Cloud bookings hit records, pushing valuations to highs.", "sentiment": "Positive", "key_players": ["Wall Street", "Institutions"], "contrarian_perspective": "Rally built on projections, not delivered revenue."},
            {"phase_name": "Conflict", "title": "Accounting Questions", "summary": "Lawsuits allege Oracle inflated cloud growth metrics. Stock dropped as short-sellers published critical research.", "sentiment": "Negative", "key_players": ["Bragar Eagel", "Short Sellers"], "contrarian_perspective": "Revenue recognition follows standard GAAP rules."},
            {"phase_name": "Turning Point", "title": "April 6th Deadline Looms", "summary": "Investors must act by April 6th to join the class action. Outcome determines if Oracle faces real liability.", "sentiment": "Neutral", "key_players": ["Oracle Legal", "Plaintiffs"], "contrarian_perspective": "These lawsuits always settle for pennies."},
            {"phase_name": "What Next", "title": "Earnings Will Decide", "summary": "Next earnings is the true test. If cloud growth stays above 30%, lawsuits are noise. If not, questions gain credibility.", "sentiment": "Neutral", "key_players": ["Safra Catz", "Analysts"], "contrarian_perspective": "Enterprise installed base provides a revenue floor."}
        ]
    },
    "demo-inv-nio": None,
    "demo-inv-jbs": {
        "phases": [
            {"phase_name": "Beginning", "title": "Brazil's Meat Giant Goes Global", "summary": "JBS grew from a small slaughterhouse to the world's largest protein company through aggressive acquisitions.", "sentiment": "Positive", "key_players": ["Batista Family", "JBS"], "contrarian_perspective": "Growth was fueled by political corruption."},
            {"phase_name": "Build-up", "title": "NYSE Listing Opens Doors", "summary": "Dual listing attracted US institutional investors. Wall Street coverage increased, reducing the EM discount.", "sentiment": "Positive", "key_players": ["NYSE", "US Investors"], "contrarian_perspective": "Dual listing doesn't fix governance issues."},
            {"phase_name": "Conflict", "title": "Margin Squeeze", "summary": "Rising feed costs and labor shortages hit margins. Stock underperformed despite diversification across proteins.", "sentiment": "Negative", "key_players": ["Commodity Markets", "Labor"], "contrarian_perspective": "Cyclical compression — dip buyers always win."},
            {"phase_name": "Turning Point", "title": "Q4 Earnings Beat", "summary": "JBS hit $0.40 EPS, $23B revenue. Shares rose 2.4%. US beef margins and global poultry demand drove the beat.", "sentiment": "Positive", "key_players": ["JBS CFO", "Analysts"], "contrarian_perspective": "One good quarter doesn't prove a turnaround."},
            {"phase_name": "What Next", "title": "Protein Consolidation", "summary": "JBS positioned to acquire rivals as high rates force sales. Scale makes it the natural industry consolidator.", "sentiment": "Positive", "key_players": ["JBS M&A", "Private Equity"], "contrarian_perspective": "Antitrust will block further consolidation."}
        ]
    },
    "demo-inv-lng": None,
}

# Map redirects
DEMO_ARCS["demo-inv-nio"] = DEMO_ARCS["demo-ev-wars"]
DEMO_ARCS["demo-inv-lng"] = DEMO_ARCS["demo-energy-shift"]


def get_demo_arc(query_terms: str, persona: str) -> dict:
    """Find the best matching demo arc for a given query."""
    query_lower = query_terms.lower()
    
    keyword_map = {
        "demo-ai-race": ["ai", "openai", "google", "regulation", "data center", "sora"],
        "demo-ev-wars": ["ev", "nio", "tesla", "electric", "byd", "cramer"],
        "demo-social-media-law": ["meta", "youtube", "addiction", "lawsuit", "social media", "damages"],
        "demo-energy-shift": ["lng", "golar", "goldman", "energy", "flng", "gas"],
        "demo-inv-oracle": ["oracle", "orcl", "lawsuit", "investor alert", "bragar"],
        "demo-inv-jbs": ["jbs", "earnings", "protein", "food", "meat"],
    }
    
    best_match = None
    best_score = 0
    
    for arc_id, keywords in keyword_map.items():
        score = sum(1 for kw in keywords if kw in query_lower)
        if score > best_score:
            best_score = score
            best_match = arc_id
    
    if best_match and best_match in DEMO_ARCS and DEMO_ARCS[best_match]:
        return DEMO_ARCS[best_match]
    
    return DEMO_ARCS["demo-ai-race"]
