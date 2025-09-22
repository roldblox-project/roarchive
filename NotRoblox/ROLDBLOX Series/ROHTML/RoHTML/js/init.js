// This script processes the nested ROHTML_CONFIG object from config.js
// and creates the flat, backward-compatible properties that other scripts expect.

(function initializeConfig() {
    const newConfig = window.ROHTML_CONFIG;
    if (!newConfig) {
        console.error("ROHTML_CONFIG not found. Make sure config.js is loaded first.");
        return;
    }

    // Create a flat structure for backward compatibility
    window.ROHTML_CONFIG = {
        // Topbar compatibility
        topbarTransparency: newConfig.topbar.transparency,
        showPlayerInfo: newConfig.topbar.features.showPlayerInfo,
        showChat: newConfig.topbar.features.showChat,
        showBackpack: newConfig.topbar.features.showBackpack,

        // Player compatibility
        username: newConfig.player.username,
        accountAge: newConfig.player.accountAge,

        // Testing compatibility
        players: newConfig.testing.dummyPlayers,
        localPlayer: newConfig.testing.localPlayerName,

        // Loading Screen compatibility
        loadingScreen: newConfig.loadingScreen,

        // Store the full new config structure as well for future use
        _full: newConfig
    };
})(); 