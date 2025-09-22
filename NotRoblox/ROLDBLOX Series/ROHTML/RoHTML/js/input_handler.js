// This function will be called by the AutoHotkey script
let lastHoveredElement = []; // To track hover state
// const cursor = document.getElementById('debug-cursor'); // This is now declared in index.html

// Load cursor images to get their natural dimensions
const farCursor = new Image();

function handleAhkMouse(eventData) {
    if (!cursor) return;

    // Update the position of the custom cursor
    if (eventData.type === 'mousemove') {
        cursor.style.left = eventData.clientX + 'px';
        cursor.style.top = eventData.clientY + 'px';
    }

    // Find the element at the cursor's position
    const element = document.elementFromPoint(eventData.clientX, eventData.clientY);
    if (element) {
        // Create a new MouseEvent
        const event = new MouseEvent(eventData.type, {
            bubbles: true,
            cancelable: true,
            view: window,
            clientX: eventData.clientX,
            clientY: eventData.clientY,
            button: eventData.button,
        });
        // Dispatch the event to the element
        element.dispatchEvent(event);
    }
}

function handleAhkKey(eventData) {
    console.log('Key event:', eventData);
    // Future implementation: dispatch keyboard events
    const event = new KeyboardEvent(eventData.type, {
        key: eventData.key,
        bubbles: true,
        cancelable: true,
    });
    document.dispatchEvent(event);
} 