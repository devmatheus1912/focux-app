/**
 * Reprocess official logo: strip checkerboard, remove white outer fringe, soft circular mask.
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

function isCheckerboard(r, g, b) {
  if (Math.abs(r - g) > 8 || Math.abs(g - b) > 8 || Math.abs(r - b) > 8) {
    return false;
  }
  const avg = (r + g + b) / 3;
  return avg >= 155 && avg <= 255;
}

function measureCircle(data, width, height) {
  let cx = 0;
  let cy = 0;
  let count = 0;
  let maxR = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      if (data[i + 3] > 8) {
        cx += x;
        cy += y;
        count++;
      }
    }
  }

  cx /= count;
  cy /= count;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      if (data[i + 3] > 8) {
        const d = Math.hypot(x - cx, y - cy);
        if (d > maxR) maxR = d;
      }
    }
  }

  return { cx, cy, maxR };
}

function processLogo(data, width, height) {
  for (let i = 0; i < data.length; i += 4) {
    if (isCheckerboard(data[i], data[i + 1], data[i + 2])) {
      data[i + 3] = 0;
    }
  }

  let { cx, cy, maxR } = measureCircle(data, width, height);
  let removed = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      let alpha = data[i + 3];
      if (alpha === 0) {
        data[i] = 0;
        data[i + 1] = 0;
        data[i + 2] = 0;
        continue;
      }

      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      const lum = (r + g + b) / 3;
      const sat = Math.max(r, g, b) - Math.min(r, g, b);
      const dist = Math.hypot(x - cx, y - cy);
      const outer = dist / maxR;

      if (outer > 0.84 && lum > 130 && sat < 65) {
        data[i] = 0;
        data[i + 1] = 0;
        data[i + 2] = 0;
        data[i + 3] = 0;
        removed++;
      }
    }
  }

  ({ cx, cy, maxR } = measureCircle(data, width, height));

  const inset = 1.5;
  const feather = 10;
  const cutoff = maxR - inset;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      let alpha = data[i + 3];
      if (alpha === 0) continue;

      const dist = Math.hypot(x - cx, y - cy);
      if (dist >= cutoff) {
        data[i] = 0;
        data[i + 1] = 0;
        data[i + 2] = 0;
        data[i + 3] = 0;
        removed++;
        continue;
      }

      const fadeStart = cutoff - feather;
      if (dist > fadeStart) {
        const t = (cutoff - dist) / feather;
        const nextAlpha = Math.round(alpha * t * t);
        data[i + 3] = nextAlpha;
        if (nextAlpha === 0) {
          data[i] = 0;
          data[i + 1] = 0;
          data[i + 2] = 0;
          removed++;
        }
      }
    }
  }

  let minX = width;
  let minY = height;
  let maxX = 0;
  let maxY = 0;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      if (data[i + 3] > 8) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  const pad = Math.round((maxX - minX) * 0.012);
  minX = Math.max(0, minX - pad);
  minY = Math.max(0, minY - pad);
  maxX = Math.min(width - 1, maxX + pad);
  maxY = Math.min(height - 1, maxY + pad);

  const tw = maxX - minX + 1;
  const th = maxY - minY + 1;
  const trimmed = Buffer.alloc(tw * th * 4);

  for (let y = 0; y < th; y++) {
    for (let x = 0; x < tw; x++) {
      const si = ((minY + y) * width + (minX + x)) * 4;
      const di = (y * tw + x) * 4;
      trimmed[di] = data[si];
      trimmed[di + 1] = data[si + 1];
      trimmed[di + 2] = data[si + 2];
      trimmed[di + 3] = data[si + 3];
    }
  }

  const size = Math.max(tw, th);
  console.log(`removed ${removed} pixels, trim ${tw}x${th} -> ${size}x${size}`);
  return { trimmed, tw, th, size };
}

async function main() {
  const sharp = await getSharp();
  const root = path.join(__dirname, '..');
  const assets = path.join(root, 'assets', 'images');
  const sourceCandidates = [
    path.join(
      process.env.USERPROFILE || '',
      '.cursor',
      'projects',
      'd-Projetos-Focux-Personal',
      'assets',
      'c__Users_mathe_AppData_Roaming_Cursor_User_workspaceStorage_b0ad238a091a6811f671c88c4fcf6b7a_images_Logo_Oficial-9792c166-df7e-4bf3-993e-853cb8c87dcd.png',
    ),
    path.join(assets, 'logo_official.png'),
  ];

  const source = sourceCandidates.find((p) => fs.existsSync(p));
  if (!source) {
    console.error('Logo source not found');
    process.exit(1);
  }

  const { data, info } = await sharp(source)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const { trimmed, tw, th, size } = processLogo(data, info.width, info.height);
  const squared = await sharp(trimmed, {
    raw: { width: tw, height: th, channels: 4 },
  })
    .extend({
      top: Math.floor((size - th) / 2),
      bottom: Math.ceil((size - th) / 2),
      left: Math.floor((size - tw) / 2),
      right: Math.ceil((size - tw) / 2),
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  for (const name of ['logo_official.png', 'logo_mark_transparent.png']) {
    const out = path.join(assets, name);
    await sharp(squared).toFile(out);
    console.log(`✓ ${out}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
