// js/loading.js

document.addEventListener('DOMContentLoaded', () => {
    const loadingScreen = document.getElementById('loading-screen');
    const loadingText = document.getElementById('loading-text');
    const placeLabel = document.getElementById('place-label');
    const creatorLabel = document.getElementById('creator-label');

    // --- Configuration ---
    const placeName = "RoHTML"; // Placeholder
    const creatorName = "NotRoblox"; // Placeholder
    const minDuration = 5500; // 2 seconds
    const maxDuration = 7000; // 6 seconds
    const loadingDuration = Math.floor(Math.random() * (maxDuration - minDuration + 1)) + minDuration;
    const dotAnimationSpeed = 200; // ms between dot changes

    // --- Set initial text ---
    placeLabel.textContent = placeName;
    creatorLabel.textContent = "By " + creatorName;

    // --- Animate "Loading..." text ---
    let dots = "";
    const dotInterval = setInterval(() => {
        dots += ".";
        if (dots.length > 3) {
            dots = "";
        }
        loadingText.textContent = "Loading" + dots;
    }, dotAnimationSpeed);

    // --- Function to hide the loading screen ---
    const hideLoadingScreen = () => {
        clearInterval(dotInterval); // Stop the dot animation
        loadingScreen.classList.add('loading-screen-hidden');

        // Optional: remove from DOM after transition ends
        loadingScreen.addEventListener('transitionend', () => {
            // loadingScreen.remove();
        });
    };

    // --- Decide when to hide based on config ---
    if (window.ROHTML_CONFIG && window.ROHTML_CONFIG.loadingScreen && window.ROHTML_CONFIG.loadingScreen.startFadeImmediately) {
        // If the config option is true, hide immediately.
        hideLoadingScreen();
    } else {
        // Otherwise, use the original timer.
        setTimeout(hideLoadingScreen, loadingDuration);
    }
}); 