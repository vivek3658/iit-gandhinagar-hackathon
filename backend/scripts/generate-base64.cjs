const fs = require('fs');
const path = require('path');

const glbPath = path.join(__dirname, '..', 'docs', 'assets', 'sparrow.glb');
const outPath = path.join(__dirname, '..', 'docs', 'assets', 'sparrow-data.js');

if (fs.existsSync(glbPath)) {
  const b64 = fs.readFileSync(glbPath).toString('base64');
  fs.writeFileSync(outPath, `window.SPARROW_GLB_DATA = "data:model/gltf-binary;base64,${b64}";\n`);
  console.log(`Generated ${outPath} successfully (${b64.length} bytes base64)`);
} else {
  console.error(`File not found: ${glbPath}`);
}
