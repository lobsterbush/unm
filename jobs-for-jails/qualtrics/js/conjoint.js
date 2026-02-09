// ==============================================================================
// Jobs for Jails: Conjoint Experiment JavaScript for Qualtrics
// ==============================================================================
// Purpose: Generate randomized conjoint profiles and capture choices
// Author: Charles Crabtree
// ==============================================================================

Qualtrics.SurveyEngine.addOnload(function() {
    
    // ==============================================================================
    // CONJOINT DESIGN CONFIGURATION
    // ==============================================================================
    
    var conjointDesign = {
        
        // Attribute 1: Target Type
        target_type: {
            label: "Target of Enforcement",
            levels: [
                "Undocumented workers at a local business",
                "Individuals with prior criminal convictions",
                "Families in a residential neighborhood",
                "Individuals at a courthouse"
            ]
        },
        
        // Attribute 2: Economic Impact
        economic_impact: {
            label: "Economic Impact",
            levels: [
                "Will create 50 local jobs through increased enforcement",
                "Will have no effect on local employment",
                "May result in the loss of 50 local jobs"
            ]
        },
        
        // Attribute 3: Enforcement Method
        enforcement_method: {
            label: "Enforcement Method",
            levels: [
                "Workplace inspection with advance notice",
                "Unannounced workplace raid",
                "Home visits by ICE agents",
                "Arrests at public locations"
            ]
        },
        
        // Attribute 4: Federal Funding
        federal_funding: {
            label: "Federal Funding to County",
            levels: [
                "County will receive $5 million in federal funding",
                "County will receive $500,000 in federal funding",
                "No additional federal funding"
            ]
        },
        
        // Attribute 5: Local Police Cooperation
        local_cooperation: {
            label: "Local Police Involvement",
            levels: [
                "Local police will assist ICE",
                "Local police will not assist but won't interfere",
                "Local police prohibited from assisting ICE"
            ]
        }
    };
    
    // Get current task number (1-5)
    var taskNumber = parseInt("${e://Field/conjoint_task}") || 1;
    
    // ==============================================================================
    // RANDOMIZATION FUNCTIONS
    // ==============================================================================
    
    // Fisher-Yates shuffle
    function shuffle(array) {
        var currentIndex = array.length, temporaryValue, randomIndex;
        while (0 !== currentIndex) {
            randomIndex = Math.floor(Math.random() * currentIndex);
            currentIndex -= 1;
            temporaryValue = array[currentIndex];
            array[currentIndex] = array[randomIndex];
            array[randomIndex] = temporaryValue;
        }
        return array;
    }
    
    // Get random element from array
    function getRandomElement(array) {
        return array[Math.floor(Math.random() * array.length)];
    }
    
    // Generate a single profile
    function generateProfile() {
        var profile = {};
        for (var attr in conjointDesign) {
            profile[attr] = getRandomElement(conjointDesign[attr].levels);
        }
        return profile;
    }
    
    // ==============================================================================
    // GENERATE TWO PROFILES
    // ==============================================================================
    
    var profileA = generateProfile();
    var profileB = generateProfile();
    
    // Ensure profiles are different on at least one attribute
    var attempts = 0;
    while (JSON.stringify(profileA) === JSON.stringify(profileB) && attempts < 10) {
        profileB = generateProfile();
        attempts++;
    }
    
    // ==============================================================================
    // BUILD HTML TABLE
    // ==============================================================================
    
    var tableHTML = '<table class="conjoint-table" style="width:100%; border-collapse:collapse; margin:20px 0;">';
    
    // Header row
    tableHTML += '<tr style="background-color:#f5f5f5;">';
    tableHTML += '<th style="padding:12px; border:1px solid #ddd; text-align:left; width:30%;">Attribute</th>';
    tableHTML += '<th style="padding:12px; border:1px solid #ddd; text-align:center; width:35%;">Option A</th>';
    tableHTML += '<th style="padding:12px; border:1px solid #ddd; text-align:center; width:35%;">Option B</th>';
    tableHTML += '</tr>';
    
    // Attribute rows (randomize order)
    var attributeOrder = shuffle(Object.keys(conjointDesign));
    
    for (var i = 0; i < attributeOrder.length; i++) {
        var attr = attributeOrder[i];
        var rowColor = (i % 2 === 0) ? '#ffffff' : '#fafafa';
        
        tableHTML += '<tr style="background-color:' + rowColor + ';">';
        tableHTML += '<td style="padding:10px; border:1px solid #ddd; font-weight:bold;">' + 
                     conjointDesign[attr].label + '</td>';
        tableHTML += '<td style="padding:10px; border:1px solid #ddd; text-align:center;">' + 
                     profileA[attr] + '</td>';
        tableHTML += '<td style="padding:10px; border:1px solid #ddd; text-align:center;">' + 
                     profileB[attr] + '</td>';
        tableHTML += '</tr>';
    }
    
    tableHTML += '</table>';
    
    // ==============================================================================
    // INSERT INTO QUESTION
    // ==============================================================================
    
    // Find the question container and insert the table
    var questionContainer = this.getQuestionContainer();
    var questionText = questionContainer.querySelector('.QuestionText');
    
    if (questionText) {
        // Add task counter
        var taskInfo = '<p style="margin-bottom:15px; color:#666;">Task ' + taskNumber + ' of 5</p>';
        questionText.innerHTML = taskInfo + 
            '<p style="margin-bottom:10px;"><strong>Please review the two immigration enforcement scenarios below and indicate which one you would support:</strong></p>' +
            tableHTML;
    }
    
    // ==============================================================================
    // STORE DATA IN EMBEDDED DATA FIELDS
    // ==============================================================================
    
    // Store Profile A attributes
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_A_target', profileA.target_type);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_A_economic', profileA.economic_impact);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_A_method', profileA.enforcement_method);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_A_funding', profileA.federal_funding);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_A_cooperation', profileA.local_cooperation);
    
    // Store Profile B attributes
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_B_target', profileB.target_type);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_B_economic', profileB.economic_impact);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_B_method', profileB.enforcement_method);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_B_funding', profileB.federal_funding);
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_B_cooperation', profileB.local_cooperation);
    
    // Store attribute order for analysis
    Qualtrics.SurveyEngine.setEmbeddedData('task' + taskNumber + '_attr_order', attributeOrder.join('|'));
    
});

Qualtrics.SurveyEngine.addOnReady(function() {
    // Additional styling if needed
    var style = document.createElement('style');
    style.textContent = `
        .conjoint-table {
            font-size: 14px;
            line-height: 1.5;
        }
        .conjoint-table th {
            font-size: 15px;
        }
        .conjoint-table td, .conjoint-table th {
            vertical-align: middle;
        }
        @media (max-width: 600px) {
            .conjoint-table {
                font-size: 12px;
            }
            .conjoint-table td, .conjoint-table th {
                padding: 8px 5px;
            }
        }
    `;
    document.head.appendChild(style);
});

Qualtrics.SurveyEngine.addOnUnload(function() {
    // Increment task counter for next question
    var currentTask = parseInt("${e://Field/conjoint_task}") || 1;
    Qualtrics.SurveyEngine.setEmbeddedData('conjoint_task', currentTask + 1);
});
