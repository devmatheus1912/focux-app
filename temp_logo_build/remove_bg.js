const fs = require('fs');
const { createCanvas, loadImage } = require('canvas');

async function processImage() {
  const iconPath = 'C:\\Users\\mathe\\.gemini\\antigravity\\brain\\e8385cee-4d68-4b1a-b0e1-d645c7ee8d38\\media__1776963813907.jpg';
  const img = await loadImage(iconPath);
  
  const iconSize = img.height;
  
  const iconCanvas = createCanvas(iconSize, iconSize);
  const iCtx = iconCanvas.getContext('2d');
  iCtx.drawImage(img, 0, 0);
  
  const imgData = iCtx.getImageData(0, 0, iconSize, iconSize);
  const data = imgData.data;
  
  // Sample top-left for background color
  const bgR = data[0], bgG = data[1], bgB = data[2];
  
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i], g = data[i+1], b = data[i+2];
    
    // Distance from the exact top-left background color
    const dist = Math.sqrt(Math.pow(r - bgR, 2) + Math.pow(g - bgG, 2) + Math.pow(b - bgB, 2));
    
    let alpha = 255;
    
    // HARD THRESHOLD: If color is very close to background (JPEG noise), make it 100% transparent.
    // This absolutely eliminates the dark square bounding box!
    if (dist < 15) {
        alpha = 0;
    } else {
        // Smooth transition for the glowing edges of the F
        alpha = (dist - 15) * 6; 
        if (alpha > 255) alpha = 255;
    }
    
    // As a secondary measure to guarantee the corners of the square are invisible,
    // apply a soft radial fade at the very edges of the image bounding box.
    const cx = iconSize / 2;
    const cy = iconSize / 2;
    const x = (i / 4) % iconSize;
    const y = Math.floor((i / 4) / iconSize);
    const distFromCenter = Math.sqrt(Math.pow(x - cx, 2) + Math.pow(y - cy, 2));
    
    const maxRadius = iconSize * 0.45; // 90% of the image size
    if (distFromCenter > maxRadius) {
        const fadeRadius = iconSize * 0.05;
        const excess = distFromCenter - maxRadius;
        const radialAlpha = Math.max(0, 255 - (excess * (255 / fadeRadius)));
        alpha = Math.min(alpha, radialAlpha);
    }

    data[i+3] = alpha;
    
    // Do NOT boost RGB values. Keep the original F colors intact.
  }
  
  iCtx.putImageData(imgData, 0, 0);
  
  const iconOutPath = '../assets/images/logo_icon.png';
  const out1 = fs.createWriteStream(iconOutPath);
  iconCanvas.createPNGStream().pipe(out1);
  
  console.log('Generated perfectly transparent icon with ZERO background noise!');
}

processImage().catch(console.error);
