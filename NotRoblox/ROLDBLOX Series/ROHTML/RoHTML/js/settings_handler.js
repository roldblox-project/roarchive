// js/settings_handler.js

function sendAhkMessage(message) {
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage(message);
  } else {
    console.warn("WebView environment not found. Message not sent:", message);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  // --- Generic Setting Change Handler ---
  function handleSettingChange(event) {
    const settingRow = event.target.closest(".setting-row");
    if (!settingRow) return;

    const settingName = settingRow.dataset.setting;
    let value;

    // Check the type of control to get its value
    const selector = settingRow.querySelector(".selector-control");
    const slider = settingRow.querySelector(".slider-control");

    if (selector) {
      // For our custom selector, the value is in its active option
      const activeOption = selector.querySelector(".selector-option.active");
      if (activeOption) {
        value = activeOption.textContent;
      }
    } else if (slider) {
      // For our custom slider, the value is in a data attribute or child element
      // This needs to be implemented based on the slider's final structure
      value = slider.dataset.value; // Assuming value is stored in data-value
    }

    if (settingName && value !== undefined) {
      const message = {
        type: "settingChange",
        setting: settingName,
        value: value,
      };
      sendAhkMessage(message);

      // Special case for fullscreen
      if (settingName === "fullscreen") {
        const fullscreenMessage = {
          type: "fullscreen",
          value: value,
        };
        sendAhkMessage(fullscreenMessage);
      }
    }
  }

  // --- Developer Console Button ---
  const devConsoleButton = document.getElementById("developer-console-button");
  if (devConsoleButton) {
    devConsoleButton.addEventListener("click", () => {
      sendAhkMessage({ type: "devConsole" });
    });
  }

  // --- Attach listeners to all setting rows ---
  // We use a single listener on a parent to handle all changes efficiently.
  const settingsContainer = document.getElementById("page-settings");
  if (settingsContainer) {
    // We listen for a custom 'change' event that our controls will bubble up.
    // A simple 'click' might be sufficient if the controls update visually and then we grab the value.
    settingsContainer.addEventListener("click", (event) => {
      // Let's check if a selector option or slider handle was clicked
      if (
        event.target.classList.contains("selector-option") ||
        event.target.closest(".slider-handle")
      ) {
        // We need to wait a moment for the control's state to update
        setTimeout(() => handleSettingChange(event), 50);
      }
    });
  }

  // --- Bottom Bar Buttons ---
  const resetCharButton = document.getElementById("reset-char-button");
  const leaveGameButton = document.getElementById("leave-game-button");

  if (resetCharButton) {
    resetCharButton.addEventListener("click", () => {
      // Show reset character confirmation dialog
      const resetCharacterPage = document.getElementById(
        "reset-character-page"
      );
      if (resetCharacterPage) {
        resetCharacterPage.classList.remove("hidden");
      }
    });
  }

  if (leaveGameButton) {
    leaveGameButton.addEventListener("click", () => {
      // Show leave game confirmation dialog
      const leaveGamePage = document.getElementById("leave-game-page");
      if (leaveGamePage) {
        leaveGamePage.classList.remove("hidden");
      }
    });
  }
});
