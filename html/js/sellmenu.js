/* ========================================
   VERKAUFSMENÜ JAVASCRIPT
   NUI-basiertes Verkaufssystem
   ======================================== */

let currentProperty = null;
let selectedOption = null;
let nearbyPlayers = [];

// Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    console.log('[Sell Menu] Received message:', data);
    
    if (data.action === 'openSellMenu') {
        openSellMenu(data.property, data.originalPrice, data.sellPrice, data.players);
    } else if (data.action === 'closeSellMenu') {
        closeSellMenu();
    }
});

// Open Sell Menu
function openSellMenu(property, originalPrice, sellPrice, players) {
    console.log('[Sell Menu] Opening menu for:', property.property_name);
    
    currentProperty = property;
    nearbyPlayers = players || [];
    
    // Set property name
    document.querySelector('.sell-property-name').textContent = property.property_name;
    
    // Set info
    document.getElementById('sell-info-price').textContent = formatMoney(originalPrice);
    document.getElementById('sell-info-city-price').textContent = formatMoney(sellPrice);
    document.getElementById('sell-info-loss').textContent = formatMoney(originalPrice - sellPrice);
    
    // Show container
    document.querySelector('.sell-container').classList.add('active');
    
    // Enable NUI focus
    fetch(`https://${GetParentResourceName()}/nuiFocus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ focus: true })
    });
    
    console.log('[Sell Menu] Menu opened successfully');
}

// Close Sell Menu
function closeSellMenu() {
    console.log('[Sell Menu] Closing menu');
    
    document.querySelector('.sell-container').classList.remove('active');
    document.querySelector('.sell-player-selection').classList.remove('active');
    selectedOption = null;
    
    // Disable NUI focus
    fetch(`https://${GetParentResourceName()}/nuiFocus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ focus: false })
    });
}

// Select Option
function selectSellOption(option) {
    console.log('[Sell Menu] Selected option:', option);
    selectedOption = option;
    
    if (option === 'city') {
        // Stadt-Verkauf - sofort bestätigen
        confirmSell();
    } else if (option === 'player') {
        // Spieler-Verkauf - zeige Spieler-Liste
        showPlayerSelection();
    }
}

// Show Player Selection
function showPlayerSelection() {
    const playerList = document.querySelector('.sell-player-list');
    playerList.innerHTML = '';
    
    if (nearbyPlayers.length === 0) {
        playerList.innerHTML = `
            <div style="text-align: center; padding: 20px; color: rgba(255,255,255,0.6);">
                Keine Spieler in der Nähe
            </div>
        `;
    } else {
        nearbyPlayers.forEach(player => {
            const item = document.createElement('div');
            item.className = 'sell-player-item';
            item.innerHTML = `
                <div class="sell-player-name">${player.name}</div>
                <div class="sell-player-id">ID: ${player.id}</div>
            `;
            item.onclick = () => selectPlayer(player);
            playerList.appendChild(item);
        });
    }
    
    document.querySelector('.sell-player-selection').classList.add('active');
}

// Select Player
function selectPlayer(player) {
    console.log('[Sell Menu] Selected player:', player);
    
    // Highlight selected
    document.querySelectorAll('.sell-player-item').forEach(item => {
        item.style.borderColor = 'rgba(64, 224, 208, 0.2)';
    });
    event.currentTarget.style.borderColor = 'rgba(64, 224, 208, 0.8)';
    
    // Enable confirm button
    document.querySelector('.sell-btn-confirm').disabled = false;
    document.querySelector('.sell-btn-confirm').dataset.playerId = player.id;
}

// Confirm Sell
function confirmSell() {
    console.log('[Sell Menu] Confirming sell, option:', selectedOption);
    
    if (selectedOption === 'city') {
        // Verkauf an Stadt
        fetch(`https://${GetParentResourceName()}/sellToCity`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                propertyId: currentProperty.property_id
            })
        }).then(() => {
            console.log('[Sell Menu] Sell to city confirmed');
            closeSellMenu();
        });
    } else if (selectedOption === 'player') {
        // Verkauf an Spieler
        const playerId = document.querySelector('.sell-btn-confirm').dataset.playerId;
        const price = document.getElementById('sell-price-input').value;
        
        if (!playerId) {
            console.log('[Sell Menu] No player selected');
            return;
        }
        
        if (!price || isNaN(price) || price <= 0) {
            console.log('[Sell Menu] Invalid price');
            return;
        }
        
        fetch(`https://${GetParentResourceName()}/sellToPlayer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                propertyId: currentProperty.property_id,
                targetId: parseInt(playerId),
                price: parseInt(price)
            })
        }).then(() => {
            console.log('[Sell Menu] Sell to player confirmed');
            closeSellMenu();
        });
    }
}

// Cancel
function cancelSell() {
    console.log('[Sell Menu] Sell cancelled');
    closeSellMenu();
}

// Format Money
function formatMoney(amount) {
    return new Intl.NumberFormat('de-DE', {
        style: 'currency',
        currency: 'EUR'
    }).format(amount);
}

// ESC Key Handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        if (document.querySelector('.sell-container').classList.contains('active')) {
            closeSellMenu();
        }
    }
});

// Get Resource Name
function GetParentResourceName() {
    return 'Haus-Manager';
}

console.log('[Sell Menu] JavaScript loaded');
