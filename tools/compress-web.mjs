import fs from 'node:fs';
import path from 'node:path';
import {gzipSync} from 'node:zlib';
import {fileURLToPath} from 'node:url';
const dir=fileURLToPath(new URL('../web/game/',import.meta.url));
for(const name of fs.readdirSync(dir)) {
  if(!/\.(wasm|pck|js)$/.test(name))continue;
  const file=path.join(dir,name),data=fs.readFileSync(file),compressed=gzipSync(data,{level:9});
  fs.writeFileSync(file+'.gz',compressed);
  console.log(`${name}: ${(data.length/1048576).toFixed(2)} MB → ${(compressed.length/1048576).toFixed(2)} MB`);
}
