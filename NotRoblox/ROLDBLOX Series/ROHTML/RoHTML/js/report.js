document.addEventListener('DOMContentLoaded', () => {

    // --- UTILITY ---
    // A local copy of the createSelector function from settings.js to make this self-contained
    function createSelector(container, options, initialValue, onChange) {
        if (!container) return;
        container.innerHTML = ''; // Clear previous content
        const leftButton = document.createElement('button'); leftButton.className = 'selector-button left';
        const textContainer = document.createElement('div'); textContainer.className = 'selector-text-container'; textContainer.style.cursor = 'pointer';
        const rightButton = document.createElement('button'); rightButton.className = 'selector-button right';
        container.append(leftButton, textContainer, rightButton);
        let currentIndex; let isAnimating = false;
        const optionSpans = options.map(optionText => {
            const span = document.createElement('span'); span.className = 'selector-text'; span.textContent = optionText; textContainer.appendChild(span); return span;
        });
        function updateSelector(index, fromClick = false, direction = 1) {
            if (isAnimating) return;
            const oldIndex = currentIndex; const newIndex = (index + options.length) % options.length;
            if (fromClick && newIndex === oldIndex) return;
            isAnimating = true;
            const oldSpan = optionSpans[oldIndex]; const newSpan = optionSpans[newIndex];
            if (!oldSpan || !newSpan) { isAnimating = false; return; }
            const outClass = direction === 1 ? 'slide-out-left' : 'slide-out-right';
            const inClass = direction === 1 ? 'slide-in-from-right' : 'slide-in-from-left';
            const onAnimationEnd = () => {
                newSpan.removeEventListener('animationend', onAnimationEnd);
                oldSpan.className = 'selector-text'; newSpan.className = 'selector-text active'; isAnimating = false;
            };
            newSpan.addEventListener('animationend', onAnimationEnd);
            oldSpan.classList.remove('active'); oldSpan.classList.add(outClass); newSpan.classList.add(inClass);
            currentIndex = newIndex;
            if (fromClick && onChange) { onChange(options[currentIndex]); }
        }
        function setInitialState(value) {
            let initialIndex = options.indexOf(value);
            if (initialIndex === -1) initialIndex = 0;
            currentIndex = initialIndex;
            optionSpans.forEach((span, i) => {
                span.className = 'selector-text'; if (i === currentIndex) { span.classList.add('active'); }
            });
        }
        leftButton.addEventListener('click', () => updateSelector(currentIndex - 1, true, -1));
        rightButton.addEventListener('click', () => updateSelector(currentIndex + 1, true, 1));
        textContainer.addEventListener('click', () => updateSelector(currentIndex + 1, true, 1));
        setInitialState(initialValue);
    }


    // --- CONSTANTS & STATE ---
    const ABUSE_TYPES_PLAYER = [ "Swearing", "Inappropriate Username", "Bullying", "Scamming", "Dating", "Cheating/Exploiting", "Personal Question", "Offsite Links" ];
    const ABUSE_TYPES_GAME = ["Inappropriate Content", "Bad Model or Script", "Offsite Link"];
    let activeDropdown = null; // Stores the button that opened the dropdown
    let isReportingPlayer = false;


    // --- DOM ELEMENTS ---
    const reportTypeSelectorEl = document.getElementById('report-type-selector');
    const whichPlayerRow = document.getElementById('report-which-player-row');
    const whichPlayerBtn = document.getElementById('report-which-player-dropdown');
    const abuseTypeBtn = document.getElementById('report-abuse-type-dropdown');
    const fullscreenFrame = document.getElementById('report-dropdown-fullscreen-frame');
    const scrollingFrame = document.getElementById('report-dropdown-scrolling-frame');
    const submitButton = document.getElementById('report-submit-button');
    const descriptionTextarea = document.getElementById('report-description-textarea');
    const thanksDialog = document.getElementById('confirmation-thanks');
    const thanksOkButton = document.getElementById('report-thanks-ok-button');


    // --- CORE FUNCTIONS ---

    function selectOption(optionText) {
        if (activeDropdown) {
            const textElement = activeDropdown.querySelector('.dropdown-button-text');
            if (textElement) {
                textElement.textContent = optionText;
            }
        }
        closeDropdown();
    }

    function openDropdown(button, options) {
        activeDropdown = button;
        if (!scrollingFrame || !fullscreenFrame) return;

        scrollingFrame.innerHTML = ''; // Clear previous options
        options.forEach(optionText => {
            const optionBtn = document.createElement('button');
            optionBtn.className = 'report-dropdown-option';
            optionBtn.textContent = optionText;
            optionBtn.onclick = () => selectOption(optionText);
            scrollingFrame.appendChild(optionBtn);
        });
        fullscreenFrame.classList.remove('hidden');
    }

    function closeDropdown() {
        if (fullscreenFrame) fullscreenFrame.classList.add('hidden');
        activeDropdown = null;
        validateForm();
    }

    function updateReportUI() {
        if (!whichPlayerRow || !abuseTypeBtn) return;
        
        // Toggle visibility of the player selection row
        whichPlayerRow.style.display = isReportingPlayer ? 'flex' : 'none';

        // Reset the text of the dropdowns
        const abuseTypeText = abuseTypeBtn.querySelector('.dropdown-button-text');
        
        if (abuseTypeText) abuseTypeText.textContent = "Choose One";

        if (isReportingPlayer) {
             const whichPlayerText = whichPlayerBtn.querySelector('.dropdown-button-text');
             if(whichPlayerText) whichPlayerText.textContent = "Choose One";
        }
        validateForm();
    }

    function validateForm() {
        let isValid = false;
        const abuseTypeSelected = abuseTypeBtn.querySelector('.dropdown-button-text').textContent !== 'Choose One';

        if (isReportingPlayer) {
            const playerSelected = whichPlayerBtn.querySelector('.dropdown-button-text').textContent !== 'Choose One';
            isValid = playerSelected && abuseTypeSelected;
        } else {
            isValid = abuseTypeSelected;
        }
        submitButton.disabled = !isValid;
    }

    function resetReportForm() {
        const abuseTypeText = abuseTypeBtn.querySelector('.dropdown-button-text');
        if (abuseTypeText) abuseTypeText.textContent = 'Choose One';
        
        if (isReportingPlayer) {
            const whichPlayerText = whichPlayerBtn.querySelector('.dropdown-button-text');
            if (whichPlayerText) whichPlayerText.textContent = 'Choose One';
        }
        
        descriptionTextarea.value = '';
        validateForm();
    }

    function showThanksDialog() {
        if (thanksDialog) {
            document.getElementById('settings-menu-container').style.display = 'none';
            thanksDialog.style.display = 'flex';
            thanksOkButton.focus(); // Set focus to the OK button
        }
    }

    function hideThanksDialog() {
        if (thanksDialog) {
            thanksDialog.style.display = 'none';
            document.getElementById('settings-menu-container').style.display = 'flex';
        }
    }


    // --- EVENT LISTENERS ---

    // Initialize the main selector
    createSelector(reportTypeSelectorEl, ['Game', 'Player'], 'Game', (selectedValue) => {
        isReportingPlayer = (selectedValue === 'Player');
        updateReportUI();
    });

    // Dropdown open listeners
    if (whichPlayerBtn) {
        whichPlayerBtn.addEventListener('click', () => {
            const dropdownId = whichPlayerBtn.id;
            if (dropdownId === 'report-which-player-dropdown') {
                const optionsContainer = document.getElementById('report-dropdown-scrolling-frame');
                optionsContainer.innerHTML = ''; // Clear previous options

                // Use the new config structure
                if (window.ROHTML_CONFIG && window.ROHTML_CONFIG.testing && window.ROHTML_CONFIG.testing.dummyPlayers) {
                    const players = window.ROHTML_CONFIG.testing.dummyPlayers.filter(p => p !== window.ROHTML_CONFIG.testing.localPlayerName);
                    players.forEach(player => {
                        const option = document.createElement('button');
                        option.className = 'report-dropdown-option';
                        option.textContent = player;
                        option.onclick = () => selectOption(player);
                        optionsContainer.appendChild(option);
                    });
                }
            }
            fullscreenFrame.classList.remove('hidden');
        });
    }

    if (abuseTypeBtn) {
        abuseTypeBtn.addEventListener('click', () => {
            const options = isReportingPlayer ? ABUSE_TYPES_PLAYER : ABUSE_TYPES_GAME;
            openDropdown(abuseTypeBtn, options);
        });
    }
    
    // Submit button listener
    if (submitButton) {
        submitButton.addEventListener('click', () => {
            if (submitButton.disabled) return;
            
            // Call a global function defined in settings.js
            if (window.ROHTML && window.ROHTML.showThanksPage) {
                window.ROHTML.showThanksPage(isReportingPlayer);
            }
        });
    }

    // Thanks dialog OK button listener is now handled in settings.js
    
    // Global key listener for the confirmation dialog
    document.addEventListener('keydown', (event) => {
        if (thanksDialog.style.display === 'flex' && event.key === 'Enter') {
            // Check if the OK button is the active element or if no specific element has focus within the dialog
            if (document.activeElement === thanksOkButton || document.activeElement === document.body) {
                thanksOkButton.click();
            }
        }
    });

    // Fullscreen close listener
    if (fullscreenFrame) {
        fullscreenFrame.addEventListener('click', (event) => {
            if (event.target === fullscreenFrame) {
                closeDropdown();
            }
        });
    }

    // --- INITIAL STATE ---
    updateReportUI();
}); 