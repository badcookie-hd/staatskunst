import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const capitals = data.features.filter(f => f.properties.adm0cap === 1).map(f => ({
  code: f.properties.adm0_a3, name: f.properties.name, point: f.geometry.coordinates,
}));
const target = path.join(path.dirname(fileURLToPath(import.meta.url)), '../data/capitals.json');
fs.writeFileSync(target, JSON.stringify({
  source: 'Natural Earth populated places, public domain; modern reference capitals', capitals,
}, null, 2) + '\n');
console.log(`${capitals.length} reference capitals`);
