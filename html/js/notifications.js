// ████████████████████████████████████████████████████████████████████████████████
// █─█──██▀▄─██▄─██─▄█─▄▄▄▄███▀▄─██▄─▀█▄─▄██▀▄─██▄─▄▄▀█▄─▄▄─█▄─▄▄▀█
// █─▄▀███─▀─███─██─██▄▄▄▄─███─▀─███─█▄▀─███─▀─███─▄─▄██─▄█▀██─▄─▄█
// ▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▀▀▄▄▀▄▄▀▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀
// 
// Custom Notification System - Schön, Zentral, Mit Icons
// ████████████████████████████████████████████████████████████████████████████████

// Icon mapping für verschiedene Notification-Typen
const NOTIFICATION_ICONS = {
    'success': 'fa-circle-check',
    'error': 'fa-circle-xmark',
    'info': 'fa-circle-info',
    'warning': 'fa-triangle-exclamation'
};

const NOTIFICATION_TITLES = {
    'success': 'Erfolg',
    'error': 'Fehler',
    'info': 'Information',
    'warning': 'Warnung'
};

// Show notification
function showNotification(message, type = 'info', duration = 5000) {
    console.log('[Haus-Manager Notify]', type, message);
    
    // Get or create notification container
    let container = document.getElementById('notification-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'notification-container';
        document.body.appendChild(container);
    }
    
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const icon = NOTIFICATION_ICONS[type] || 'fa-circle-info';
    const title = NOTIFICATION_TITLES[type] || 'Benachrichtigung';
    
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="fas ${icon}"></i>
        </div>
        <div class="notification-content">
            <div class="notification-title">${title}</div>
            <div class="notification-message">${message}</div>
        </div>
        <div class="notification-progress" style="animation-duration: ${duration}ms;"></div>
    `;
    
    // Add to container
    container.appendChild(notification);
    
    // Auto remove after duration
    setTimeout(() => {
        notification.classList.add('removing');
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300); // Match animation duration
    }, duration);
}

// Listen for NUI messages
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'showNotification') {
        showNotification(data.message, data.type || 'info', data.duration || 5000);
    }
});

console.log('[Haus-Manager Notifications] Loaded successfully');
