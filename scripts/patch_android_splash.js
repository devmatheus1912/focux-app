/**
 * Post flutter_native_splash patch:
 * - mesh PNG on android background drawables
 * - remove centered logo layer from launch_background
 * - Android 12+: blank animated icon (same color as background)
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

const LAUNCH_BACKGROUND = `<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:gravity="fill" android:src="@drawable/background"/>
    </item>
</layer-list>
`;

const SPLASH_COLOR = '#12343C';

function patchLaunchBackground(root) {
  const targets = [
    path.join(root, 'android', 'app', 'src', 'main', 'res', 'drawable', 'launch_background.xml'),
    path.join(root, 'android', 'app', 'src', 'main', 'res', 'drawable-v21', 'launch_background.xml'),
  ];

  for (const target of targets) {
    if (!fs.existsSync(target)) continue;
    fs.writeFileSync(target, LAUNCH_BACKGROUND);
  }
}

function patchAndroid12Styles(root) {
  const styleFiles = [
    path.join(root, 'android', 'app', 'src', 'main', 'res', 'values-v31', 'styles.xml'),
    path.join(root, 'android', 'app', 'src', 'main', 'res', 'values-night-v31', 'styles.xml'),
  ];

  for (const styleFile of styleFiles) {
    if (!fs.existsSync(styleFile)) continue;
    let content = fs.readFileSync(styleFile, 'utf8');
    content = content.replace(
      /(<item name="android:windowSplashScreenBackground">)[^<]+(<\/item>)/,
      `$1${SPLASH_COLOR}$2`,
    );
    content = content.replace(
      /(<item name="android:windowSplashScreenIconBackgroundColor">)[^<]+(<\/item>)/,
      `$1${SPLASH_COLOR}$2`,
    );
    if (!content.includes('android:windowSplashScreenAnimatedIcon')) {
      content = content.replace(
        /(<item name="android:windowSplashScreenBackground">#12343C<\/item>)/,
        `$1\n        <item name="android:windowSplashScreenAnimatedIcon">@drawable/android12splash</item>`,
      );
    }
    fs.writeFileSync(styleFile, content);
  }
}

async function removeLegacySplashLayers(resDir) {
  for (const entry of fs.readdirSync(resDir, { withFileTypes: true })) {
    if (!entry.isDirectory() || !entry.name.startsWith('drawable')) continue;
    const splash = path.join(resDir, entry.name, 'splash.png');
    if (fs.existsSync(splash)) fs.unlinkSync(splash);
  }
}

async function main() {
  const sharp = await getSharp();
  const root = path.join(__dirname, '..');
  const resDir = path.join(root, 'android', 'app', 'src', 'main', 'res');
  const meshBuffer = await sharp(Buffer.from(meshBackgroundSvg(512, 512)))
    .png()
    .toBuffer();

  const targets = [];
  for (const entry of fs.readdirSync(resDir, { withFileTypes: true })) {
    if (!entry.isDirectory() || !entry.name.startsWith('drawable')) continue;
    const bg = path.join(resDir, entry.name, 'background.png');
    if (fs.existsSync(bg)) targets.push(bg);
  }

  for (const target of targets) {
    await sharp(meshBuffer).toFile(target);
  }

  patchLaunchBackground(root);
  patchAndroid12Styles(root);
  removeLegacySplashLayers(resDir);

  console.log(`✓ patched ${targets.length} android background drawables with mesh`);
  console.log('✓ removed legacy splash.png layers (kept android12splash icon)');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
