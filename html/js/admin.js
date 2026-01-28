// Admin UI Functions

function openAdminUI() {
    console.log('[Haus-Manager] openAdminUI called');
    console.log('[Haus-Manager] currentConfig:', currentConfig);
    console.log('[Haus-Manager] currentProperties:', currentProperties);
    
    populateInteriorTypes();
    populatePropertiesList();
    setupMultiOwnerToggle();
    
    const adminUI = document.getElementById('adminUI');
    if (adminUI) {
        console.log('[Haus-Manager] Setting adminUI display to flex');
        adminUI.style.display = 'flex';
    } else {
        console.error('[Haus-Manager] adminUI element not found!');
    }
}

function setupMultiOwnerToggle() {
    const checkbox = document.getElementById('allowMultiOwner');
    const maxOwnersGroup = document.getElementById('maxOwnersGroup');
    
    if (checkbox && maxOwnersGroup) {
        checkbox.addEventListener('change', function() {
            maxOwnersGroup.style.display = this.checked ? 'block' : 'none';
        });
    }
    
    // Setup for edit modal as well
    const editCheckbox = document.getElementById('editAllowMultiOwner');
    const editMaxOwnersGroup = document.getElementById('editMaxOwnersGroup');
    
    if (editCheckbox && editMaxOwnersGroup) {
        editCheckbox.addEventListener('change', function() {
            editMaxOwnersGroup.style.display = this.checked ? 'block' : 'none';
        });
    }
}

function populateInteriorTypes() {
    const select = document.getElementById('interiorType');
    if (!select) return;
    select.innerHTML = '';
    
    if (!currentConfig || !currentConfig.Interiors) return;
    
    for (const [key, interior] of Object.entries(currentConfig.Interiors)) {
        const option = document.createElement('option');
        option.value = key;
        option.textContent = interior.label;
        select.appendChild(option);
    }
}

function populatePropertiesList() {
    const container = document.getElementById('propertiesList');
    if (!container) return;
    container.innerHTML = '';
    
    if (!currentProperties || currentProperties.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">🏠</div>
                <div class="empty-state-text">Keine Immobilien vorhanden</div>
            </div>
        `;
        return;
    }
    
    currentProperties.forEach(property => {
        // Safety checks
        if (!property || !property.property_id) return;
        
        const isOwned = property.owned === 1;
        const isRented = property.is_rented === 1;
        const typeClass = `badge-${property.property_type || 'apartment'}`;
        
        // Determine status with explicit rental/ownership info
        let statusBadges = '';
        
        // Ownership status
        const maxOwners = property.max_owners || 1;
        const currentOwners = property.current_owner_count || 0;
        
        if (currentOwners > 0) {
            if (maxOwners > 1) {
                // Multi-owner property
                if (currentOwners >= maxOwners) {
                    statusBadges += `<span class="property-badge badge-owned">${currentOwners}/${maxOwners} Verkauft</span>`;
                } else {
                    statusBadges += `<span class="property-badge badge-partial">${currentOwners}/${maxOwners} Verkauft</span>`;
                }
            } else {
                // Single owner
                statusBadges += '<span class="property-badge badge-owned">Verkauft</span>';
            }
        } else {
            statusBadges += '<span class="property-badge badge-available">Verfügbar</span>';
        }
        
        // Rental status (explicit and separate)
        if (isRented) {
            statusBadges += '<span class="property-badge badge-rented">Vermietet</span>';
        }
        
        // Handle coords - could be string or already parsed object
        let coords = { x: 0, y: 0, z: 0 };
        try {
            if (property.coords) {
                coords = typeof property.coords === 'string' ? JSON.parse(property.coords) : property.coords;
            }
        } catch (e) {
            console.error('Error parsing coords for property:', property.property_id, e);
        }
        
        // Owner and renter info
        let ownerInfo = '';
        if (property.owner_identifier) {
            ownerInfo = `<div class="info-item"><strong>Eigentümer:</strong> ${property.owner_identifier}</div>`;
        }
        if (maxOwners > 1) {
            ownerInfo = `<div class="info-item"><strong>Verkauft:</strong> ${currentOwners} von ${maxOwners} Plätzen</div>`;
        }
        
        let renterInfo = '';
        if (isRented && property.rent_end_date) {
            const endDate = new Date(property.rent_end_date);
            renterInfo = `<div class="info-item"><strong>Vermietet bis:</strong> ${endDate.toLocaleDateString('de-DE')}</div>`;
        }
        
        // Safe and wardrobe status
        let safeInfo = '';
        let wardrobeInfo = '';
        
        if (property.safe_coords) {
            try {
                const safeCoords = typeof property.safe_coords === 'string' ? JSON.parse(property.safe_coords) : property.safe_coords;
                if (safeCoords && safeCoords.x !== undefined) {
                    safeInfo = `<div class="info-item"><strong>🔒 Safe:</strong> ✅ Gesetzt</div>`;
                }
            } catch (e) {
                console.error('Error parsing safe_coords:', e);
            }
        } else {
            safeInfo = `<div class="info-item"><strong>🔒 Safe:</strong> ❌ Nicht gesetzt</div>`;
        }
        
        if (property.wardrobe_coords) {
            try {
                const wardrobeCoords = typeof property.wardrobe_coords === 'string' ? JSON.parse(property.wardrobe_coords) : property.wardrobe_coords;
                if (wardrobeCoords && wardrobeCoords.x !== undefined) {
                    wardrobeInfo = `<div class="info-item"><strong>👔 Garderobe:</strong> ✅ Gesetzt</div>`;
                }
            } catch (e) {
                console.error('Error parsing wardrobe_coords:', e);
            }
        } else {
            wardrobeInfo = `<div class="info-item"><strong>👔 Garderobe:</strong> ❌ Nicht gesetzt</div>`;
        }
        
        const itemHTML = `
            <div class="property-item">
                <div class="property-item-header">
                    <div class="property-item-title">${property.property_name || 'Unbenannt'}</div>
                    <div>
                        <span class="property-badge ${typeClass}">${formatPropertyType(property.property_type)}</span>
                        ${statusBadges}
                    </div>
                </div>
                <div class="property-item-info">
                    <div class="info-item">
                        <strong>Preis:</strong> ${formatCurrency(property.price)}
                    </div>
                    <div class="info-item">
                        <strong>Innenraum:</strong> ${property.interior_type || 'N/A'}
                    </div>
                    <div class="info-item">
                        <strong>Position:</strong> ${coords.x.toFixed(1)}, ${coords.y.toFixed(1)}, ${coords.z.toFixed(1)}
                    </div>
                    <div class="info-item">
                        <strong>Marker:</strong> ${property.marker_visible === 1 ? 'Sichtbar' : 'Versteckt'}
                    </div>
                    ${safeInfo}
                    ${wardrobeInfo}
                    ${ownerInfo}
                    ${renterInfo}
                </div>
                <div class="property-item-actions">
                    <button class="btn-edit" onclick="editProperty('${property.property_id}')">Bearbeiten</button>
                    <button class="btn-danger" onclick="deleteProperty('${property.property_id}')">Löschen</button>
                </div>
            </div>
        `;
        
        container.insertAdjacentHTML('beforeend', itemHTML);
    });
}

function getPlayerPosition() {
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
            document.getElementById('coordX').value = coords.x.toFixed(2);
            document.getElementById('coordY').value = coords.y.toFixed(2);
            document.getElementById('coordZ').value = coords.z.toFixed(2);
            showToast('Position übernommen!', 'success');
        } catch (e) {
            console.error('Error parsing response:', e, 'Response:', text);
            showToast('Fehler beim Verarbeiten der Position!', 'error');
        }
    })
    .catch(error => {
        console.error('Error getting position:', error);
        showToast('Fehler beim Abrufen der Position!', 'error');
    });
}

function createProperty() {
    const allowMultiOwner = document.getElementById('allowMultiOwner').checked;
    const maxOwners = allowMultiOwner ? parseInt(document.getElementById('maxOwners').value) : 1;
    
    // Parse Vec4 coords helper function
    function parseVec4(input) {
        if (!input || input.trim() === '') return null;
        const parts = input.split(',').map(s => parseFloat(s.trim()));
        if (parts.length !== 4 || parts.some(isNaN)) return null;
        return { x: parts[0], y: parts[1], z: parts[2], heading: parts[3] };
    }
    
    const safeCoords = parseVec4(document.getElementById('safeCoords').value);
    const wardrobeCoords = parseVec4(document.getElementById('wardrobeCoords').value);
    
    const propertyData = {
        propertyType: document.getElementById('propertyType').value,
        propertyName: document.getElementById('propertyName').value,
        interiorType: document.getElementById('interiorType').value,
        price: parseInt(document.getElementById('propertyPrice').value) || 0,
        coords: {
            x: parseFloat(document.getElementById('coordX').value) || 0,
            y: parseFloat(document.getElementById('coordY').value) || 0,
            z: parseFloat(document.getElementById('coordZ').value) || 0,
            heading: 0
        },
        markerVisible: document.getElementById('markerVisible').checked,
        markerRadius: parseFloat(document.getElementById('markerRadius').value) || 50.0,
        safeCoords: safeCoords,
        wardrobeCoords: wardrobeCoords,
        maxOwners: maxOwners
    };
    
    // Validate
    if (!propertyData.propertyName) {
        showToast('Bitte geben Sie einen Namen ein!', 'error');
        return;
    }
    
    if (propertyData.price <= 0) {
        showToast('Bitte geben Sie einen gültigen Preis ein!', 'error');
        return;
    }
    
    if (propertyData.coords.x === 0 && propertyData.coords.y === 0) {
        showToast('Bitte geben Sie eine Position ein!', 'error');
        return;
    }
    
    fetch('https://haus-manager/createProperty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(propertyData)
    });
    
    // Reset form
    document.getElementById('propertyName').value = '';
    document.getElementById('propertyPrice').value = '';
    document.getElementById('coordX').value = '';
    document.getElementById('coordY').value = '';
    document.getElementById('coordZ').value = '';
    document.getElementById('markerRadius').value = '50.0';
    document.getElementById('safeCoords').value = '';
    document.getElementById('wardrobeCoords').value = '';
    
    showToast('Immobilie wird erstellt...', 'info');
}

function editProperty(propertyId) {
    console.log('[Haus-Manager] editProperty called with ID:', propertyId, 'Type:', typeof propertyId);
    console.log('[Haus-Manager] currentProperties:', currentProperties);
    console.log('[Haus-Manager] Looking for property in:', currentProperties.map(p => ({id: p.property_id, type: typeof p.property_id})));
    
    // Find the property - compare both as strings since property_id might be string or number
    const property = currentProperties.find(p => String(p.property_id) === String(propertyId));
    if (!property) {
        console.error('[Haus-Manager] Property not found! ID:', propertyId);
        console.error('[Haus-Manager] Available properties:', currentProperties);
        showToast('Immobilie nicht gefunden!', 'error');
        return;
    }
    
    console.log('[Haus-Manager] Found property:', property);
    
    // Open edit modal
    const modal = document.getElementById('editPropertyModal');
    if (!modal) {
        console.error('[Haus-Manager] Edit modal not found');
        return;
    }
    
    // Parse coords
    let coords = { x: 0, y: 0, z: 0 };
    try {
        coords = typeof property.coords === 'string' ? JSON.parse(property.coords) : property.coords;
    } catch (e) {
        console.error('Error parsing coords:', e);
    }
    
    // Pre-fill form fields
    document.getElementById('editPropertyId').value = property.property_id;
    document.getElementById('editPropertyName').value = property.property_name || '';
    document.getElementById('editPropertyType').value = property.property_type || 'apartment';
    document.getElementById('editPropertyPrice').value = property.price || 0;
    document.getElementById('editCoordX').value = coords.x ? coords.x.toFixed(2) : '0';
    document.getElementById('editCoordY').value = coords.y ? coords.y.toFixed(2) : '0';
    document.getElementById('editCoordZ').value = coords.z ? coords.z.toFixed(2) : '0';
    document.getElementById('editInteriorType').value = property.interior_type || '';
    document.getElementById('editMarkerVisible').checked = property.marker_visible === 1;
    document.getElementById('editMarkerRadius').value = property.marker_radius || 50.0;
    
    // Safe and wardrobe coords (if they exist)
    document.getElementById('editSafeCoords').value = property.safe_coords ? 
        JSON.parse(property.safe_coords).x + ', ' + JSON.parse(property.safe_coords).y + ', ' + 
        JSON.parse(property.safe_coords).z + ', ' + JSON.parse(property.safe_coords).heading : '';
    document.getElementById('editWardrobeCoords').value = property.wardrobe_coords ?
        JSON.parse(property.wardrobe_coords).x + ', ' + JSON.parse(property.wardrobe_coords).y + ', ' +
        JSON.parse(property.wardrobe_coords).z + ', ' + JSON.parse(property.wardrobe_coords).heading : '';
    
    // Multi-ownership
    const maxOwners = property.max_owners || 1;
    document.getElementById('editAllowMultiOwner').checked = maxOwners > 1;
    document.getElementById('editMaxOwners').value = maxOwners;
    document.getElementById('editMaxOwnersGroup').style.display = maxOwners > 1 ? 'block' : 'none';
    
    // Populate interior types for edit modal
    populateEditInteriorTypes();
    
    // Show modal
    modal.style.display = 'flex';
}

function populateEditInteriorTypes() {
    const select = document.getElementById('editInteriorType');
    if (!select || !currentConfig || !currentConfig.Interiors) return;
    
    select.innerHTML = '';
    for (const [key, interior] of Object.entries(currentConfig.Interiors)) {
        const option = document.createElement('option');
        option.value = key;
        option.textContent = interior.label;
        select.appendChild(option);
    }
}

function getEditPlayerPosition() {
    fetch('https://haus-manager/getPlayerPosition', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(response => response.text())
    .then(text => {
        try {
            const coords = JSON.parse(text);
            document.getElementById('editCoordX').value = coords.x.toFixed(2);
            document.getElementById('editCoordY').value = coords.y.toFixed(2);
            document.getElementById('editCoordZ').value = coords.z.toFixed(2);
            showToast('Position übernommen!', 'success');
        } catch (e) {
            console.error('Error parsing response:', e);
            showToast('Fehler beim Verarbeiten der Position!', 'error');
        }
    })
    .catch(error => {
        console.error('Error getting position:', error);
        showToast('Fehler beim Abrufen der Position!', 'error');
    });
}

function savePropertyEdits() {
    const propertyId = document.getElementById('editPropertyId').value;
    
    // Parse Vec4 coords helper
    function parseVec4(input) {
        if (!input || input.trim() === '') return null;
        const parts = input.split(',').map(s => parseFloat(s.trim()));
        if (parts.length !== 4 || parts.some(isNaN)) return null;
        return { x: parts[0], y: parts[1], z: parts[2], heading: parts[3] };
    }
    
    const safeCoords = parseVec4(document.getElementById('editSafeCoords').value);
    const wardrobeCoords = parseVec4(document.getElementById('editWardrobeCoords').value);
    const allowMultiOwner = document.getElementById('editAllowMultiOwner').checked;
    const maxOwners = allowMultiOwner ? parseInt(document.getElementById('editMaxOwners').value) : 1;
    
    const updates = {
        propertyName: document.getElementById('editPropertyName').value,
        propertyType: document.getElementById('editPropertyType').value,
        price: parseInt(document.getElementById('editPropertyPrice').value) || 0,
        coords: {
            x: parseFloat(document.getElementById('editCoordX').value) || 0,
            y: parseFloat(document.getElementById('editCoordY').value) || 0,
            z: parseFloat(document.getElementById('editCoordZ').value) || 0,
            heading: 0
        },
        interiorType: document.getElementById('editInteriorType').value,
        markerVisible: document.getElementById('editMarkerVisible').checked,
        markerRadius: parseFloat(document.getElementById('editMarkerRadius').value) || 50.0,
        safeCoords: safeCoords,
        wardrobeCoords: wardrobeCoords,
        maxOwners: maxOwners
    };
    
    // Validate
    if (!updates.propertyName) {
        showToast('Bitte geben Sie einen Namen ein!', 'error');
        return;
    }
    
    if (updates.price <= 0) {
        showToast('Bitte geben Sie einen gültigen Preis ein!', 'error');
        return;
    }
    
    fetch('https://haus-manager/updateProperty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            propertyId: propertyId,
            updates: updates
        })
    });
    
    // Close modal
    closeEditModal();
    showToast('Immobilie wird aktualisiert...', 'info');
}

function closeEditModal() {
    console.log('[Haus-Manager NUI] closeEditModal() called');
    const modal = document.getElementById('editPropertyModal');
    if (modal) {
        modal.style.display = 'none';
        console.log('[Haus-Manager NUI] Edit modal closed');
    } else {
        console.error('[Haus-Manager NUI] Edit modal element not found');
    }
}

// Make closeEditModal globally available for onclick handlers
window.closeEditModal = closeEditModal;
console.log('[Haus-Manager NUI] closeEditModal function exported to window');

function deleteProperty(propertyId) {
    showConfirmDialog('Sind Sie sicher, dass Sie diese Immobilie löschen möchten?', function() {
        fetch('https://haus-manager/deleteProperty', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                propertyId: propertyId
            })
        });
        
        showToast('Immobilie wird gelöscht...', 'info');
    });
}

// Clear safe coordinates and remove prop from game
function clearSafeCoords() {
    const input = document.getElementById('editSafeCoords');
    if (input) {
        const oldValue = input.value;
        input.value = '';
        
        // If there were coordinates before, notify server to remove the safe prop
        if (oldValue && oldValue.trim() !== '') {
            // Get current property ID from modal
            const propertyId = document.getElementById('editPropertyId')?.value;
            if (propertyId) {
                // Send event to remove safe prop immediately
                fetch('https://haus-manager/removeSafeProp', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ propertyId: parseInt(propertyId) })
                });
            }
        }
        
        showToast('Safe Koordinaten gelöscht - Safe wird entfernt', 'success');
    }
}

// Clear wardrobe coordinates and remove marker from game
function clearWardrobeCoords() {
    const input = document.getElementById('editWardrobeCoords');
    if (input) {
        const oldValue = input.value;
        input.value = '';
        
        // If there were coordinates before, notify server to remove the wardrobe marker
        if (oldValue && oldValue.trim() !== '') {
            // Get current property ID from modal
            const propertyId = document.getElementById('editPropertyId')?.value;
            if (propertyId) {
                // Send event to remove wardrobe marker immediately
                fetch('https://haus-manager/removeWardrobeProp', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ propertyId: parseInt(propertyId) })
                });
            }
        }
        
        showToast('Garderobe Koordinaten gelöscht - Garderobe wird entfernt', 'success');
    }
}
