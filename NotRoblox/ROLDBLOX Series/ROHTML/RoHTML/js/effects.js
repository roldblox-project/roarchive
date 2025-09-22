// This script manages the visual effect layer for tonemapping.

// This function will be called by the settings manager whenever the tonemapping setting changes.
function applyTonemappingEffect(value) {
    const effectLayer = document.getElementById('effect-layer');
    if (!effectLayer) return;

    let filters = [];

    switch (value) {
        case 'Default > Legacy':
            // Total Brightness = 95% (base) * 1.25 (tint) = 118.75%
            filters.push('brightness(119%)');
            filters.push('contrast(75%)');
            filters.push('saturate(107%)');
            break;

        case 'Retro > Legacy':
            filters.push('brightness(103%)');
            filters.push('contrast(95%)');
            filters.push('saturate(90%)');
            break;
            
        case 'Off':
        default:
            // No filters
            break;
    }

    effectLayer.style.backdropFilter = filters.join(' ');
} 