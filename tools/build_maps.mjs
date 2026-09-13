// node tools/build_maps.mjs path/to/ne_110m_admin_0_countries.geojson
// Natural Earth: public domain. Historical edits are original schematic geometry.
import fs from 'node:fs';
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const lookup = Object.fromEntries(source.features.map(f => [f.properties.ADM0_A3, f]));
const bounds = [-12, 35, 34, 72];
function clip(ring) {
  let points = ring.slice(0, -1);
  for (const [axis, edge, sign] of [[0,-12,1],[0,35,-1],[1,34,1],[1,72,-1]]) {
    const result = [];
    for (let i=0; i<points.length; i++) {
      const a=points[i], b=points[(i+1)%points.length];
      const ia=(a[axis]-edge)*sign>=0, ib=(b[axis]-edge)*sign>=0;
      if(ia) result.push(a);
      if(ia!==ib) {const t=(edge-a[axis])/(b[axis]-a[axis]); result.push([a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1])]);}
    }
    points=result;
  }
  return points.map(p=>p.map(v=>Math.round(v*10000)/10000));
}
function rings(code) {
  const g=lookup[code].geometry;
  return (g.type==='Polygon'?[g.coordinates]:g.coordinates).map(p=>clip(p[0])).filter(p=>p.length>=3);
}
const specs = [
  ['DEU','Deutschland',[10.4,51.1],58,66,83,52],
  ['FRA','Frankreich',[2,46.5],52,62,71,56],
  ['GBR','Vereinigtes Königreich',[-2.8,54.4],60,60,74,48],
  ['ITA','Italien',[12.4,42.7],38,55,59,46],
  ['ESP','Spanien',[-3.6,40.1],29,48,54,39],
  ['POL','Polen',[19.3,52],32,48,58,58],
  ['AUT','Österreich',[13.7,47.5],25,20,41,18],
  ['CZE','Tschechien',[15.4,49.8],37,32,44,24],
  ['HUN','Ungarn',[19.3,47.1],23,25,33,24],
  ['BEL','Belgien',[4.5,50.6],30,25,43,20],
  ['NLD','Niederlande',[5.5,52.4],32,24,51,22],
  ['CHE','Schweiz',[8.2,46.7],29,23,49,20],
  ['PRT','Portugal',[-8,39.6],21,22,34,19],
  ['DNK','Dänemark',[9.5,56.1],23,17,40,18],
  ['SWE','Schweden',[16,62.1],32,27,49,26],
  ['NOR','Norwegen',[8.2,61.1],24,19,46,22],
  ['SVK','Slowakei',[19.5,48.8],20,20,31,18]
];
const linksModern = [[0,1],[0,6],[0,7],[0,9],[0,10],[0,11],[0,13],[0,5],[1,3],[1,4],[1,9],[1,11],[3,6],[3,11],[4,12],[5,7],[5,16],[6,7],[6,8],[6,11],[6,16],[7,16],[8,16],[9,10],[14,15]];
// Maritime access is explicit; it does not imply a land border.
const seaLinks = [[2,1],[2,10],[2,15],[13,14],[13,15]];
const historicEast = [[17.62,54.85],[17.7,53.8],[16.7,53.1],[16.2,52.4],[15.9,51.9],[17.3,51.2],[18.5,50.9],[18.9,50.3],[18.853144,49.49623]];
const germanModern = lookup.DEU.geometry.coordinates[0];
const czech = lookup.CZE.geometry.coordinates[0];
const german1936 = [...germanModern.slice(7,-1),[14.119686,53.757029],[14.8029,54.050706],[16.363477,54.513159],...historicEast,...czech.slice(0,9).reverse(),germanModern[7]];
const prussia = [[19.66,54.426],[20.15,54.95],[21.25,55.25],[22.8,54.4],[22.9,53.7],[21,53.4],[19.2,53.5],[19.66,54.426]];
const poland1936 = [...historicEast.slice().reverse(),[18.25,54.77],[18.45,54.55],[19.2,53.5],[21,53.4],[22.9,53.7],[24.8,55.5],[26.3,55.7],[28.2,54.8],[27.5,53],[27,51.5],[26.4,50.4],[26.5,48.4],[24.5,47.9],[22.558138,49.085738],...lookup.POL.geometry.coordinates[0].slice(13,20),historicEast.at(-1)];
const colors=['719ea9','7f9dc4','b08091','8baa87','c5a46f','b59083','ac8893','8ea89c','a598b7','c6b58c','c9a081','a4b8b3','86a5a0','ad99c4','9eb486','869fb8','c3ad7b'];
const data={bounds,background:source.features.flatMap(f=>{const g=f.geometry;return(g.type==='Polygon'?[g.coordinates]:g.coordinates).map(p=>clip(p[0])).filter(p=>p.length>=3);}),scenarios:{}};
for(const year of [1936,2026]) {
  const countries=specs.slice(0,year===1936?16:17).map((s,id)=>{
    const [code,name,center,oldIndustry,oldArmy,newIndustry,newArmy]=s;
    const authoritarian = year===1936 && [0,3,5,6,8,12].includes(id);
    const ruling = year===1936?([0,3].includes(id)?3:([1,2,4,5,6,8,12].includes(id)?2:([14,15,13].includes(id)?1:0))):([0,3,8].includes(id)?2:([2,4,13,15].includes(id)?1:0));
    const support=[24,25,29,22]; support[ruling]+=15; const sum=support.reduce((a,b)=>a+b); const normalized=support.map(x=>x/sum*100);
    return {id,code:year===1936&&id===7?'CSK':code,name:year===1936&&id===0?'Deutsches Reich':year===1936&&id===7?'Tschechoslowakei':name,
      center:year===1936&&id===7?[18,48.8]:center, color:colors[id], polygons:rings(code),neighbors:[],sea_neighbors:[],
      industry:year===1936?oldIndustry:newIndustry,army:year===1936?oldArmy:newArmy,
      quality:year===1936?(id<3?1.15:1):([0,1,2,14].includes(id)?2.2:1.9),money:year===1936?420:620,
      stability:year===1936?(id===4?46:62):72,influence:100,ruling,support:normalized,democratic:!authoritarian};
  });
  if(year===1936) {
    countries[0].polygons=[clip(german1936),clip(prussia)];
    countries[5].polygons=[clip(poland1936)];
    // Czech and Slovak geometries are merged when rendered by Godot.
    countries[7].polygons=[...rings('CZE'),...rings('SVK'),clip([[22.15,48.4],[22.558138,49.085738],[23.2,48.95],[24.5,47.9],[23.5,47.95],[22.15,48.4]])];
    countries[3].polygons.push(clip([[13.6,45.65],[13.7,46.4],[14.4,46.1],[14.5,45.5],[14.1,44.8],[13.6,45.65]]));
  }
  let links=linksModern;
  if(year===1936) links=linksModern.map(([a,b])=>[a===16?7:a,b===16?7:b]).filter(([a,b])=>a!==b);
  for(const [a,b] of links) {if(!countries[a].neighbors.includes(b))countries[a].neighbors.push(b);if(!countries[b].neighbors.includes(a))countries[b].neighbors.push(a);}
  for(const [a,b] of seaLinks) {countries[a].sea_neighbors.push(b);countries[b].sea_neighbors.push(a);}
  data.scenarios[year]={year,countries,title:year===1936?'Europa am Scheideweg':'Europa der Gegenwart',
    description:year===1936?'16 Staaten · Aufrüstung, fragile Demokratien und Diktaturen. Österreich und die Tschechoslowakei sind eigenständig.':'17 Staaten · Moderne Industrie und Technologie. Tschechien und die Slowakei sind eigenständige Staaten.',
    parties:year===1936?['Liberale','Sozialisten','Konservative','Faschisten']:['Liberale','Sozialdemokraten','Konservative','Nationalkonservative']};
}
fs.mkdirSync('data',{recursive:true});
fs.writeFileSync('data/scenarios.json',JSON.stringify(data));
console.log('Generated scenarios:',Object.entries(data.scenarios).map(([y,s])=>`${y}: ${s.countries.length} countries`).join(', '));
