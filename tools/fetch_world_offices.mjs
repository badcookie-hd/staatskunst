// Usage: node tools/fetch_world_offices.mjs 1936|2026 cache-directory
// Run build_world_profiles.mjs first to populate country and office entity caches.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const year=Number(process.argv[2]),cache=process.argv[3];
if(![1936,2026].includes(year))throw Error('Supported years: 1936, 2026');
const atlas=JSON.parse(fs.readFileSync('data/world_profiles.json'));
const countryIds=[...new Set(atlas.countries.flatMap(c=>[c.qid,c.profiles[year].entity]))];
const officeIds=[...new Set(countryIds.flatMap(id=>{
  const e=JSON.parse(fs.readFileSync(path.join(cache,id+'.json')));
  return ['P1906','P1313'].flatMap(p=>(e.claims[p]??[]).filter(s=>s.rank!=='deprecated').map(s=>s.mainsnak.datavalue?.value?.id).filter(Boolean));
}))];
const result=[];
for(let i=0;i<officeIds.length;i+=25){
  const query=`SELECT ?office ?person ?start ?end WHERE { VALUES ?office { ${officeIds.slice(i,i+25).map(id=>'wd:'+id).join(' ')} } ?person p:P39 ?s . ?s ps:P39 ?office; pq:P580 ?start . FILTER NOT EXISTS { ?s wikibase:rank wikibase:DeprecatedRank } OPTIONAL { ?s pq:P582 ?end } FILTER(?start <= "${year}-01-01T00:00:00Z"^^xsd:dateTime && (!BOUND(?end) || ?end > "${year}-01-01T00:00:00Z"^^xsd:dateTime)) }`;
  const file=path.join(cache,'query-'+crypto.createHash('sha256').update(query).digest('hex')+'.json');
  if(fs.existsSync(file)){result.push(...JSON.parse(fs.readFileSync(file)));continue;}
  let rows;
  for(let attempt=0;attempt<3;attempt++)try {
    const response=await fetch('https://query.wikidata.org/sparql?'+new URLSearchParams({query,format:'json'}),{headers:{'User-Agent':'Staatskunst/0.7 (https://github.com/badcookie-hd/staatskunst)'},signal:AbortSignal.timeout(60000)});
    if(!response.ok)throw Error('SPARQL '+response.status);
    rows=(await response.json()).results.bindings.map(x=>({office:x.office.value.split('/').at(-1),person:x.person.value.split('/').at(-1),start:x.start.value.slice(0,10),end:x.end?.value?.slice(0,10)??''}));break;
  }catch(error){if(attempt===2)throw error;await new Promise(r=>setTimeout(r,3000));}
  fs.writeFileSync(file,JSON.stringify(rows));result.push(...rows);
  console.log(year,'offices',i,'/',officeIds.length);
}
fs.writeFileSync(path.join(cache,year===1936?'historical-offices.json':'modern-offices.json'),JSON.stringify(result,null,2));
