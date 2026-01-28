// Sell to Player UI handling
let currentSellData = null;

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openSellToPlayer') {
        openSellToPlayerUI(data);
    }
});

// Open sell to player UI
function openSellToPlayerUI(data) {
    currentSellData = data;
    
    // Populate property info
    document.getElementById('sellPropertyName').textContent = data.property.name;
    document.getElementById('sellPropertyType').textContent = getPropertyTypeLabel(data.property.type);
    document.getElementById('sellPropertyOriginalPrice').textContent = formatMoney(data.property.price);
    
    // Populate player dropdown
    const playerSelect = document.getElementById('sellTargetPlayer');
    playerSelect.innerHTML = '<option value="">Spieler wählen...</option>';
    
    if (data.players && data.players.length > 0) {
        data.players.forEach(player => {
            const option = document.createElement('option');
            option.value = player.id;
            option.textContent = `${player.name} (ID: ${player.id})`;
            playerSelect.appendChild(option);
        });
    } else {
        playerSelect.innerHTML = '<option value="">Keine Spieler in der Nähe</option>';
    }
    
    // Set suggested price (75% of original)
    document.getElementById('sellPrice').value = Math.floor(data.property.price * 0.75);
    
    // Show UI
    document.getElementById('sellToPlayerUI').style.display = 'flex';
}

// Close sell UI
function closeSellUI() {
    console.log('[Haus-Manager NUI] closeSellUI() called');
    const sellUI = document.getElementById('sellToPlayerUI');
    if (sellUI) {
        sellUI.style.display = 'none';
        console.log('[Haus-Manager NUI] Sell UI closed');
    } else {
        console.error('[Haus-Manager NUI] Sell UI element not found');
    }
    currentSellData = null;
    
    // Notify client
    console.log('[Haus-Manager NUI] Sending closeSellUI fetch to client');
    fetch('https://haus-manager/closeSellUI', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then(() => {
        console.log('[Haus-Manager NUI] closeSellUI fetch successful');
    }).catch((error) => {
        console.error('[Haus-Manager NUI] closeSellUI fetch error:', error);
    });
}

// Make closeSellUI globally available for onclick handlers
window.closeSellUI = closeSellUI;
console.log('[Haus-Manager NUI] closeSellUI function exported to window');

// Confirm sell to player
function confirmSellToPlayer() {
    const targetId = document.getElementById('sellTargetPlayer').value;
    const price = document.getElementById('sellPrice').value;
    
    // Validation
    if (!targetId) {
        showNotification('Bitte wählen Sie einen Käufer aus!', 'error');
        return;
    }
    
    if (!price || price <= 0) {
        showNotification('Bitte geben Sie einen gültigen Preis ein!', 'error');
        return;
    }
    
    if (parseInt(price) > 99999999) {
        showNotification('Der Preis ist zu hoch!', 'error');
        return;
    }
    
    // Send to client
    fetch('https://haus-manager/sellToPlayer', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            propertyId: currentSellData.property.id,
            targetId: parseInt(targetId),
            price: parseInt(price)
        })
    }).then(response => response.json())
      .then(result => {
          if (result === 'ok') {
              closeSellUI();
          }
      });
}

// Get property type label
function getPropertyTypeLabel(type) {
    const labels = {
        'apartment': 'Wohnung',
        'house': 'Haus',
        'office': 'Büro'
    };
    return labels[type] || type;
}

// Format money with commas and dollar sign
function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Show notification (simple implementation)
function showNotification(message, type) {
    // You can enhance this with a proper notification system
    alert(message);
}

// Close UI on ESC key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        if (document.getElementById('sellToPlayerUI').style.display !== 'none') {
            closeSellUI();
        }
    }
});
