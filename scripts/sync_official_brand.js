/**
 * Prepara logo oficial: remove fundo preto (flood-fill), harmoniza ciano #13C2C2,
 * gera ícone, splash, favicon e app icon.
 * Usage: node scripts/sync_official_brand.js
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

const ROOT = path.join(__dirname, '..');
const RAW = path.join(ROOT, 'assets', 'images', 'logo_official_raw.png');
const OUT_OFFICIAL = path.join(ROOT, 'assets', 'images', 'logo_official.png');
const BRAND_BG = { r: 18, g: 52, b: 60, alpha: 1 };
const BRAND_CYAN = { r: 19, g: 194, b: 194 };

function isDarkBg(r, g, b) {
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  if (max < 28) return true;
  if (max < 52 && max - min < 14) return true;
  return false;
}

function harmonizeAccent(r, g, b, a) {
  if (a < 24) return [r, g, b, a];
  const spread = Math.max(r, g, b) - Math.min(r, g, b);
  if (spread < 36) return [r, g, b, a];
  const isCyan = b > 90 && g > 80 && b >= r && g >= r * 0.65;
  if (!isCyan) return [r, g, b, a];
  const t = 0.82;
  return [
    Math.round(r * (1 - t) + BRAND_CYAN.r * t),
    Math.round(g * (1 - t) + BRAND_CYAN.g * t),
    Math.round(b * (1 - t) + BRAND_CYAN.b * t),
    a,
  ];
}

function idx(x, y, width) {
  return (y * width + x) * 4;
}

function floodFillBackground(data, width, height) {
  const visited = new Uint8Array(width * height);
  const stack = [];

  const seed = (x, y) => {
    const p = y * width + x;
    if (visited[p]) return;
    const i = idx(x, y, width);
    if (!isDarkBg(data[i], data[i + 1], data[i + 2])) return;
    visited[p] = 1;
    stack.push([x, y]);
  };

  for (let x = 0; x < width; x++) {
    seed(x, 0);
    seed(x, height - 1);
  }
  for (let y = 0; y < height; y++) {
    seed(0, y);
    seed(width - 1, y);
  }

  let keyed = 0;
  while (stack.length) {
    const [x, y] = stack.pop();
    const i = idx(x, y, width);
    data[i + 3] = 0;
    data[i] = 0;
    data[i + 1] = 0;
    data[i + 2] = 0;
    keyed++;

    const neighbors = [
      [x - 1, y],
      [x + 1, y],
      [x, y - 1],
      [x, y + 1],
    ];
    for (const [nx, ny] of neighbors) {
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
      const p = ny * width + nx;
      if (visited[p]) continue;
      const ni = idx(nx, ny, width);
      if (!isDarkBg(data[ni], data[ni + 1], data[ni + 2])) continue;
      visited[p] = 1;
      stack.push([nx, ny]);
    }
  }
  return keyed;
}

function defringeEdges(data, width, height, passes = 4) {
  let removed = 0;
  for (let pass = 0; pass < passes; pass++) {
    const clone = Buffer.from(data);
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const i = idx(x, y, width);
        if (clone[i + 3] === 0) continue;

        let nearTransparent = false;
        for (let dy = -1; dy <= 1 && !nearTransparent; dy++) {
          for (let dx = -1; dx <= 1 && !nearTransparent; dx++) {
            if (dx === 0 && dy === 0) continue;
            const nx = x + dx;
            const ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
              nearTransparent = true;
              continue;
            }
            if (clone[idx(nx, ny, width) + 3] === 0) nearTransparent = true;
          }
        }
        if (!nearTransparent) continue;

        const r = clone[i];
        const g = clone[i + 1];
        const b = clone[i + 2];
        if (isDarkBg(r, g, b) || Math.max(r, g, b) < 64) {
          data[i + 3] = 0;
          data[i] = 0;
          data[i + 1] = 0;
          data[i + 2] = 0;
          removed++;
        }
      }
    }
  }
  return removed;
}

function removeStrayDarkMatte(data) {
  let removed = 0;
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0) continue;
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    const max = Math.max(r, g, b);
    const spread = max - Math.min(r, g, b);
    const isWhite = max > 175;
    const isCyan = b > 95 && g > 75 && spread > 24;
    if (isWhite || isCyan) continue;
    if (isDarkBg(r, g, b) || (max < 68 && spread < 24)) {
      data[i + 3] = 0;
      data[i] = 0;
      data[i + 1] = 0;
      data[i + 2] = 0;
      removed++;
    }
  }
  return removed;
}

function cleanAlphaGhosts(data) {
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0) {
      data[i] = 0;
      data[i + 1] = 0;
      data[i + 2] = 0;
    }
  }
}

function isContentPixel(r, g, b, a) {
  if (a < 48) return false;
  const max = Math.max(r, g, b);
  const spread = max - Math.min(r, g, b);
  if (max > 175) return true;
  if (b > 95 && g > 75 && spread > 24) return true;
  return false;
}

function cropToOpaqueContent(data, width, height) {
  let minX = width;
  let minY = height;
  let maxX = 0;
  let maxY = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = idx(x, y, width);
      if (!isContentPixel(data[i], data[i + 1], data[i + 2], data[i + 3])) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  if (maxX <= minX || maxY <= minY) {
    return { data, width, height, cropped: false };
  }

  const pad = 2;
  minX = Math.max(0, minX - pad);
  minY = Math.max(0, minY - pad);
  maxX = Math.min(width - 1, maxX + pad);
  maxY = Math.min(height - 1, maxY + pad);
  const outW = maxX - minX + 1;
  const outH = maxY - minY + 1;
  const out = Buffer.alloc(outW * outH * 4);

  for (let y = 0; y < outH; y++) {
    for (let x = 0; x < outW; x++) {
      const si = idx(x + minX, y + minY, width);
      const di = (y * outW + x) * 4;
      out[di] = data[si];
      out[di + 1] = data[si + 1];
      out[di + 2] = data[si + 2];
      out[di + 3] = data[si + 3];
    }
  }

  return { data: out, width: outW, height: outH, cropped: true };
}

function isSymbolPixel(r, g, b, a) {
  if (a < 48) return false;
  const max = Math.max(r, g, b);
  const spread = max - Math.min(r, g, b);
  return b > 95 && g > 75 && spread > 24;
}

function cropToSymbolContent(data, width, height) {
  let minX = width;
  let minY = height;
  let maxX = 0;
  let maxY = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = idx(x, y, width);
      if (!isSymbolPixel(data[i], data[i + 1], data[i + 2], data[i + 3])) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  if (maxX <= minX || maxY <= minY) {
    return { data, width, height, cropped: false };
  }

  const pad = 2;
  minX = Math.max(0, minX - pad);
  minY = Math.max(0, minY - pad);
  maxX = Math.min(width - 1, maxX + pad);
  maxY = Math.min(height - 1, maxY + pad);
  const outW = maxX - minX + 1;
  const outH = maxY - minY + 1;
  const out = Buffer.alloc(outW * outH * 4);

  for (let y = 0; y < outH; y++) {
    for (let x = 0; x < outW; x++) {
      const si = idx(x + minX, y + minY, width);
      const di = (y * outW + x) * 4;
      out[di] = data[si];
      out[di + 1] = data[si + 1];
      out[di + 2] = data[si + 2];
      out[di + 3] = data[si + 3];
    }
  }

  return { data: out, width: outW, height: outH, cropped: true };
}

function findSymbolBottomY(data, width, height) {
  const rows = [];
  for (let y = 0; y < height; y++) {
    let cyan = 0;
    for (let x = 0; x < width; x++) {
      const i = idx(x, y, width);
      if (!isSymbolPixel(data[i], data[i + 1], data[i + 2], data[i + 3])) continue;
      cyan++;
    }
    rows.push({ y, cyan });
  }

  const searchStart = Math.round(height * 0.34);
  const searchEnd = Math.round(height * 0.58);
  let bestGap = { start: -1, size: 0 };

  for (let y = searchStart; y < searchEnd; y++) {
    let gapLen = 0;
    while (y + gapLen < searchEnd && rows[y + gapLen].cyan < 8) {
      gapLen++;
    }
    if (gapLen >= 12 && gapLen > bestGap.size) {
      bestGap = { start: y, size: gapLen };
    }
    if (gapLen > 0) y += gapLen - 1;
  }

  if (bestGap.start > 0) {
    for (let y = bestGap.start - 1; y >= 0; y--) {
      if (rows[y].cyan > 24) return y + 12;
    }
  }

  return Math.round(height * 0.48);
}

async function writeSymbolIcon(sharp, officialPath, outputPath) {
  const { data, info } = await sharp(officialPath)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const symbolBottom = findSymbolBottomY(data, info.width, info.height);
  const extractH = Math.max(1, Math.min(info.height - 1, symbolBottom));

  const extracted = Buffer.alloc(info.width * extractH * 4);
  for (let y = 0; y < extractH; y++) {
    const src = y * info.width * 4;
    const dst = y * info.width * 4;
    data.copy(extracted, dst, src, src + info.width * 4);
  }

  const cropped = cropToSymbolContent(extracted, info.width, extractH);
  const pad = Math.max(8, Math.round(Math.max(cropped.width, cropped.height) * 0.04));
  const paddedW = cropped.width + pad * 2;
  const paddedH = cropped.height + pad * 2;
  const padded = Buffer.alloc(paddedW * paddedH * 4);

  for (let y = 0; y < cropped.height; y++) {
    for (let x = 0; x < cropped.width; x++) {
      const si = (y * cropped.width + x) * 4;
      const di = ((y + pad) * paddedW + (x + pad)) * 4;
      padded[di] = cropped.data[si];
      padded[di + 1] = cropped.data[si + 1];
      padded[di + 2] = cropped.data[si + 2];
      padded[di + 3] = cropped.data[si + 3];
    }
  }

  await sharp(padded, {
    raw: { width: paddedW, height: paddedH, channels: 4 },
  })
    .png()
    .toFile(outputPath);

  console.log(
    `✓ logo_icon.png (${paddedW}x${paddedH}, symbol rows 0-${symbolBottom})`,
  );
}

async function processTransparentLogo(inputPath, outputPath, sharp) {
  const { data, info } = await sharp(inputPath)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const keyed = floodFillBackground(data, info.width, info.height);
  const defringed = defringeEdges(data, info.width, info.height);
  const matte = removeStrayDarkMatte(data);

  let tinted = 0;
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0) continue;
    let r = data[i];
    let g = data[i + 1];
    let b = data[i + 2];
    let a = data[i + 3];
    [r, g, b, a] = harmonizeAccent(r, g, b, a);
    if (r !== data[i] || g !== data[i + 1] || b !== data[i + 2]) tinted++;
    data[i] = r;
    data[i + 1] = g;
    data[i + 2] = b;
    data[i + 3] = a;
  }

  cleanAlphaGhosts(data);

  const cropped = cropToOpaqueContent(data, info.width, info.height);
  const outData = cropped.data;
  const outW = cropped.width;
  const outH = cropped.height;

  await sharp(outData, {
    raw: { width: outW, height: outH, channels: 4 },
  })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(outputPath);

  console.log(
    `✓ transparent logo: ${path.relative(ROOT, outputPath)} (${outW}x${outH}, fill ${keyed}, defringe ${defringed}, matte ${matte}, tint ${tinted})`,
  );

  return sharp(outputPath).metadata();
}

async function main() {
  if (!fs.existsSync(RAW)) {
    console.error('Missing', RAW);
    process.exit(1);
  }

  const sharp = await getSharp();
  const assets = path.join(ROOT, 'assets', 'images');
  const brand = path.join(ROOT, 'brand');
  const web = path.join(ROOT, 'web');
  const webIcons = path.join(web, 'icons');

  for (const dir of [assets, brand, webIcons]) {
    fs.mkdirSync(dir, { recursive: true });
  }

  await processTransparentLogo(RAW, OUT_OFFICIAL, sharp);
  await writeSymbolIcon(
    sharp,
    OUT_OFFICIAL,
    path.join(assets, 'logo_icon.png'),
  );

  // Splash Flutter / Android clássico — lockup completo com margem transparente.
  await sharp(OUT_OFFICIAL)
    .resize(520, null, { fit: 'inside' })
    .extend({
      top: 48,
      bottom: 48,
      left: 64,
      right: 64,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toFile(path.join(assets, 'logo_splash.png'));
  console.log('✓ logo_splash.png');

  // Android 12 — símbolo completo com margem para máscara circular (~60%).
  const splashIconInner = 300;
  const iconOnly = await sharp(path.join(assets, 'logo_icon.png'))
    .resize(splashIconInner, splashIconInner, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  await sharp({
    create: {
      width: 512,
      height: 512,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite([{ input: iconOnly, gravity: 'centre' }])
    .png()
    .toFile(path.join(assets, 'logo_splash_icon.png'));
  console.log('✓ logo_splash_icon.png');

  const iconBuf = await sharp(path.join(assets, 'logo_icon.png'))
    .resize(680, 680, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  await sharp({
    create: {
      width: 1024,
      height: 1024,
      channels: 4,
      background: BRAND_BG,
    },
  })
    .composite([{ input: iconBuf, gravity: 'centre' }])
    .png()
    .toFile(path.join(brand, 'app_icon_eagle_1024.png'));
  console.log('✓ brand/app_icon_eagle_1024.png');

  const sizes = [
    { file: path.join(web, 'favicon.png'), size: 48 },
    { file: path.join(webIcons, 'Icon-192.png'), size: 192 },
    { file: path.join(webIcons, 'Icon-512.png'), size: 512 },
    { file: path.join(webIcons, 'Icon-maskable-192.png'), size: 192 },
    { file: path.join(webIcons, 'Icon-maskable-512.png'), size: 512 },
  ];

  for (const { file, size } of sizes) {
    const pad = Math.round(size * 0.14);
    const inner = size - pad * 2;
    const resized = await sharp(path.join(assets, 'logo_icon.png'))
      .resize(inner, inner, {
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
      .composite([{ input: resized, gravity: 'centre' }])
      .png()
      .toFile(file);
    console.log('✓', path.relative(ROOT, file));
  }

  console.log('\nDone. Run: dart run flutter_launcher_icons && dart run flutter_native_splash:create');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
