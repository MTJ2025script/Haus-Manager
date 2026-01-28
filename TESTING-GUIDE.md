# Haus-Manager - Testing Guide for Bug Fixes

This document provides step-by-step testing procedures to validate the bug fixes implemented in this PR.

## 🚗 1. Garage System Tests

### Test 1.1: Vehicle Exit Height (Fixed Bug)
**Issue:** Vehicles were spawning 1 meter in the air when exiting garage
**Fix:** Reduced z-offset from +1.0 to +0.5

**Test Steps:**
1. Enter a garage with a vehicle
2. Drive around inside the garage interior
3. Exit the garage by driving to the exit marker
4. **Expected:** Vehicle should spawn at ground level (z + 0.5), not floating in air
5. **Verify:** No visible gap between vehicle wheels and ground

### Test 1.2: Player Exit Position (Fixed Bug)
**Issue:** Players on foot were using incorrect z-coordinate
**Fix:** Players now use exact z-coordinate from saved entry position

**Test Steps:**
1. Enter a garage on foot (no vehicle)
2. Walk around inside the garage interior
3. Exit the garage by walking to the exit marker
4. **Expected:** Player should spawn at exact saved position, not floating or underground
5. **Verify:** Player feet should be firmly on the ground

### Test 1.3: Large Garage Capacity (Fixed Bug)
**Issue:** Large garage had only 10 slots instead of 16
**Fix:** Expanded parking slots from 10 to 16

**Test Steps:**
1. Create or find a property with "large" garage size
2. Store 11+ vehicles in the garage
3. Enter the garage interior
4. **Expected:** All vehicles should be visible and properly parked
5. **Verify:** Can store up to 16 vehicles without errors

### Test 1.4: Distance Validation (Fixed Bug)
**Issue:** Exit coordinates were saved without validating player proximity to garage
**Fix:** Added distance check (10 meter threshold)

**Test Steps:**
1. Stand near a garage entrance (within 10 meters)
2. Enter the garage
3. Exit the garage
4. **Expected:** Player/vehicle should spawn at their entry position
5. **Verify:** No teleportation to unexpected locations

### Test 1.5: Duplicate Distance Check (Fixed Bug)
**Issue:** Redundant nested distance check in marker thread
**Fix:** Removed inner distance check at line 475

**Test Steps:**
1. Walk around near a garage entrance
2. Observe the garage marker rendering
3. **Expected:** Smooth marker display without performance issues
4. **Verify:** No console errors or duplicate rendering

---

## 🔑 2. Temporary Key System Tests

### Test 2.1: Grant Temporary Key
**Feature:** Server can grant temporary keys with expiration time

**Test Steps:**
1. As property owner, open key management UI
2. Select a nearby player
3. Grant a temporary key (e.g., 2 hours)
4. **Expected:** Key is created with correct expiration time
5. **Verify:** Database shows `key_type='temporary'` and correct `expires_at` timestamp
6. **Verify:** Target player receives notification with key details

### Test 2.2: Grant Permanent Key
**Feature:** Server can grant permanent keys

**Test Steps:**
1. As property owner, open key management UI
2. Select a nearby player
3. Grant a permanent key
4. **Expected:** Key is created without expiration
5. **Verify:** Database shows `key_type='permanent'` and `expires_at=NULL`
6. **Verify:** Target player receives notification

### Test 2.3: Revoke Key
**Feature:** Owner can revoke any key (temporary or permanent)

**Test Steps:**
1. Grant a key to a player (temporary or permanent)
2. Open key management UI
3. Click "Entziehen" (Revoke) button
4. **Expected:** Key is removed from database
5. **Verify:** Player no longer has access to property
6. **Verify:** Player receives notification of revocation

### Test 2.4: Key Expiration (Server Time)
**Feature:** Temporary keys expire automatically using server time

**Test Steps:**
1. Grant a temporary key with short duration (e.g., 1 minute)
2. Wait for expiration time to pass
3. Try to access property with expired key
4. **Expected:** Access denied after expiration
5. **Verify:** Auto-cleanup thread removes expired key within 5 minutes
6. **Verify:** Player receives expiration notification

### Test 2.5: UI Display
**Feature:** UI shows both temporary and permanent keys

**Test Steps:**
1. Grant 2 temporary keys (different durations) and 1 permanent key
2. Open key management UI
3. **Expected:** All 3 keys visible in UI
4. **Expected:** Temporary keys show countdown timer
5. **Expected:** Permanent keys show "∞ Permanent" badge
6. **Expected:** Owner cannot revoke their own key
7. **Verify:** Countdown updates in real-time

### Test 2.6: Server Time Synchronization
**Feature:** All time calculations use server time (not client time)

**Test Steps:**
1. Grant a temporary key for 1 hour
2. Check database: `expires_at` should be `os.time() * 1000 + 3600000`
3. Query keys immediately
4. **Expected:** `seconds_remaining` should be approximately 3600
5. **Verify:** Time remaining decreases consistently
6. **Verify:** No client-side time manipulation possible

---

## 🛡️ 3. Security Tests

### Test 3.1: Expired Key Filtering
**Feature:** Server filters out expired keys automatically

**Test Steps:**
1. Manually set a key's `expires_at` to past timestamp in database
2. Try to access property with that key
3. **Expected:** Access denied
4. **Verify:** GetPropertyKeys() does not return expired key
5. **Verify:** HasPropertyKey() returns false for expired key

### Test 3.2: Permission Validation
**Feature:** Only property owner can manage keys

**Test Steps:**
1. As non-owner, try to open key management UI
2. **Expected:** Permission denied
3. **Verify:** Cannot grant or revoke keys without ownership

---

## 📊 4. Database Verification

### Query 4.1: Check Key Types
```sql
SELECT property_id, citizen_id, key_type, 
       FROM_UNIXTIME(expires_at/1000) as expires_at_readable,
       CASE 
         WHEN expires_at IS NULL THEN 'Never'
         WHEN expires_at > UNIX_TIMESTAMP()*1000 THEN 'Valid'
         ELSE 'Expired'
       END as status
FROM haus_keys
ORDER BY property_id, key_type, expires_at;
```

### Query 4.2: Find Expired Keys
```sql
SELECT * FROM haus_keys
WHERE key_type = 'temporary' 
  AND expires_at IS NOT NULL 
  AND expires_at <= UNIX_TIMESTAMP()*1000;
```
**Expected:** Should return empty result if auto-cleanup is working

---

## ✅ Success Criteria

All tests should pass with the following outcomes:

### Garage System:
- ✅ Vehicles spawn at correct height (no floating)
- ✅ Players spawn at correct position (no underground/floating)
- ✅ Large garages support 16 vehicles
- ✅ Exit coordinates validated before saving
- ✅ No duplicate distance checks

### Temporary Key System:
- ✅ Temporary keys can be granted with custom duration (1-168 hours)
- ✅ Permanent keys can be granted
- ✅ Keys can be revoked by owner
- ✅ Expired keys are automatically cleaned up
- ✅ UI displays both key types correctly
- ✅ Server time is used for all calculations
- ✅ Countdown timer shows accurate remaining time

### Security:
- ✅ Expired keys cannot be used
- ✅ Non-owners cannot manage keys
- ✅ Time cannot be manipulated client-side

---

## 🐛 Known Issues to Monitor

1. **Garage Interior Slots:** If more than 16 vehicles are stored, only first 16 will be visible
2. **Key Cleanup Interval:** Expired keys are removed every 5 minutes (not immediately)
3. **Timezone:** All times use server timezone (verify consistency)

---

## 📝 Testing Checklist

Print this checklist and mark each test as you complete it:

- [ ] Test 1.1: Vehicle Exit Height
- [ ] Test 1.2: Player Exit Position
- [ ] Test 1.3: Large Garage Capacity (16 slots)
- [ ] Test 1.4: Distance Validation
- [ ] Test 1.5: No Duplicate Distance Check
- [ ] Test 2.1: Grant Temporary Key
- [ ] Test 2.2: Grant Permanent Key
- [ ] Test 2.3: Revoke Key
- [ ] Test 2.4: Key Expiration
- [ ] Test 2.5: UI Display (both types)
- [ ] Test 2.6: Server Time Synchronization
- [ ] Test 3.1: Expired Key Filtering
- [ ] Test 3.2: Permission Validation
- [ ] Query 4.1: Verify Key Types in DB
- [ ] Query 4.2: Verify No Expired Keys Remain

---

## 🎯 Quick Smoke Test (5 minutes)

For rapid validation, run these critical tests:

1. **Garage:** Enter/exit with vehicle → vehicle should not float
2. **Temporary Key:** Grant 1-hour key → check UI shows countdown
3. **Permanent Key:** Grant permanent key → check UI shows "∞"
4. **Revoke:** Revoke a key → verify removal from UI
5. **Database:** Run Query 4.1 → verify key_type and expires_at values

If all 5 pass, the system is working correctly!
