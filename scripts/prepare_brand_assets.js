/**
 * Prepare Eagle brand assets:
 * - strip fake checkerboard from transparent F export
 * - build splash / launcher surfaces from mark + #080C10 (not 3D scene PNG)
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

const BRAND_BG = { r: 8, g: 12, b: 16, alpha: 1 }; // #080C10

function isCheckerboard(r, g, b) {
  if (Math.abs(r - g) > 10 || Math.abs(g - b) > 10 || Math.abs(r - b) > 10) {
    return false;
  }
  const avg = (r + g + b) / 3;
  return avg >= 168;
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

async function composeMarkOnBrandBg(inputPath, outputPath, size, iconScale, sharp) {
  const trimmed = await sharp(inputPath)
    .trim({ threshold: 8 })
    .toBuffer();

  const iconSize = Math.round(size * iconScale);
  const icon = await sharp(trimmed)
    .resize(iconSize, iconSize, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  await sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: BRAND_BG,
    },
  })
    .composite([{ input: icon, gravity: 'centre' }])
    .png()
    .toFile(outputPath);

  console.log(`✓ brand surface: ${outputPath}`);
}

function glassTileSvg(size, radius) {
  return `
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="tile" cx="35%" cy="25%" r="75%">
          <stop offset="0%" stop-color="#0D2830"/>
          <stop offset="100%" stop-color="#080C10"/>
        </radialGradient>
      </defs>
      <rect width="${size}" height="${size}" rx="${radius}" ry="${radius}" fill="url(#tile)"/>
      <rect width="${size}" height="${size}" rx="${radius}" ry="${radius}" fill="none" stroke="rgba(255,255,255,0.10)" stroke-width="2"/>
    </svg>
  `;
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

async function main() {
  const sharp = await getSharp();
  const root = path.join(__dirname, '..');
  const assets = path.join(root, 'assets', 'images');
  const brand = path.join(root, 'brand');
  const sourceCandidates = [
    path.join(assets, 'logo_icon_transparent.png'),
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

  await composeMarkOnBrandBg(markPath, path.join(assets, 'logo_splash.png'), 1024, 0.42, sharp);
  await composeMarkOnBrandBg(markPath, path.join(assets, 'logo_icon_padded.png'), 1152, 0.46, sharp);
  await composeGlassAppIcon(markPath, path.join(brand, 'app_icon_eagle_1024.png'), 1024, sharp);

  await sharp({
    create: {
      width: 1,
      height: 1,
      channels: 4,
      background: BRAND_BG,
    },
  })
    .png()
    .toFile(path.join(assets, 'splash_background.png'));

  for (const rel of [
    'android/app/src/main/res/drawable/background.png',
    'android/app/src/main/res/drawable-v21/background.png',
  ]) {
    await sharp({
      create: {
        width: 1,
        height: 1,
        channels: 4,
        background: BRAND_BG,
      },
    })
      .png()
      .toFile(path.join(root, rel));
  }

  console.log('Brand assets ready.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
