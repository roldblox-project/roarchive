document.addEventListener('DOMContentLoaded', () => {
    // --- GLOBAL NAMESPACE ---
    window.ROHTML = window.ROHTML || {};

    // --- DOM ELEMENTS ---
    const menuButton = document.getElementById('menu-button');
    const settingsClippingShield = document.getElementById('settings-clipping-shield');
    const settingsShield = document.getElementById('settings-shield');
    const topbar = document.getElementById('topbar');
    const settingsMenuContainer = document.getElementById('settings-menu-container');
    const resetCharButton = document.getElementById('reset-char-button');
    const leaveGameButton = document.getElementById('leave-game-button');
    const resetPage = document.getElementById('reset-character-page');
    const leavePage = document.getElementById('leave-game-page');
    const resetConfirmButton = document.getElementById('reset-confirm-button');
    const resetCancelButton = document.getElementById('reset-cancel-button');
    const leaveConfirmButton = document.getElementById('leave-confirm-button');
    const leaveCancelButton = document.getElementById('leave-cancel-button');
    const thanksPage = document.getElementById('thanks-page');
    const thanksOkButton = document.getElementById('thanks-ok-button');
    const thanksGamePage = document.getElementById('thanks-game-page');
    const thanksGameOkButton = document.getElementById('thanks-game-ok-button');
    const thanksPlayerPage = document.getElementById('thanks-player-page');
    const thanksPlayerOkButton = document.getElementById('thanks-player-ok-button');

    let activeConfirmationPage = null;
    let settingsVisible = false;

    function showConfirmationPage(page) {
        if (!page) return;
        settingsMenuContainer.style.display = 'none';
        page.style.display = 'flex';
        activeConfirmationPage = page;
        // Focus the default button
        const defaultButton = page.querySelector('.confirmation-button.selected');
        if (defaultButton) {
            defaultButton.focus();
        }
    }

    function hideConfirmationPage() {
        if (!activeConfirmationPage) return;
        activeConfirmationPage.style.display = 'none';
        settingsMenuContainer.style.display = 'flex';
        activeConfirmationPage = null;
    }

    if (resetCharButton) {
        resetCharButton.addEventListener('click', () => showConfirmationPage(resetPage));
    }
    if (leaveGameButton) {
        leaveGameButton.addEventListener('click', () => showConfirmationPage(leavePage));
    }
    if (resetCancelButton) {
        resetCancelButton.addEventListener('click', hideConfirmationPage);
    }
    if (leaveCancelButton) {
        leaveCancelButton.addEventListener('click', hideConfirmationPage);
    }
    if (thanksOkButton) {
        thanksOkButton.addEventListener('click', hideConfirmationPage);
    }

    if (resetConfirmButton) {
        resetConfirmButton.addEventListener('click', () => {
            console.log("Character reset!");
            setSettingsVisible(false, true); // Instant close
        });
    }

    if (leaveConfirmButton) {
        leaveConfirmButton.addEventListener('click', () => {
            window.close(); // Note: May not work in all browser contexts
            setSettingsVisible(false, true); // Instant close
        });
    }

    // --- Tab Switching Logic ---
    const tabs = document.querySelectorAll('.settings-tab');
    const pageView = document.getElementById('page-view');
    const tabMap = {
        'players': 0,
        'settings': 1,
        'report': 2,
        'help': 3,
        'record': 4
    };

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            const pageIndex = tabMap[tab.dataset.page];
            pageView.style.transform = `translateX(-${pageIndex * 20}%)`;
        });
    });
    // End Tab Switching Logic

    // -- Bottom Bar Logic --
    const resumeButton = document.getElementById('resume-button');
    if(resumeButton) {
        resumeButton.addEventListener('click', () => {
            setSettingsVisible(false);
        });
    }
    // End Bottom Bar Logic

    // --- GLOBAL FUNCTIONS ---
    window.ROHTML.showThanksPage = function(isPlayerReport) {
        const pageToShow = isPlayerReport ? thanksPlayerPage : thanksGamePage;
        showConfirmationPage(pageToShow);
    };

    // --- EVENT LISTENERS ---
    if (resetCharButton) {
        resetCharButton.addEventListener('click', () => showConfirmationPage(resetPage));
    }
    if (leaveGameButton) {
        leaveGameButton.addEventListener('click', () => showConfirmationPage(leavePage));
    }
    if (resetCancelButton) {
        resetCancelButton.addEventListener('click', hideConfirmationPage);
    }
    if (leaveCancelButton) {
        leaveCancelButton.addEventListener('click', hideConfirmationPage);
    }
    if (thanksGameOkButton) {
        // For thanks pages, the OK button should close the entire menu instantly.
        thanksGameOkButton.addEventListener('click', () => setSettingsVisible(false, true));
    }
    if (thanksPlayerOkButton) {
        // For thanks pages, the OK button should close the entire menu instantly.
        thanksPlayerOkButton.addEventListener('click', () => setSettingsVisible(false, true));
    }

    // --- KEYBINDINGS ---
    document.addEventListener('keydown', (event) => {
        // Handle Escape key globally
        if (event.key === 'Escape') {
            if (activeConfirmationPage) {
                // On thanks pages, Escape closes everything instantly.
                if (activeConfirmationPage === thanksGamePage || activeConfirmationPage === thanksPlayerPage) {
                    setSettingsVisible(false, true);
                } else {
                    // On other confirmation pages, Escape is a "cancel" action.
                    hideConfirmationPage();
                }
            } else {
                // If no confirmation page is active, Escape toggles the main menu visibility.
                setSettingsVisible(!settingsVisible);
            }
            return; // Stop further processing
        }

        // Handle Enter key only on active confirmation pages
        if (event.key === 'Enter' && activeConfirmationPage) {
            const defaultButton = activeConfirmationPage.querySelector('.confirmation-button.selected');
            if (defaultButton) {
                defaultButton.click();
            }
            return; // Stop further processing
        }

        // Handle Tab key only on the main menu
        if (event.key === 'Tab' && settingsVisible && !activeConfirmationPage) {
            event.preventDefault(); // Prevent default focus stealing
            const tabsArray = Array.from(tabs);
            const currentIndex = tabsArray.findIndex(tab => tab.classList.contains('active'));
            const nextIndex = (currentIndex + 1) % tabsArray.length;
            tabsArray[nextIndex].click();
        }
        
        // Handle other keys only when settings are visible and no confirmation page is active
        if (settingsVisible && !activeConfirmationPage) {
            // We also check that the user isn't typing in an input field
            if (document.activeElement.tagName.toLowerCase() !== 'input' && document.activeElement.tagName.toLowerCase() !== 'textarea') {
                if (event.key.toLowerCase() === 'r') {
                    event.preventDefault(); // Prevent default browser action
                    showConfirmationPage(resetPage);
                }
                if (event.key.toLowerCase() === 'l') {
                    event.preventDefault(); // Prevent default browser action
                    showConfirmationPage(leavePage);
                }
            }
        }
    });

    // Store initial state
    const initialTopbarColor = topbar.style.backgroundColor;
    let topbarTimeout;

    function setSettingsVisible(visible, instant = false) {
        if (visible) {
            // Call this before the menu becomes visible
            if (window.ROHTML && window.ROHTML.onMenuOpen) {
                window.ROHTML.onMenuOpen();
            }
        }

        if (instant && !visible) {
            settingsShield.style.transition = 'none';
        }

        // When closing, always hide confirmation pages and show the main menu
        if (!visible) {
            hideConfirmationPage(); // This now handles the active page correctly

            // Call this as the menu starts to close
            if (window.ROHTML && window.ROHTML.onMenuClose) {
                window.ROHTML.onMenuClose();
            }

            // Reset to the default 'Players' tab
            tabs.forEach(t => t.classList.remove('active'));
            const defaultTab = document.querySelector('.settings-tab[data-page="players"]');
            if (defaultTab) {
                defaultTab.classList.add('active');
            }
            pageView.style.transform = `translateX(0%)`; // Players tab is at index 0
        }

        settingsVisible = visible;
        settingsClippingShield.classList.toggle('settings-visible', visible);

        clearTimeout(topbarTimeout);

        if (visible) {
            topbar.style.backgroundColor = 'rgb(31, 31, 31)';
            menuButton.style.backgroundImage = `url('content/textures/ui/Menu/HamburgerDown.png')`;
        } else {
            // Instantly change the icon when closing starts
            menuButton.style.backgroundImage = `url('content/textures/ui/Menu/Hamburger.png')`;
            
            const changeTopbarColor = () => {
                const TOPBAR_BACKGROUND_COLOR = [31, 31, 31];
                topbar.style.backgroundColor = `rgba(${TOPBAR_BACKGROUND_COLOR.join(',')}, ${ROHTML_CONFIG.topbarTransparency})`;
            };

            if (instant) {
                changeTopbarColor();
            } else {
                // Delay the topbar transparency change until after the animation
                topbarTimeout = setTimeout(changeTopbarColor, 400); // Delay matches the CSS animation duration
            }
        }

        if (instant && !visible) {
            // Use a timeout to restore the transition after the style changes have been applied
            setTimeout(() => {
                settingsShield.style.transition = ''; // Restore to CSS default
            }, 50);
        }
    }

    menuButton.addEventListener('click', () => {
        setSettingsVisible(!settingsVisible);
    });

    settingsClippingShield.addEventListener('click', (event) => {
        // Only close if the click is on the clipping shield itself, not its children
        if (event.target === settingsClippingShield) {
            setSettingsVisible(false);
        }
    });

    const volumeSound = new Audio('content/sounds/metalstone2.mp3');
    volumeSound.onerror = () => {
        // This will fail silently if the file doesn't exist, which is fine.
        // The user can add the file if they want the sound.
        console.warn("Could not load 'uuhhh.mp3'. Place it in 'content/sounds/' to enable volume feedback.");
    };


    // --- Settings Controls Initialization ---
    function createSlider(container, steps, initialValue, settingKey, playSoundOnUpdate = false) {
        const leftButton = document.createElement('button');
        leftButton.className = 'slider-button left';

        const stepsContainer = document.createElement('div');
        stepsContainer.className = 'slider-steps-container';

        const rightButton = document.createElement('button');
        rightButton.className = 'slider-button right';

        container.append(leftButton, stepsContainer, rightButton);

        let currentValue = initialValue;
        let holdInterval;
        let isDragging = false;

        const stepElements = [];
        for (let i = 0; i < steps; i++) {
            const step = document.createElement('div');
            step.className = 'slider-step';
            step.dataset.step = i + 1;
            stepsContainer.appendChild(step);
            stepElements.push(step);
        }

        function updateSlider(value, fromClick = false) {
            const oldValue = currentValue;
            const newValue = Math.max(0, Math.min(steps, value));

            if (newValue === oldValue && fromClick) return; // Only exit if from an event, allow initial set

            currentValue = newValue;

            stepElements.forEach((step, i) => {
                step.classList.toggle('active', i < currentValue);
            });

            if (fromClick) {
                updateSetting(settingKey, currentValue);
                if (playSoundOnUpdate) {
                    volumeSound.volume = currentValue / steps;
                    if (volumeSound.readyState >= 2) { // Ensure sound is loaded
                        volumeSound.currentTime = 0;
                        volumeSound.play().catch(e => { /* Fail silently */ });
                    }
                }
            }
        }

        const startHolding = (direction) => {
            if (holdInterval) clearInterval(holdInterval);
            const move = () => updateSlider(currentValue + direction, true);
            move(); // Initial move
            holdInterval = setInterval(move, 120);
        };

        const stopHolding = () => {
            clearInterval(holdInterval);
        };

        const handleDrag = (e) => {
            if (!isDragging) return;
            const rect = stepsContainer.getBoundingClientRect();
            const x = (e.clientX || e.touches[0].clientX) - rect.left;
            let value = Math.round((x / rect.width) * steps);
            updateSlider(value, true);
        };

        stepsContainer.addEventListener('mousedown', (e) => {
            isDragging = true;
            handleDrag(e); // Update on initial click
        });
        stepsContainer.addEventListener('touchstart', (e) => {
            isDragging = true;
            handleDrag(e);
        });

        document.addEventListener('mousemove', handleDrag);
        document.addEventListener('touchmove', handleDrag);

        document.addEventListener('mouseup', () => isDragging = false);
        document.addEventListener('touchend', () => isDragging = false);


        ['mousedown', 'touchstart'].forEach(evt => {
            leftButton.addEventListener(evt, (e) => { e.preventDefault(); startHolding(-1); });
            rightButton.addEventListener(evt, (e) => { e.preventDefault(); startHolding(1); });
        });

        ['mouseup', 'mouseleave', 'touchend', 'touchcancel'].forEach(evt => {
            document.addEventListener(evt, stopHolding);
        });

        stepElements.forEach(step => {
            step.addEventListener('click', () => updateSlider(parseInt(step.dataset.step), true));
        });
        
        container.update = updateSlider;
        updateSlider(initialValue);
    }

    function createSelector(container, options, initialValue, settingKey) {
        const leftButton = document.createElement('button');
        leftButton.className = 'selector-button left';

        const textContainer = document.createElement('div');
        textContainer.className = 'selector-text-container';
        textContainer.style.cursor = 'pointer';
        
        const rightButton = document.createElement('button');
        rightButton.className = 'selector-button right';

        container.append(leftButton, textContainer, rightButton);

        let currentIndex;
        let isAnimating = false;

        const optionSpans = options.map(optionText => {
            const span = document.createElement('span');
            span.className = 'selector-text';
            span.textContent = optionText;
            textContainer.appendChild(span);
            return span;
        });

        function updateSelector(index, fromClick = false, direction = 1) {
            // Ignore new clicks if an animation is already in progress
            if (isAnimating) return;

            const oldIndex = currentIndex;
            const newIndex = (index + options.length) % options.length;

            if (fromClick && newIndex === oldIndex) return;
            
            isAnimating = true;

            const oldSpan = optionSpans[oldIndex];
            const newSpan = optionSpans[newIndex];

            const outClass = direction === 1 ? 'slide-out-left' : 'slide-out-right';
            const inClass = direction === 1 ? 'slide-in-from-right' : 'slide-in-from-left';

            // Use 'animationend' to clean up classes after the new span finishes sliding in.
            // This is the most reliable way to handle animation cleanup.
            const onAnimationEnd = () => {
                newSpan.removeEventListener('animationend', onAnimationEnd);

                // Reset the elements to their final, non-animating state
                oldSpan.className = 'selector-text';
                newSpan.className = 'selector-text active';

                // Animation is finished, allow new clicks
                isAnimating = false;
            };
            newSpan.addEventListener('animationend', onAnimationEnd);

            // Remove the 'active' class from the old span and apply the animation classes
            oldSpan.classList.remove('active');
            oldSpan.classList.add(outClass);
            newSpan.classList.add(inClass);
            
            currentIndex = newIndex;

             if (fromClick) {
                let valueToSave = options[currentIndex];
                if (valueToSave === 'On') valueToSave = true;
                if (valueToSave === 'Off') valueToSave = false;
                updateSetting(settingKey, valueToSave);
            }
        }
        
        function setInitialState(value) {
            let initialIndex;
            if (typeof value === 'boolean') {
                initialIndex = value ? options.indexOf('On') : options.indexOf('Off');
            } else {
                initialIndex = options.indexOf(value);
    }

            if (initialIndex === -1) initialIndex = 0;
            
            currentIndex = initialIndex;
            
            optionSpans.forEach((span, i) => {
                span.className = 'selector-text';
                if (i === currentIndex) {
                    span.classList.add('active');
                }
            });
        }

        leftButton.addEventListener('click', () => updateSelector(currentIndex - 1, true, -1));
        rightButton.addEventListener('click', () => updateSelector(currentIndex + 1, true, 1));
        textContainer.addEventListener('click', () => updateSelector(currentIndex + 1, true, 1));

        container.update = setInitialState;
        setInitialState(initialValue);
    }

    function initializeSettingsControls() {
        // Shift Lock Selector
        const shiftLockSelector = document.getElementById('shift-lock-selector');
        if (shiftLockSelector) {
            const options = JSON.parse(shiftLockSelector.dataset.options);
            createSelector(shiftLockSelector, options, getSetting('shiftLockSwitch') ? 'On' : 'Off', 'shiftLockSwitch');
        }

        // Camera Mode Selector
        const cameraModeSelector = document.getElementById('camera-mode-selector');
        if (cameraModeSelector) {
            const options = JSON.parse(cameraModeSelector.dataset.options);
            createSelector(cameraModeSelector, options, getSetting('cameraMode'), 'cameraMode');
        }

        // Movement Mode Selector
        const movementModeSelector = document.getElementById('movement-mode-selector');
        if (movementModeSelector) {
            const options = JSON.parse(movementModeSelector.dataset.options);
            createSelector(movementModeSelector, options, getSetting('movementMode'), 'movementMode');
        }

        // Camera Sensitivity Slider
        const cameraSensitivitySlider = document.getElementById('camera-sensitivity-slider');
        if (cameraSensitivitySlider) {
            createSlider(cameraSensitivitySlider, 10, getSetting('cameraSensitivity'), 'cameraSensitivity');
        }

        // Volume Slider
        const volumeSlider = document.getElementById('volume-slider');
        if (volumeSlider) {
            createSlider(volumeSlider, 10, getSetting('volume'), 'volume', true);
        }

        // Fullscreen Selector
        const fullscreenSelector = document.getElementById('fullscreen-selector');
        if (fullscreenSelector) {
            const options = JSON.parse(fullscreenSelector.dataset.options);
            createSelector(fullscreenSelector, options, getSetting('fullscreen') ? 'On' : 'Off', 'fullscreen');
        }
        
        // Graphics Mode Selector
        const graphicsModeSelector = document.getElementById('graphics-mode-selector');
        if (graphicsModeSelector) {
            const options = JSON.parse(graphicsModeSelector.dataset.options);
            createSelector(graphicsModeSelector, options, getSetting('graphicsMode'), 'graphicsMode');
        }

        // Graphics Quality Slider
        const graphicsQualitySlider = document.getElementById('graphics-quality-slider');
        if (graphicsQualitySlider) {
            createSlider(graphicsQualitySlider, 10, getSetting('graphicsQuality'), 'graphicsQuality');
        }

        // Tonemapping Selector
        const tonemappingSelector = document.getElementById('tonemapping-selector');
        if (tonemappingSelector) {
            const options = JSON.parse(tonemappingSelector.dataset.options);
            createSelector(tonemappingSelector, options, getSetting('tonemapping'), 'tonemapping');
        }
    }

    // Initial call to setup all controls based on loaded settings
    initializeSettingsControls();

    // --- Record Page Button Events ---
    const takeScreenshotButton = document.getElementById('take-screenshot-button');
    const recordVideoButton = document.getElementById('record-video-button');

    if (takeScreenshotButton) {
        takeScreenshotButton.addEventListener('click', () => {
            // This will be handled by the input handler, for now just close menu
            setSettingsVisible(false, true); // Instant close
        });
    }

    if (recordVideoButton) {
        recordVideoButton.addEventListener('click', () => {
            // This will be handled by the input handler, for now just close menu
            setSettingsVisible(false, true); // Instant close
        });
    }
}); 