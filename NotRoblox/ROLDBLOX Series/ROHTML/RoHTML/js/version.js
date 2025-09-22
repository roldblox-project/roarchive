document.addEventListener('DOMContentLoaded', () => {
    // Populate the version labels from the data file
    const serverVersionLabel = document.getElementById('server-version-label');
    const environmentLabel = document.getElementById('environment-label');
    const clientVersionLabel = document.getElementById('client-version-label');

    if (typeof ROHTML_VERSION_DATA !== 'undefined') {
        serverVersionLabel.textContent = ROHTML_VERSION_DATA.server;
        environmentLabel.textContent = ROHTML_VERSION_DATA.environment;
        clientVersionLabel.textContent = ROHTML_VERSION_DATA.client;
    }

    // Handle showing/hiding the container
    const versionContainer = document.getElementById('version-container');
    const tabs = document.querySelectorAll('.settings-tab');
    const settingsShield = document.getElementById('settings-clipping-shield');

    function checkVersionVisibility() {
        const helpTab = document.querySelector('.settings-tab[data-page="help"]');
        const isSettingsVisible = settingsShield.classList.contains('settings-visible');

        if (isSettingsVisible && helpTab && helpTab.classList.contains('active')) {
            versionContainer.style.display = 'flex'; // Use flex to match CSS
        } else {
            versionContainer.style.display = 'none';
        }
    }

    // Check visibility whenever a tab is clicked
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            // Use a timeout to allow the 'active' class to be updated by settings.js first
            setTimeout(checkVersionVisibility, 0);
        });
    });

    // Also check when the menu is opened or closed
    // We can use a MutationObserver to watch for class changes on the shield
    const observer = new MutationObserver((mutationsList) => {
        for (const mutation of mutationsList) {
            if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                checkVersionVisibility();
            }
        }
    });

    observer.observe(settingsShield, { attributes: true });

    // Initial check in case the page loads with the menu open
    checkVersionVisibility();
}); 