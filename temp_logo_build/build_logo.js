const fs = require('fs');
const { createCanvas, loadImage } = require('canvas');

async function main() {
  const iconPath = 'C:\\Users\\mathe\\.gemini\\antigravity\\brain\\e8385cee-4d68-4b1a-b0e1-d645c7ee8d38\\media__1776963813907.jpg';
  const img = await loadImage(iconPath);
  
  const iconSize = img.height; // assuming square
  
  // Calculate final canvas size
  const canvasWidth = Math.floor(iconSize * 3.5);
  const canvasHeight = iconSize;
  const canvas = createCanvas(canvasWidth, canvasHeight);
  const ctx = canvas.getContext('2d');

  // Fill background
  // Sample background color from top-left pixel
  const tempCanvas = createCanvas(1, 1);
  const tempCtx = tempCanvas.getContext('2d');
  tempCtx.drawImage(img, 0, 0, 1, 1, 0, 0, 1, 1);
  const bgPixel = tempCtx.getImageData(0, 0, 1, 1).data;
  const bgColor = `rgba(${bgPixel[0]}, ${bgPixel[1]}, ${bgPixel[2]}, ${bgPixel[3] / 255})`;
  
  ctx.fillStyle = bgColor;
  ctx.fillRect(0, 0, canvasWidth, canvasHeight);

  // Draw the icon
  ctx.drawImage(img, 0, 0);

  // Draw text
  const startX = iconSize; // Right after the square icon image
  const centerY = canvasHeight / 2;
  
  ctx.fillStyle = '#FFFFFF';
  
  // Title part 1: FOCUX
  const fontSizeFocux = Math.floor(iconSize * 0.18);
  ctx.font = `bold ${fontSizeFocux}px sans-serif`;
  ctx.textBaseline = 'alphabetic';
  ctx.fillText('FOCUX', startX, centerY + (fontSizeFocux * 0.1));
  
  const focuxWidth = ctx.measureText('FOCUX').width;
  
  // Title part 2: PERSONAL
  const fontSizePersonal = Math.floor(iconSize * 0.18);
  ctx.font = `normal ${fontSizePersonal}px sans-serif`;
  const personalText = ' PERSONAL';
  ctx.fillText(personalText, startX + focuxWidth, centerY + (fontSizeFocux * 0.1));

  // Tagline
  const fontSizeTagline = Math.floor(iconSize * 0.05);
  ctx.font = `normal ${fontSizeTagline}px sans-serif`;
  ctx.fillStyle = '#A0A5B5';
  ctx.fillText('Treine com dados. Evolua com inteligência.', startX, centerY + (fontSizeFocux * 0.1) + fontSizeTagline * 2);

  const outPath = '../LOGOFOCUXPERSONAL_FULL.png';
  const out = fs.createWriteStream(outPath);
  const stream = canvas.createPNGStream();
  stream.pipe(out);
  
  out.on('finish', () => {
    console.log('Logo generated at ' + outPath);
  });
}

main().catch(console.error);
