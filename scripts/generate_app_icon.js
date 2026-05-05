/**
 * Generate Focux app icon: F-eagle on dark blue rounded-square badge.
 * Matches the AuthLogoMark rendering from the login screen.
 *
 * Usage: node generate_app_icon.js
 */
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const SIZE = 1024;
const CORNER_RADIUS = Math.round(SIZE * 0.22); // same ratio as AuthLogoMark (0.26 but slightly less for icon)
const EAGLE_SCALE = 0.82; // how much of the canvas the eagle fills

async function main() {
  const projectRoot = path.join(__dirname, '..');
  const logoPath = path.join(projectRoot, 'assets', 'images', 'logo_icon.png');
  const outputPath = path.join(projectRoot, 'brand', 'app_icon_eagle_1024.png');

  if (!fs.existsSync(logoPath)) {
    console.error('ERROR: logo_icon.png not found at', logoPath);
    process.exit(1);
  }

  // 1. Create the dark blue gradient background as SVG
  // Radial gradient matching AuthLogoMark: center(-0.3, -0.5) → #122E65 to #050B20
  const gradCx = 50 - 15; // 35%
  const gradCy = 50 - 25; // 25%
  const bgSvg = `
    <svg width="${SIZE}" height="${SIZE}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="bg" cx="${gradCx}%" cy="${gradCy}%" r="70%" fx="${gradCx}%" fy="${gradCy}%">
          <stop offset="0%" stop-color="#122E65"/>
          <stop offset="100%" stop-color="#050B20"/>
        </radialGradient>
        <rect id="rect" width="${SIZE}" height="${SIZE}" rx="${CORNER_RADIUS}" ry="${CORNER_RADIUS}"/>
        <clipPath id="clip">
          <use href="#rect"/>
        </clipPath>
      </defs>
      <use href="#rect" fill="url(#bg)" clip-path="url(#clip)"/>
      <!-- Subtle border -->
      <rect width="${SIZE}" height="${SIZE}" rx="${CORNER_RADIUS}" ry="${CORNER_RADIUS}"
            fill="none" stroke="rgba(124,192,255,0.10)" stroke-width="3"/>
    </svg>
  `;

  // 2. Create background image from SVG
  const bgBuffer = await sharp(Buffer.from(bgSvg))
    .png()
    .toBuffer();

  // 3. Load and resize the F-eagle logo
  const eagleSize = Math.round(SIZE * EAGLE_SCALE);
  const eagleOffset = Math.round((SIZE - eagleSize) / 2);

  const eagleBuffer = await sharp(logoPath)
    .resize(eagleSize, eagleSize, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();

  // 4. Apply screen blend: composite eagle onto background
  // Sharp supports 'screen' blend mode natively
  const result = await sharp(bgBuffer)
    .composite([
      {
        input: eagleBuffer,
        top: eagleOffset,
        left: eagleOffset,
        blend: 'screen',
      }
    ])
    .png({ quality: 100, compressionLevel: 6 })
    .toBuffer();

  // 5. Apply rounded corners mask to ensure clean edges
  const maskSvg = `
    <svg width="${SIZE}" height="${SIZE}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${SIZE}" height="${SIZE}" rx="${CORNER_RADIUS}" ry="${CORNER_RADIUS}" fill="white"/>
    </svg>
  `;

  const maskBuffer = await sharp(Buffer.from(maskSvg))
    .png()
    .toBuffer();

  // Final composite with mask for clean rounded corners
  const finalResult = await sharp(result)
    .composite([
      {
        input: maskBuffer,
        blend: 'dest-in', // Keep only pixels where mask is white
      }
    ])
    .png({ quality: 100 })
    .toBuffer();

  fs.writeFileSync(outputPath, finalResult);
  console.log(`✓ Generated: ${outputPath}`);

  // Verify
  const meta = await sharp(outputPath).metadata();
  console.log(`  Size: ${meta.width}x${meta.height}`);
  console.log(`  Format: ${meta.format}`);
  console.log(`  Corner radius: ${CORNER_RADIUS}px`);
  console.log(`  Eagle blend: screen mode (matches login AuthLogoMark)`);
}

main().catch(err => {
  console.error('Failed:', err);
  process.exit(1);
});
