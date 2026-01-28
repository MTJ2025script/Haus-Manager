// ═══════════════════════════════════════════════════════════════════════════════
// Temporary Key HUD System
// Displays active temporary keys with live countdown
// ═══════════════════════════════════════════════════════════════════════════════

let keyHUDData = [];
let keyHUDUpdateInterval = null;

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATE KEY HUD
// ═══════════════════════════════════════════════════════════════════════════════
function updateKeyHUD(keys, currentTime) {
    keyHUDData = keys || [];
    
    const hudContainer = document.getElementById('keyHUD');
    if (!hudContainer) {
        console.error('[Key HUD] Container #keyHUD not found!');
        return;
    }
    
    if (keyHUDData.length === 0) {
        // No temporary keys - clear and hide HUD
        hudContainer.innerHTML = '';
        if (keyHUDUpdateInterval) {
            clearInterval(keyHUDUpdateInterval);
            keyHUDUpdateInterval = null;
        }
        return;
    }
    
    // Update existing cards or create new ones (prevents flickering)
    const existingCards = hudContainer.querySelectorAll('.key-hud-card');
    const existingIds = Array.from(existingCards).map(card => card.dataset.propertyId);
    const newIds = keyHUDData.map(key => String(key.propertyId));
    
    // Remove cards for keys that no longer exist
    existingCards.forEach(card => {
        if (!newIds.includes(card.dataset.propertyId)) {
            card.classList.add('fade-out');
            setTimeout(() => card.remove(), 300);
        }
    });
    
    // Add or update cards
    keyHUDData.forEach((key, index) => {
        const keyId = String(key.propertyId);
        let card = hudContainer.querySelector(`[data-property-id="${keyId}"]`);
        
        if (!card) {
            // Create new card
            card = createKeyHUDCard(key, currentTime);
            hudContainer.appendChild(card);
        } else {
            // Update existing card
            card.dataset.expiresAt = key.expiresAt;
            const timeData = calculateTimeRemaining(key.expiresAt, currentTime);
            
            const timeElement = card.querySelector('.key-hud-time');
            if (timeElement) {
                timeElement.textContent = timeData.displayTime;
                timeElement.className = `key-hud-time ${timeData.colorClass}`;
            }
            
            const progressBar = card.querySelector('.key-hud-progress-bar');
            if (progressBar) {
                progressBar.style.width = timeData.progress + '%';
                progressBar.className = `key-hud-progress-bar ${timeData.progressClass}`;
            }
        }
    });
    
    // Start update interval if not already running
    if (!keyHUDUpdateInterval) {
        keyHUDUpdateInterval = setInterval(() => {
            updateKeyHUDTimes();
        }, 1000); // Update every second
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE KEY HUD CARD
// ═══════════════════════════════════════════════════════════════════════════════
function createKeyHUDCard(key, currentTime) {
    const card = document.createElement('div');
    card.className = 'key-hud-card';
    card.dataset.propertyId = key.propertyId;
    card.dataset.expiresAt = key.expiresAt;
    
    const timeData = calculateTimeRemaining(key.expiresAt, currentTime);
    
    card.innerHTML = `
        <div class="key-hud-header">
            <i class="fas fa-key key-hud-icon"></i>
            <div class="key-hud-title">${escapeHtml(key.propertyName)}</div>
        </div>
        <div class="key-hud-timer">
            <span class="key-hud-time ${timeData.colorClass}">${timeData.displayTime}</span>
        </div>
        <div class="key-hud-progress">
            <div class="key-hud-progress-bar ${timeData.progressClass}" style="width: ${timeData.progress}%"></div>
        </div>
    `;
    
    return card;
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATE KEY HUD TIMES (Called every second)
// ═══════════════════════════════════════════════════════════════════════════════
function updateKeyHUDTimes() {
    const currentTime = Date.now();
    const hudContainer = document.getElementById('keyHUD');
    if (!hudContainer) return;
    
    const cards = hudContainer.querySelectorAll('.key-hud-card');
    
    cards.forEach(card => {
        const expiresAt = parseInt(card.dataset.expiresAt);
        const timeData = calculateTimeRemaining(expiresAt, currentTime);
        
        // Update time display
        const timeElement = card.querySelector('.key-hud-time');
        if (timeElement) {
            timeElement.textContent = timeData.displayTime;
            timeElement.className = `key-hud-time ${timeData.colorClass}`;
        }
        
        // Update progress bar
        const progressBar = card.querySelector('.key-hud-progress-bar');
        if (progressBar) {
            progressBar.style.width = timeData.progress + '%';
            progressBar.className = `key-hud-progress-bar ${timeData.progressClass}`;
        }
        
        // Remove card if expired
        if (timeData.totalSeconds <= 0) {
            card.classList.add('fade-out');
            setTimeout(() => card.remove(), 300);
        }
    });
    
    // Stop interval if no cards left
    if (cards.length === 0 && keyHUDUpdateInterval) {
        clearInterval(keyHUDUpdateInterval);
        keyHUDUpdateInterval = null;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALCULATE TIME REMAINING
// ═══════════════════════════════════════════════════════════════════════════════
function calculateTimeRemaining(expiresAt, currentTime) {
    const totalMilliseconds = expiresAt - currentTime;
    const totalSeconds = Math.max(0, Math.floor(totalMilliseconds / 1000));
    
    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    
    // Format display time
    let displayTime;
    if (days > 0) {
        displayTime = `${days}d ${hours}h ${minutes}m`;
    } else if (hours > 0) {
        displayTime = `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
        displayTime = `${minutes}m ${seconds}s`;
    } else {
        displayTime = `${seconds}s`;
    }
    
    // Determine color and progress classes based on time remaining
    const hoursRemaining = totalSeconds / 3600;
    let colorClass, progressClass;
    
    if (hoursRemaining > 6) {
        colorClass = 'time-safe';
        progressClass = 'progress-safe';
    } else if (hoursRemaining > 1) {
        colorClass = 'time-warning';
        progressClass = 'progress-warning';
    } else {
        colorClass = 'time-critical';
        progressClass = 'progress-critical';
    }
    
    // Calculate progress percentage (assuming max 24 hours for visual reference)
    const maxHours = 24;
    const progress = Math.min(100, (hoursRemaining / maxHours) * 100);
    
    return {
        totalSeconds,
        displayTime,
        colorClass,
        progressClass,
        progress: Math.max(0, progress)
    };
}

// ═══════════════════════════════════════════════════════════════════════════════
// ESCAPE HTML
// ═══════════════════════════════════════════════════════════════════════════════
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// ═══════════════════════════════════════════════════════════════════════════════
// HANDLE NUI MESSAGES
// ═══════════════════════════════════════════════════════════════════════════════
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'updateKeyHUD') {
        updateKeyHUD(data.keys, data.currentTime);
    }
});
