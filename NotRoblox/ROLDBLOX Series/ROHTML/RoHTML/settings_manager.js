const SETTINGS_KEY = 'ROHTML_PlayerSettings';

// Default settings structure based on the UI
const defaultSettings = {
    shiftLockSwitch: true,
    cameraMode: 'Default (Classic)',
    movementMode: 'Default (Keyboard)',
    cameraSensitivity: 5,
    volume: 8,
    fullscreen: false,
    graphicsMode: 'Automatic',
    graphicsQuality: 6,
    tonemapping: 'Off'
};

let currentSettings = {};

function saveSettings() {
    console.log("Attempting to save settings...");
    // For now, we'll log it to the console.
    console.log("Updated settings:", JSON.stringify(currentSettings, null, 2));
    try {
        localStorage.setItem(SETTINGS_KEY, JSON.stringify(currentSettings));
    } catch (e) {
        console.error("Failed to save settings to localStorage:", e);
    }
}

async function loadSettings() {
    try {
        // We primarily use localStorage for simplicity in this web-only context
        const savedSettings = localStorage.getItem(SETTINGS_KEY);
        if (savedSettings) {
            currentSettings = JSON.parse(savedSettings);
            // Ensure all keys from default settings are present
            for (const key in defaultSettings) {
                if (currentSettings[key] === undefined) {
                    currentSettings[key] = defaultSettings[key];
                }
            }
        } else {
            currentSettings = { ...defaultSettings };
        }
    } catch (e) {
        console.error("Failed to load settings, using defaults:", e);
        currentSettings = { ...defaultSettings };
    }
    applyAllSettings();
}

function updateSetting(key, value) {
    if (currentSettings[key] !== undefined) {
        currentSettings[key] = value;
        saveSettings();
        // Also apply the specific setting change in real-time
        if (key === 'tonemapping') {
            applyTonemappingEffect(value);
        }
    }
}

function getSetting(key) {
    return currentSettings[key];
}

function applyAllSettings() {
    // Update Sliders
    const cameraSensitivitySlider = document.querySelector('#camera-sensitivity-slider');
    if (cameraSensitivitySlider && cameraSensitivitySlider.update) {
        cameraSensitivitySlider.update(currentSettings.cameraSensitivity);
    }
    const volumeSlider = document.querySelector('#volume-slider');
    if (volumeSlider && volumeSlider.update) {
        volumeSlider.update(currentSettings.volume);
    }
    const graphicsQualitySlider = document.querySelector('#graphics-quality-slider');
    if (graphicsQualitySlider && graphicsQualitySlider.update) {
        graphicsQualitySlider.update(currentSettings.graphicsQuality);
    }

    // Update Selectors
    const shiftLockSelector = document.querySelector('#shift-lock-selector');
    if (shiftLockSelector && shiftLockSelector.update) {
        shiftLockSelector.update(currentSettings.shiftLockSwitch ? 'On' : 'Off');
    }
    const cameraModeSelector = document.querySelector('#camera-mode-selector');
    if (cameraModeSelector && cameraModeSelector.update) {
        cameraModeSelector.update(currentSettings.cameraMode);
    }
    const movementModeSelector = document.querySelector('#movement-mode-selector');
    if (movementModeSelector && movementModeSelector.update) {
        movementModeSelector.update(currentSettings.movementMode);
    }
    const graphicsModeSelector = document.querySelector('#graphics-mode-selector');
    if (graphicsModeSelector && graphicsModeSelector.update) {
        graphicsModeSelector.update(currentSettings.graphicsMode);
    }
    const fullscreenSelector = document.querySelector('#fullscreen-selector');
    if (fullscreenSelector && fullscreenSelector.update) {
        fullscreenSelector.update(currentSettings.fullscreen ? 'On' : 'Off');
    }
    const tonemappingSelector = document.querySelector('#tonemapping-selector');
    if (tonemappingSelector && tonemappingSelector.update) {
        tonemappingSelector.update(currentSettings.tonemapping);
    }
    // Apply the tonemapping effect on initial load
    applyTonemappingEffect(currentSettings.tonemapping);
}

// Initial load
document.addEventListener('DOMContentLoaded', () => {
    loadSettings();
}); 