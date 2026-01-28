# UI Background Images

This directory is for custom background images for the Haus-Manager UI system.

## Required Images (PNG format):

### 1. **ui-background.png** (Main Fallback Background)
- **Purpose:** Default/fallback background for all UIs if specific images aren't provided
- **Recommended size:** 1920x1080 pixels (or higher for 4K displays)
- **Usage:** Background for any `.ui-container` class
- **Suggested style:** Dark, neutral image that works for all UI types

### 2. **admin-ui-background.png** (Admin UI Background)
- **Purpose:** Background specifically for the Admin/Property Management UI
- **Recommended size:** 1920x1080 pixels (or higher for 4K displays)
- **Usage:** Background for `#adminUI` container when creating/editing properties
- **Suggested style:** Professional, administrative theme - perhaps office/building imagery

### 3. **player-ui-background.png** (Player UI Background)
- **Purpose:** Background specifically for the Player Property Purchase/Rent UI
- **Recommended size:** 1920x1080 pixels (or higher for 4K displays)
- **Usage:** Background for `#propertyUI` container when buying/renting properties
- **Suggested style:** Welcoming, real estate theme - perhaps luxury property imagery

## How to Add Your Images:

1. Create or prepare your 3 PNG background images
2. Name them exactly as shown above:
   - `ui-background.png`
   - `admin-ui-background.png`
   - `player-ui-background.png`
3. Place all 3 files in this directory (`html/img/`)
4. The CSS is already configured to use them automatically
5. Restart the resource: `ensure Haus-Manager`

## CSS Configuration:

The background images are configured in `html/css/style.css`:
```css
/* Main fallback background */
.ui-container {
    background-image: url('../img/ui-background.png');
    background-size: cover;
    background-position: center;
}

/* Admin UI specific background */
#adminUI.ui-container {
    background-image: url('../img/admin-ui-background.png');
}

/* Player UI specific background */
#propertyUI.ui-container {
    background-image: url('../img/player-ui-background.png');
}
```

## Design Tips:

- **Contrast:** Use darker images for better text readability
- **Theme:** Consider the GTA V yellow/green theme when choosing your images
- **Overlays:** Semi-transparent panels sit on top, so choose images that work well with overlays
- **Resolution:** Higher resolution images look better on 4K displays (2560x1440 or 3840x2160)
- **File Size:** Keep each under 2MB for faster loading
- **Style Consistency:** While each can be different, maintain visual consistency across the 3 images

## Image Purposes:

- **Main UI:** Generic/fallback background used if specific backgrounds aren't loaded
- **Admin UI:** Shows when admins are creating/editing/managing properties - use professional imagery
- **Player UI:** Shows when players are viewing property purchase/rent options - use appealing property imagery

## Notes:

- Images should be PNG format for best quality
- The UIs will still work without images (uses solid dark overlay as fallback)
- Each UI type has its own specific background for visual distinction
- Images load automatically when they exist in this directory
- If a specific image is missing, it falls back to `ui-background.png`

