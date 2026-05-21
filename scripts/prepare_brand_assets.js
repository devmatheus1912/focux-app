/**
 * Prepare Eagle brand assets:
 * - strip fake checkerboard transparency from logo exports
 * - build padded splash/icon surfaces on #080C10
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
  if (Math.abs(r - g) > 8 || Math.abs(g - b) > 8 || Math.abs(r - b) > 8) {
    return false;
  }
  return (r >= 188 && r <= 255) || (r >= 150 && r <= 190);
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

async function composeOnBrandBg(inputPath, outputPath, size, iconScale, sharp) {
  const trimmed = await sharp(inputPath)
    .trim({ threshold: 12 })
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

async function main() {
  const sharp = await getSharp();
  const root = path.join(__dirname, '..');
  const assets = path.join(root, 'assets', 'images');
  const brand = path.join(root, 'brand');
  const glassSrc = path.join(assets, 'logo_icon.png');
  const checkerSrc = path.join(assets, 'logo_icon_transparent.png');

  if (!fs.existsSync(glassSrc)) {
    console.error('Missing logo_icon.png');
    process.exit(1);
  }

  await stripCheckerboard(
    checkerSrc,
    path.join(assets, 'logo_mark_transparent.png'),
    sharp,
  );

  await composeOnBrandBg(
    glassSrc,
    path.join(assets, 'logo_icon_padded.png'),
    1152,
    0.62,
    sharp,
  );

  await composeOnBrandBg(
    glassSrc,
    path.join(assets, 'logo_splash.png'),
    1024,
    0.56,
    sharp,
  );

  await composeOnBrandBg(
    glassSrc,
    path.join(brand, 'app_icon_eagle_1024.png'),
    1024,
    0.78,
    sharp,
  );

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
