// ████████████████████████████████████████████████████████████████████████████████
// █─█──██▀▄─██▄─██─▄█─▄▄▄▄███▀▄─██▄─▀█▄─▄██▀▄─██▄─▄▄▀█▄─▄▄─█▄─▄▄▀█
// █─▄▀███─▀─███─██─██▄▄▄▄─███─▀─███─█▄▀─███─▀─███─▄─▄██─▄█▀██─▄─▄█
// ▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▀▀▄▄▀▄▄▀▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀
// 
// Key Management JavaScript
// ████████████████████████████████████████████████████████████████████████████████

let currentProperty = null;
let currentKeys = [];
let nearbyPlayers = [];

// ═══════════════════════════════════════════════════════════════════════════════
// SHOW MINI-UI KEY NOTIFICATION
// ═══════════════════════════════════════════════════════════════════════════════
function showKeyNotification(data) {
    const notification = document.getElementById('keyNotification');
    
    notification.innerHTML = `
        <div class="key-notification-content">
            <div class="key-notification-icon">
                <i class="fas fa-key"></i>
            </div>
            <div class="key-notification-details">
                <div class="key-notification-title">🔑 Temporärer Schlüssel erhalten</div>
                <div class="key-notification-property">${data.propertyName}</div>
                <div class="key-notification-info">
                    <div class="key-notification-row">
                        <span class="label">Vergeben von:</span>
                        <span class="value">${data.grantedBy}</span>
                    </div>
                    <div class="key-notification-row">
                        <span class="label">Gültig für:</span>
                        <span class="value highlight">${data.hours} Stunde${data.hours !== 1 ? 'n' : ''}</span>
                    </div>
                    <div class="key-notification-row">
                        <span class="label">Läuft ab:</span>
                        <span class="value">${formatDateTime(data.expiresAt)}</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="key-notification-progress">
            <div class="key-notification-progress-bar"></div>
        </div>
    `;
    
    notification.classList.add('show');
    
    // Animate progress bar
    const progressBar = notification.querySelector('.key-notification-progress-bar');
    progressBar.style.animation = 'progressShrink 5s linear forwards';
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        notification.classList.remove('show');
    }, 5000);
}

// ═══════════════════════════════════════════════════════════════════════════════
// OPEN KEY MANAGEMENT UI
// ═══════════════════════════════════════════════════════════════════════════════
function openKeyManagement(data) {
    console.log('[Key Manager] openKeyManagement called with data:', data);
    
    currentProperty = data.property;
    currentKeys = data.keys;
    nearbyPlayers = data.nearbyPlayers;
    
    const keyManagementUI = document.getElementById('keyManagementUI');
    const propertyName = document.getElementById('keyMgmtPropertyName');
    const propertyType = document.getElementById('keyMgmtPropertyType');
    
    if (!keyManagementUI) {
        console.error('[Key Manager] ERROR: keyManagementUI element not found!');
        return;
    }
    
    if (!propertyName || !propertyType) {
        console.error('[Key Manager] ERROR: Property name or type element not found!');
        return;
    }
    
    console.log('[Key Manager] Setting property name:', currentProperty.name);
    console.log('[Key Manager] Setting property type:', currentProperty.type);
    
    propertyName.textContent = currentProperty.name;
    propertyType.textContent = getPropertyTypeLabel(currentProperty.type);
    
    console.log('[Key Manager] Rendering keys...');
    renderKeys();
    
    console.log('[Key Manager] Rendering nearby players...');
    renderNearbyPlayers();
    
    console.log('[Key Manager] Showing UI...');
    keyManagementUI.style.display = 'flex';
    
    console.log('[Key Manager] UI should now be visible!');
}

// ═══════════════════════════════════════════════════════════════════════════════
// RENDER KEYS LIST
// ═══════════════════════════════════════════════════════════════════════════════
function renderKeys() {
    const keysList = document.getElementById('keysList');
    
    console.log('[Key Manager] renderKeys() - Total keys:', currentKeys ? currentKeys.length : 0);
    
    if (!currentKeys || currentKeys.length === 0) {
        keysList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-key"></i>
                <p>Keine Schlüssel vergeben</p>
            </div>
        `;
        return;
    }
    
    keysList.innerHTML = currentKeys.map((key, index) => {
        const isExpiring = key.keyType === 'temporary' && key.secondsRemaining && key.secondsRemaining < 3600; // Less than 1 hour
        const timeClass = isExpiring ? 'expiring' : '';
        
        console.log(`[Key Manager] Key #${index}:`, {
            holder: key.holderName,
            citizenId: key.citizenId,
            keyType: key.keyType,
            isOwner: key.isOwner,
            showButton: !key.isOwner,
            rawKeyData: key
        });
        
        return `
            <div class="key-item ${key.isOwner ? 'owner-key' : ''} ${timeClass}">
                <div class="key-item-header">
                    <div class="key-holder-info">
                        <i class="fas ${key.isOwner ? 'fa-crown' : 'fa-user'}"></i>
                        <span class="key-holder-name">${key.holderName}</span>
                        ${key.isOwner ? '<span class="owner-badge">Eigentümer</span>' : ''}
                    </div>
                    <div class="key-type-badge ${key.keyType}">
                        ${key.keyType === 'permanent' ? '∞ Permanent' : '⏱️ Temporär'}
                    </div>
                </div>
                
                ${key.keyType === 'temporary' && key.secondsRemaining ? `
                    <div class="key-expiry-info">
                        <div class="expiry-label">Läuft ab in:</div>
                        <div class="expiry-time">${formatTimeRemaining(key.secondsRemaining)}</div>
                        <div class="expiry-progress">
                            <div class="expiry-progress-bar" style="width: ${calculateProgressPercent(key)}%"></div>
                        </div>
                    </div>
                ` : ''}
                
                <div class="key-item-footer">
                    <div class="key-granted-info">
                        Vergeben: ${formatDateTime(key.grantedAt)}
                    </div>
                    ${(() => {
                        const shouldShowButton = !key.isOwner;
                        console.log(`[Key Manager] Button visibility for ${key.holderName}: isOwner=${key.isOwner}, showButton=${shouldShowButton}`);
                        return shouldShowButton ? `
                            <button class="btn-revoke" onclick="revokeKey('${key.citizenId}')">
                                <i class="fas fa-times-circle"></i> Entziehen
                            </button>
                        ` : '';
                    })()}
                </div>
            </div>
        `;
    }).join('');
    
    console.log('[Key Manager] renderKeys() complete - HTML updated');
}

// ═══════════════════════════════════════════════════════════════════════════════
// RENDER NEARBY PLAYERS
// ═══════════════════════════════════════════════════════════════════════════════
function renderNearbyPlayers() {
    const playerSelect = document.getElementById('grantKeyPlayer');
    
    if (!nearbyPlayers || nearbyPlayers.length === 0) {
        playerSelect.innerHTML = '<option value="">Keine Spieler in der Nähe</option>';
        playerSelect.disabled = true;
        return;
    }
    
    playerSelect.disabled = false;
    playerSelect.innerHTML = '<option value="">Spieler auswählen...</option>' + 
        nearbyPlayers.map(player => 
            `<option value="${player.id}">${player.name} (${player.distance}m)</option>`
        ).join('');
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRANT KEY ACTIONS
// ═══════════════════════════════════════════════════════════════════════════════
function grantTemporaryKey() {
    const playerId = document.getElementById('grantKeyPlayer').value;
    const hours = parseInt(document.getElementById('keyDuration').value);
    
    if (!playerId) {
        return;
    }
    
    if (!hours || hours < 1 || hours > 168) {
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/grantTemporaryKey`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            targetId: parseInt(playerId),
            hours: hours
        })
    });
    
    // Reset form
    document.getElementById('grantKeyPlayer').value = '';
    document.getElementById('keyDuration').value = '24';
}

function grantPermanentKey() {
    const playerId = document.getElementById('grantKeyPlayer').value;
    
    if (!playerId) {
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/grantPermanentKey`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            targetId: parseInt(playerId)
        })
    });
    
    // Reset form
    document.getElementById('grantKeyPlayer').value = '';
}

function revokeKey(citizenId) {
    console.log('[Key Manager] Revoking key for citizen:', citizenId);
    
    fetch(`https://${GetParentResourceName()}/revokeKey`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            citizenId: citizenId
        })
    })
    .then(resp => resp.json())
    .then(resp => {
        console.log('[Key Manager] Key revocation response:', resp);
    })
    .catch(err => {
        console.error('[Key Manager] Error revoking key:', err);
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLOSE KEY MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════
function closeKeyManagement() {
    console.log('[Haus-Manager NUI] closeKeyManagement() called');
    const keyManagementUI = document.getElementById('keyManagementUI');
    if (keyManagementUI) {
        keyManagementUI.style.display = 'none';
        console.log('[Haus-Manager NUI] Key Management UI closed');
    } else {
        console.error('[Haus-Manager NUI] Key Management UI element not found');
    }
    
    console.log('[Haus-Manager NUI] Sending closeKeyManagement fetch to client');
    fetch(`https://${GetParentResourceName()}/closeKeyManagement`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(() => {
        console.log('[Haus-Manager NUI] closeKeyManagement fetch successful');
    }).catch((error) => {
        console.error('[Haus-Manager NUI] closeKeyManagement fetch error:', error);
    });
}

// Make closeKeyManagement globally available for onclick handlers
window.closeKeyManagement = closeKeyManagement;
console.log('[Haus-Manager NUI] closeKeyManagement function exported to window');

// ═══════════════════════════════════════════════════════════════════════════════
// REFRESH KEYS (called from client after server update)
// ═══════════════════════════════════════════════════════════════════════════════
function refreshKeys(data) {
    currentKeys = data.keys;
    renderKeys();
}

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════
function formatTimeRemaining(seconds) {
    if (!seconds || seconds < 0) return 'Abgelaufen';
    
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
}

function formatDateTime(dateString) {
    if (!dateString) return 'N/A';
    
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = date - now;
    const diffHours = Math.floor(diffMs / 3600000);
    
    // Format as DD.MM.YYYY HH:MM
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    
    return `${day}.${month}.${year} ${hour}:${minute}`;
}

function calculateProgressPercent(key) {
    if (key.keyType !== 'temporary' || !key.secondsRemaining) return 100;
    
    // Assuming max duration is 7 days (604800 seconds)
    const maxSeconds = 604800;
    return Math.max(0, Math.min(100, (key.secondsRemaining / maxSeconds) * 100));
}

function getPropertyTypeLabel(type) {
    const labels = {
        'apartment': '🏢 Wohnung',
        'house': '🏠 Haus',
        'office': '🏢 Büro'
    };
    return labels[type] || type;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE HANDLER
// ═══════════════════════════════════════════════════════════════════════════════
window.addEventListener('message', (event) => {
    const data = event.data;
    
    console.log('[Key Manager] Received message:', data);
    
    switch (data.action) {
        case 'showKeyNotification':
            console.log('[Key Manager] Showing key notification');
            showKeyNotification(data);
            break;
        case 'openKeyManagement':
            console.log('[Key Manager] Opening key management UI');
            openKeyManagement(data);
            break;
        case 'refreshKeys':
            console.log('[Key Manager] Refreshing keys');
            refreshKeys(data);
            break;
        default:
            console.log('[Key Manager] Unknown action:', data.action);
    }
});

// ESC key to close
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        const keyMgmtUI = document.getElementById('keyManagementUI');
        if (keyMgmtUI && keyMgmtUI.style.display !== 'none') {
            closeKeyManagement();
        }
    }
});
