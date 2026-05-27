/**
 * Post flutter_native_splash patch:
 * - flat #0B0E14 background on android drawables (matches Flutter AuthShell)
 * - keep centered splash logo on launch_background (pre-Android 12)
 * - Android 12+: keep android12splash from flutter_native_splash
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

const LAUNCH_BACKGROUND = `<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:gravity="fill" android:src="@drawable/background"/>
    </item>
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash"/>
    </item>
</layer-list>
`;

const SPLASH_COLOR = '#0B0E14';
const FLAT_RGB = { r: 11, g: 14, b: 20 };

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

async function flatBackgroundPng(sharp, size = 512) {
  return sharp({
    create: {
      width: size,
      height: size,
      channels: 3,
      background: FLAT_RGB,
    },
  })
    .png()
    .toBuffer();
}

async function main() {
  const sharp = await getSharp();
  const root = path.join(__dirname, '..');
  const resDir = path.join(root, 'android', 'app', 'src', 'main', 'res');
  const flatBuffer = await flatBackgroundPng(sharp);

  const targets = [];
  for (const entry of fs.readdirSync(resDir, { withFileTypes: true })) {
    if (!entry.isDirectory() || !entry.name.startsWith('drawable')) continue;
    const bg = path.join(resDir, entry.name, 'background.png');
    if (fs.existsSync(bg)) targets.push(bg);
  }

  for (const target of targets) {
    await sharp(flatBuffer).toFile(target);
  }

  patchLaunchBackground(root);
  patchAndroid12Styles(root);

  console.log(`✓ patched ${targets.length} android background drawables with flat ${SPLASH_COLOR}`);
  console.log('✓ launch_background keeps centered splash + android12splash icon');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
