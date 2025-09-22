// ... existing code ...
const leaveGamePage = document.getElementById("leave-game-page");
const leaveConfirmButton = document.getElementById("leave-confirm-button");
const leaveCancelButton = document.getElementById("leave-cancel-button");

const resetCharacterPage = document.getElementById("reset-character-page");
const resetConfirmButton = document.getElementById("reset-confirm-button");
const resetCancelButton = document.getElementById("reset-cancel-button");

if (leaveConfirmButton) {
  leaveConfirmButton.addEventListener("click", () => {
    // Send keys through InputForwarder
    if (window.chrome && window.chrome.webview) {
      // Send macro message for leave game
      window.chrome.webview.postMessage("macros;leaveGame");
    }
    hideAllConfirmationPages();
  });
}

if (leaveCancelButton) {
  leaveCancelButton.addEventListener("click", () => {
    hideAllConfirmationPages();
  });
}

if (resetConfirmButton) {
  resetConfirmButton.addEventListener("click", () => {
    // Send keys through InputForwarder
    if (window.chrome && window.chrome.webview) {
      // Send macro message for reset character
      window.chrome.webview.postMessage("macros;resetCharacter");
    }
    hideAllConfirmationPages();
  });
}

if (resetCancelButton) {
  resetCancelButton.addEventListener("click", () => {
    hideAllConfirmationPages();
  });
}
