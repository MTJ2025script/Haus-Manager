// Main NUI JavaScript
let currentConfig = null;
let currentProperties = [];

// Add debug logging
console.log('[Haus-Manager] NUI Script loaded');

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('[Haus-Manager] Received message:', data);
    
    switch(data.action) {
        case 'openAdminUI':
            console.log('[Haus-Manager] Opening Admin UI');
            currentConfig = data.config;
            currentProperties = data.properties;
            openAdminUI();
            break;
        case 'openGarageUI':
            console.log('[Haus-Manager] Opening Garage UI');
            currentConfig = data.config;
            currentProperties = data.properties;
            openGarageUI();
            break;
        case 'openPropertyUI':
            console.log('[Haus-Manager] Opening Property UI');
            currentConfig = data.config;
            openPropertyUI(data.property);
            break;
        default:
            console.warn('[Haus-Manager] Unknown action:', data.action);
    }
});

// Close UI function
function closeUI() {
    console.log('[Haus-Manager NUI] closeUI() called');
    
    const adminUI = document.getElementById('adminUI');
    const garageUI = document.getElementById('garageUI');
    const propertyUI = document.getElementById('propertyUI');
    
    if (adminUI) {
        adminUI.style.display = 'none';
        console.log('[Haus-Manager NUI] Admin UI closed');
    }
    if (garageUI) {
        garageUI.style.display = 'none';
        console.log('[Haus-Manager NUI] Garage UI closed');
    }
    if (propertyUI) {
        propertyUI.style.display = 'none';
        console.log('[Haus-Manager NUI] Property UI closed');
    }
    
    console.log('[Haus-Manager NUI] Sending closeUI fetch to client');
    fetch('https://haus-manager/closeUI', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(() => {
        console.log('[Haus-Manager NUI] closeUI fetch successful');
    }).catch((error) => {
        console.error('[Haus-Manager NUI] closeUI fetch error:', error);
    });
}

// Make closeUI globally available for onclick handlers
window.closeUI = closeUI;
console.log('[Haus-Manager NUI] closeUI function exported to window');

// ESC key to close
document.addEventListener('keyup', function(e) {
    if (e.key === "Escape") {
        closeUI();
    }
});

// Utility function to format currency
function formatCurrency(amount) {
    if (amount === null || amount === undefined || isNaN(amount)) {
        return '$0';
    }
    return '$' + Number(amount).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Utility function to format property type
function formatPropertyType(type) {
    const types = {
        'apartment': 'Wohnung',
        'house': 'Haus',
        'office': 'Büro'
    };
    return types[type] || type;
}

// Show toast notification
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = 'toast ' + type;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(function() {
        toast.style.opacity = '0';
        setTimeout(function() {
            toast.remove();
        }, 300);
    }, 3000);
}

// Custom Confirmation Dialog (replaces window.confirm)
let confirmCallback = null;

function showConfirmDialog(message, onConfirm, onCancel) {
    const dialog = document.getElementById('confirmDialog');
    const messageEl = document.getElementById('confirmMessage');
    
    if (dialog && messageEl) {
        messageEl.textContent = message;
        dialog.style.display = 'flex';
        
        // Store callbacks
        confirmCallback = {
            confirm: onConfirm || (() => {}),
            cancel: onCancel || (() => {})
        };
    }
}

function confirmDialogYes() {
    const dialog = document.getElementById('confirmDialog');
    if (dialog) {
        dialog.style.display = 'none';
    }
    if (confirmCallback && confirmCallback.confirm) {
        confirmCallback.confirm();
    }
    confirmCallback = null;
}

function confirmDialogNo() {
    const dialog = document.getElementById('confirmDialog');
    if (dialog) {
        dialog.style.display = 'none';
    }
    if (confirmCallback && confirmCallback.cancel) {
        confirmCallback.cancel();
    }
    confirmCallback = null;
}
