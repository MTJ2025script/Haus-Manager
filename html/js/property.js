// Property Purchase/Rent UI Functions
let currentPropertyId = null;

function openPropertyUI(property) {
    if (!property || !currentConfig) {
        return;
    }
    
    // Set property title and type with safety checks
    const propTitle = document.getElementById('propTitle');
    const propType = document.getElementById('propType');
    const propInterior = document.getElementById('propInterior');
    const propPrice = document.getElementById('propPrice');
    const buyPrice = document.getElementById('buyPrice');
    
    if (propTitle) propTitle.textContent = property.property_name || 'Unbenannt';
    if (propType) propType.textContent = formatPropertyType(property.property_type);
    
    // Set interior type
    const interior = currentConfig.Interiors && currentConfig.Interiors[property.interior_type];
    if (propInterior) propInterior.textContent = interior ? interior.label : (property.interior_type || 'N/A');
    
    // Set price
    const price = property.price || 0;
    if (propPrice) propPrice.textContent = formatCurrency(price);
    if (buyPrice) buyPrice.textContent = formatCurrency(price);
    
    // Store property ID for later use
    currentPropertyId = property.property_id;
    
    // Populate rent options
    populateRentOptions(property);
    
    // Show UI
    const propertyUI = document.getElementById('propertyUI');
    if (propertyUI) propertyUI.style.display = 'flex';
}

function populateRentOptions(property) {
    const container = document.getElementById('rentOptions');
    if (!container) return;
    container.innerHTML = '';
    
    if (!currentConfig || !currentConfig.RentPeriods) {
        return;
    }
    
    const propertyPrice = property.price || 0;
    
    currentConfig.RentPeriods.forEach((period, index) => {
        const rentPrice = Math.floor(propertyPrice * (period.multiplier || 0));
        
        const optionHTML = `
            <div class="rent-option" data-period="${period.days || 0}" data-price="${rentPrice}">
                <div class="rent-option-period">${period.label || 'N/A'}</div>
                <div class="rent-option-price">${formatCurrency(rentPrice)}</div>
                <div class="rent-option-desc">${period.days || 0} Tage</div>
            </div>
        `;
        
        container.insertAdjacentHTML('beforeend', optionHTML);
    });
    
    // Add click handlers after elements are created
    container.querySelectorAll('.rent-option').forEach(option => {
        option.addEventListener('click', function() {
            container.querySelectorAll('.rent-option').forEach(o => o.classList.remove('selected'));
            this.classList.add('selected');
        });
        
        option.addEventListener('dblclick', function() {
            rentProperty();
        });
    });
}

function purchaseProperty() {
    if (!currentPropertyId) {
        showToast('Fehler: Immobilie nicht gefunden!', 'error');
        return;
    }
    
    showConfirmDialog('Möchten Sie diese Immobilie wirklich kaufen?', function() {
        fetch('https://haus-manager/purchaseProperty', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                propertyId: currentPropertyId
            })
        });
        
        closeUI();
    });
}

function rentProperty() {
    const selectedOption = document.querySelector('.rent-option.selected');
    
    if (!currentPropertyId) {
        showToast('Fehler: Immobilie nicht gefunden!', 'error');
        return;
    }
    
    if (!selectedOption) {
        showToast('Bitte wählen Sie einen Mietzeitraum!', 'error');
        return;
    }
    
    const rentPeriod = parseInt(selectedOption.dataset.period);
    const rentPrice = parseInt(selectedOption.dataset.price);
    
    showConfirmDialog(`Möchten Sie diese Immobilie für ${formatCurrency(rentPrice)} mieten?`, function() {
        fetch('https://haus-manager/rentProperty', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                propertyId: currentPropertyId,
                rentPeriod: rentPeriod
            })
        });
        
        closeUI();
    });
}

// Garage UI Functions
function openGarageUI() {
    populateGaragePropertySelect();
    const garageUI = document.getElementById('garageUI');
    if (garageUI) garageUI.style.display = 'flex';
}

function populateGaragePropertySelect() {
    const select = document.getElementById('garagePropertySelect');
    if (!select) return;
    select.innerHTML = '';
    
    if (!currentProperties || currentProperties.length === 0) {
        const option = document.createElement('option');
        option.value = '';
        option.textContent = 'Keine Immobilien verfügbar';
        select.appendChild(option);
        return;
    }
    
    currentProperties.forEach(property => {
        const option = document.createElement('option');
        option.value = property.property_id;
        option.textContent = `${property.property_name} (${formatPropertyType(property.property_type)})`;
        select.appendChild(option);
    });
}

function getGaragePosition() {
    fetch('https://haus-manager/getPlayerPosition', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.text();
    })
    .then(text => {
        try {
            const coords = JSON.parse(text);
            document.getElementById('garageCoordX').value = coords.x.toFixed(2);
            document.getElementById('garageCoordY').value = coords.y.toFixed(2);
            document.getElementById('garageCoordZ').value = coords.z.toFixed(2);
            showToast('Garage-Position übernommen!', 'success');
        } catch (e) {
            showToast('Fehler beim Verarbeiten der Position!', 'error');
        }
    })
    .catch(error => {
        console.error('Error getting position:', error);
        showToast('Fehler beim Abrufen der Position!', 'error');
    });
}

function addGarage() {
    const propertyId = document.getElementById('garagePropertySelect').value;
    const garageSize = document.getElementById('garageSize').value;
    
    if (!propertyId) {
        showToast('Bitte wählen Sie eine Immobilie!', 'error');
        return;
    }
    
    const garageCoords = {
        x: parseFloat(document.getElementById('garageCoordX').value) || 0,
        y: parseFloat(document.getElementById('garageCoordY').value) || 0,
        z: parseFloat(document.getElementById('garageCoordZ').value) || 0,
        heading: 0
    };
    
    if (garageCoords.x === 0 && garageCoords.y === 0) {
        showToast('Bitte geben Sie eine gültige Position ein!', 'error');
        return;
    }
    
    fetch('https://haus-manager/updateProperty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            propertyId: propertyId,
            updates: {
                garageCoords: garageCoords,
                garageSize: garageSize
            }
        })
    });
    
    // Reset form
    document.getElementById('garageCoordX').value = '';
    document.getElementById('garageCoordY').value = '';
    document.getElementById('garageCoordZ').value = '';
    
    showToast('Garage wird hinzugefügt...', 'success');
}
