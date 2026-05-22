/**
 * Prepare Eagle brand assets:
 * - strip fake checkerboard from transparent F export
 * - build premium mesh splash surfaces + glass mark overlays
 */
const fs = require('fs');
const path = require('path');

async function getSharp() {
  try {
    return require('sharp');
  } catch (_) {
    const { execSync } = require('child_process');
    execSync('npm install sharp@0.33.5 --no-save', {
      cwd: __dirname,
      stdio: 'inherit',
    });
    return require('sharp');
  }
}

const BRAND_BG = { r: 18, g: 52, b: 60, alpha: 1 }; // #12343C mesh center
const BRAND_BG_DEEP = { r: 8, g: 12, b: 16, alpha: 1 }; // #080C10 edge

function isCheckerboard(r, g, b) {
  if (Math.abs(r - g) > 8 || Math.abs(g - b) > 8 || Math.abs(r - b) > 8) {
    return false;
  }
  const avg = (r + g + b) / 3;
  // Light (~240–255) and dark (~160–200) checkerboard squares from editor exports.
  return avg >= 155 && avg <= 255;
}

async function stripCheckerboard(inputPath, outputPath, sharp) {
  const { data, info } = await sharp(inputPath)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  for (let i = 0; i < data.length; i += 4) {
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    if (isCheckerboard(r, g, b)) {
      data[i + 3] = 0;
    }
  }

  await sharp(data, {
    raw: { width: info.width, height: info.height, channels: 4 },
  })
    .png()
    .toFile(outputPath);

  console.log(`✓ transparent mark: ${outputPath}`);
}

function meshBackgroundSvg(width, height) {
  const gridStep = 30;
  let gridLines = '';
  for (let x = 0; x <= width; x += gridStep) {
    gridLines += `<line x1="${x}" y1="0" x2="${x}" y2="${height}" stroke="rgba(94,234,212,0.05)" stroke-width="0.6"/>`;
  }
  for (let y = 0; y <= height; y += gridStep) {
    gridLines += `<line x1="0" y1="${y}" x2="${width}" y2="${y}" stroke="rgba(94,234,212,0.05)" stroke-width="0.6"/>`;
  }

  return `
    <svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="mesh" cx="50%" cy="36%" r="78%">
          <stop offset="0%" stop-color="#12343C"/>
          <stop offset="42%" stop-color="#0A1F24"/>
          <stop offset="100%" stop-color="#080C10"/>
        </radialGradient>
        <radialGradient id="heroGlow" cx="50%" cy="40%" r="34%">
          <stop offset="0%" stop-color="rgba(30,200,200,0.20)"/>
          <stop offset="55%" stop-color="rgba(94,234,212,0.08)"/>
          <stop offset="100%" stop-color="rgba(8,12,16,0)"/>
        </radialGradient>
      </defs>
      <rect width="100%" height="100%" fill="url(#mesh)"/>
      <rect width="100%" height="100%" fill="url(#heroGlow)"/>
      ${gridLines}
    </svg>
  `;
}

function glassTileSvg(size, radius) {
  return `
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="tile" cx="35%" cy="25%" r="75%">
          <stop offset="0%" stop-color="#0D2830"/>
          <stop offset="100%" stop-color="#080C10"/>
        </radialGradient>
        <linearGradient id="sheen" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="rgba(94,234,212,0.16)"/>
          <stop offset="35%" stop-color="rgba(94,234,212,0)"/>
        </linearGradient>
      </defs>
      <rect width="${size}" height="${size}" rx="${radius}" ry="${radius}" fill="url(#tile)"/>
      <rect width="${size}" height="${size}" rx="${radius}" ry="${radius}" fill="url(#sheen)"/>
      <rect width="${size}" height="${size}" rx="${radius}" ry="${radius}" fill="none" stroke="rgba(255,255,255,0.12)" stroke-width="2"/>
    </svg>
  `;
}

async function composeMarkOnly(markPath, outputPath, canvasSize, markScale, sharp) {
  const markSize = Math.round(canvasSize * markScale);
  const mark = await sharp(markPath)
    .trim({ threshold: 8 })
    .resize(markSize, markSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  await sharp({
    create: {
      width: canvasSize,
      height: canvasSize,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite([{ input: mark, gravity: 'centre' }])
    .png()
    .toFile(outputPath);

  console.log(`✓ mark-only overlay: ${outputPath}`);
}

async function composeGlassMarkOverlay(markPath, outputPath, canvasSize, tileScale, sharp) {
  const tileSize = Math.round(canvasSize * tileScale);
  const radius = Math.round(tileSize * 0.26);
  const tile = await sharp(Buffer.from(glassTileSvg(tileSize, radius)))
    .png()
    .toBuffer();
  const markSize = Math.round(tileSize * 0.72);
  const mark = await sharp(markPath)
    .trim({ threshold: 8 })
    .resize(markSize, markSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  const tileWithMark = await sharp(tile)
    .composite([{ input: mark, gravity: 'centre' }])
    .png()
    .toBuffer();

  await sharp({
    create: {
      width: canvasSize,
      height: canvasSize,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite([{ input: tileWithMark, gravity: 'centre' }])
    .png()
    .toFile(outputPath);

  console.log(`✓ glass mark overlay: ${outputPath}`);
}

async function composePremiumSplashCanvas(markPath, outputPath, size, tileScale, sharp) {
  const mesh = await sharp(Buffer.from(meshBackgroundSvg(size, size)))
    .png()
    .toBuffer();
  const tileSize = Math.round(size * tileScale);
  const radius = Math.round(tileSize * 0.26);
  const tile = await sharp(Buffer.from(glassTileSvg(tileSize, radius)))
    .png()
    .toBuffer();
  const markSize = Math.round(tileSize * 0.72);
  const mark = await sharp(markPath)
    .trim({ threshold: 8 })
    .resize(markSize, markSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  const tileWithMark = await sharp(tile)
    .composite([{ input: mark, gravity: 'centre' }])
    .png()
    .toBuffer();

  await sharp(mesh)
    .composite([{ input: tileWithMark, gravity: 'centre' }])
    .png()
    .toFile(outputPath);

  console.log(`✓ premium splash canvas: ${outputPath}`);
}

async function composeGlassAppIcon(markPath, outputPath, size, sharp) {
  const radius = Math.round(size * 0.22);
  const tile = await sharp(Buffer.from(glassTileSvg(size, radius))).png().toBuffer();
  const markSize = Math.round(size * 0.62);
  const mark = await sharp(markPath)
    .trim({ threshold: 8 })
    .resize(markSize, markSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  await sharp(tile)
    .composite([{ input: mark, gravity: 'centre' }])
    .png()
    .toFile(outputPath);

  console.log(`✓ glass app icon: ${outputPath}`);
}

async function composePortraitSplash(markPath, outputPath, sharp) {
  const width = 1080;
  const height = 1920;
  const mesh = await sharp(Buffer.from(meshBackgroundSvg(width, height)))
    .png()
    .toBuffer();
  const tileSize = Math.round(width * 0.46);
  const radius = Math.round(tileSize * 0.26);
  const tile = await sharp(Buffer.from(glassTileSvg(tileSize, radius)))
    .png()
    .toBuffer();
  const markSize = Math.round(tileSize * 0.72);
  const mark = await sharp(markPath)
    .trim({ threshold: 8 })
    .resize(markSize, markSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();
  const tileWithMark = await sharp(tile)
    .composite([{ input: mark, gravity: 'centre' }])
    .png()
    .toBuffer();

  await sharp(mesh)
    .composite([{ input: tileWithMark, gravity: 'centre' }])
    .png()
    .toFile(outputPath);

  console.log(`✓ portrait splash: ${outputPath}`);
}

async function writeSolidBg(outputPath, sharp) {
  await sharp({
    create: {
      width: 1,
      height: 1,
      channels: 4,
      background: BRAND_BG,
    },
  })
    .png()
    .toFile(outputPath);
}

async function main() {
  const sharp = await getSharp();
  const root = path.join(__dirname, '..');
  const assets = path.join(root, 'assets', 'images');
  const brand = path.join(root, 'brand');
  const sourceCandidates = [
    path.join(assets, 'logo_official.png'),
    path.join(assets, 'logo_icon_transparent.png'),
    path.join(
      process.env.USERPROFILE || '',
      '.cursor',
      'projects',
      'd-Projetos-Focux-Personal',
      'assets',
      'c__Users_mathe_AppData_Roaming_Cursor_User_workspaceStorage_b0ad238a091a6811f671c88c4fcf6b7a_images_Logo_Oficial-9792c166-df7e-4bf3-993e-853cb8c87dcd.png',
    ),
    path.join(
      process.env.USERPROFILE || '',
      '.cursor',
      'projects',
      'd-Projetos-Focux-Personal',
      'assets',
      'c__Users_mathe_AppData_Roaming_Cursor_User_workspaceStorage_b0ad238a091a6811f671c88c4fcf6b7a_images_focuxSemFundo-380c09ad-890a-4adb-8436-13bcfd1964db.png',
    ),
  ];

  const markSource = sourceCandidates.find((p) => fs.existsSync(p));
  if (!markSource) {
    console.error('Missing transparent F source asset');
    process.exit(1);
  }

  const markPath = path.join(assets, 'logo_mark_transparent.png');
  await stripCheckerboard(markSource, markPath, sharp);

  const meshBgPath = path.join(assets, 'splash_mesh_bg.png');
  await sharp(Buffer.from(meshBackgroundSvg(1080, 1920)))
    .png()
    .toFile(meshBgPath);
  console.log(`✓ mesh background: ${meshBgPath}`);

  await composeMarkOnly(
    markPath,
    path.join(assets, 'logo_splash_f_only.png'),
    640,
    0.58,
    sharp,
  );

  await composeMarkOnly(
    markPath,
    path.join(assets, 'logo_splash_f_padded.png'),
    1152,
    0.52,
    sharp,
  );

  await composeGlassMarkOverlay(
    markPath,
    path.join(assets, 'logo_splash_mark.png'),
    640,
    0.72,
    sharp,
  );

  await composePremiumSplashCanvas(
    markPath,
    path.join(assets, 'logo_splash.png'),
    1024,
    0.54,
    sharp,
  );

  await composeMarkOnly(
    markPath,
    path.join(assets, 'logo_icon_padded.png'),
    1152,
    0.52,
    sharp,
  );

  await composePortraitSplash(
    markPath,
    path.join(assets, 'splash_portrait.png'),
    sharp,
  );

  await composeGlassAppIcon(markPath, path.join(brand, 'app_icon_eagle_1024.png'), 1024, sharp);

  await writeSolidBg(path.join(assets, 'splash_background.png'), sharp);

  console.log('Brand assets ready.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
