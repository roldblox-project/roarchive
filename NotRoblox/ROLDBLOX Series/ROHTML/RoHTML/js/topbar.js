document.addEventListener('DOMContentLoaded', () => {
    // --- GLOBAL NAMESPACE ---
    window.ROHTML = window.ROHTML || {};

    // --- DOM ELEMENTS ---
    const topbar = document.getElementById('topbar');
    const playerInfo = document.getElementById('player-info');
    const usernameEl = document.getElementById('username');
    const accountAgeTextEl = document.getElementById('account-age-text');
    const chatButton = document.getElementById('chat-button');
    const backpackButton = document.getElementById('backpack-button');
    
    // --- STATE ---
    let isChatOpen = false;
    let isBackpackOpen = false;
    let chatStateBeforeMenu = false;
    let backpackStateBeforeMenu = false;
    let isMenuOpen = false;

    const chatIcon = 'content/textures/ui/Chat/Chat.png';
    const chatIconDown = 'content/textures/ui/Chat/ChatDown.png';
    const backpackIcon = 'content/textures/ui/Backpack/Backpack.png';
    const backpackIconDown = 'content/textures/ui/Backpack/BackpackDown.png';

    // --- INITIAL CONFIG ---
    // Apply Transparency from config
    const TOPBAR_BACKGROUND_COLOR = [31, 31, 31];
    topbar.style.backgroundColor = `rgba(${TOPBAR_BACKGROUND_COLOR.join(',')}, ${ROHTML_CONFIG.topbarTransparency})`;

    // Apply visibility settings from config
    if (ROHTML_CONFIG.showPlayerInfo) {
        usernameEl.textContent = ROHTML_CONFIG.username;
        if (ROHTML_CONFIG.accountAge < 13) {
            accountAgeTextEl.textContent = 'Account: <13';
        } else {
            accountAgeTextEl.textContent = 'Account: 13+';
        }
    } else {
        playerInfo.style.display = 'none';
    }

    if (!ROHTML_CONFIG.showChat) {
        chatButton.style.display = 'none';
    }

    if (!ROHTML_CONFIG.showBackpack) {
        backpackButton.style.display = 'none';
    }

    // --- CORE FUNCTIONS ---
    function setChatState(isOpen) {
        isChatOpen = isOpen;
        if (chatButton) {
            chatButton.classList.toggle('chat-button-on', isChatOpen);
        }
        // In a real app, you would show/hide the actual chat window here
        console.log(`Chat is now ${isChatOpen ? 'Open' : 'Closed'}`);
    }

    function setBackpackState(isOpen) {
        isBackpackOpen = isOpen;
        if (backpackButton) {
            backpackButton.classList.toggle('backpack-button-on', isBackpackOpen);
        }
        // In a real app, you would show/hide the actual backpack window here
        console.log(`Backpack is now ${isBackpackOpen ? 'Open' : 'Closed'}`);
    }
    
    // --- GLOBAL FUNCTIONS for menu interaction ---
    window.ROHTML.onMenuOpen = function() {
        isMenuOpen = true;
        chatStateBeforeMenu = isChatOpen;
        backpackStateBeforeMenu = isBackpackOpen;
        if (isChatOpen) setChatState(false);
        if (isBackpackOpen) setBackpackState(false);
    };
    
    window.ROHTML.onMenuClose = function() {
        isMenuOpen = false;
        // Restore chat state, but leave backpack closed per user request.
        if (chatStateBeforeMenu) setChatState(true);
        backpackStateBeforeMenu = false; 
    };

    // --- EVENT LISTENERS ---
    if (chatButton) {
        chatButton.addEventListener('click', () => {
            if (isMenuOpen) return;
            setChatState(!isChatOpen);
        });
    }

    if (backpackButton) {
        backpackButton.addEventListener('click', () => {
            if (isMenuOpen) return;
            setBackpackState(!isBackpackOpen);
        });
    }

    document.addEventListener('keydown', (event) => {
        if (isMenuOpen) return;

        // Prevent actions if typing in an input field
        if (document.activeElement.tagName.toLowerCase() === 'input' || document.activeElement.tagName.toLowerCase() === 'textarea') {
            return;
        }

        if (event.key === '/') {
            event.preventDefault();
            setChatState(true); // Always turn on, never off
        }

        if (event.key === '`') {
            event.preventDefault();
            setBackpackState(!isBackpackOpen); // Toggle
        }
    });
}); 