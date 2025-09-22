// This script handles the optional background image.

document.addEventListener('DOMContentLoaded', () => {
    // This function checks if the script is running inside a WebView2 environment
    const isInsideWebView = () => {
        return !!(window.chrome && window.chrome.webview);
    };

    // Only show the background image if we are NOT inside the WebView (i.e., in a normal browser for testing)
    if (!isInsideWebView()) {
        let pageBackground = document.getElementById('page-background');
        if (!pageBackground) {
            pageBackground = document.createElement('div');
            pageBackground.id = 'page-background';
            document.body.insertBefore(pageBackground, document.body.firstChild);
        }
        pageBackground.style.display = 'block'; // Make it visible
    }
}); 