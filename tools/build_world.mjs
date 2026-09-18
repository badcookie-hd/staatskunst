// node tools/build_world.mjs path/to/ne_110m_admin_0_countries.geojson
// Natural Earth public-domain reference geography; campaign geometry is separate.
import fs from 'node:fs';
const source=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
const countries=source.features.map(f=>({code:f.properties.ADM0_A3,name:f.properties.NAME_DE??f.properties.ADMIN,center:[f.properties.LABEL_X??0,f.properties.LABEL_Y??0],polygons:(f.geometry.type==='Polygon'?[f.geometry.coordinates]:f.geometry.coordinates).map(p=>p[0].slice(0,-1).map(v=>v.map(x=>Math.round(x*10000)/10000))).filter(p=>p.length>=3)}));
fs.writeFileSync('data/world.json',JSON.stringify({source:'Natural Earth 1:110m; public domain',countries}));
console.log('World reference regions:',countries.length);
