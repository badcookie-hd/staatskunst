// Build an offline political reference atlas from Natural Earth and dated Wikidata statements.
// Run from the repository: node tools/build_world_profiles.mjs input.geojson cache-directory
import fs from 'node:fs';
import path from 'node:path';
const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const cache = process.argv[3];
const overrides=JSON.parse(fs.readFileSync('data/world_overrides.json'));
fs.mkdirSync(cache, {recursive:true});
const entities = {};
const UA = 'Staatskunst/0.7 (https://github.com/badcookie-hd/staatskunst; offline reference atlas)';
async function fetchEntities(ids) {
  const unique = [...new Set(ids)].filter(id => /^Q\d+$/.test(id));
  const missing = unique.filter(id => {
    const file = path.join(cache,id+'.json');
    if (fs.existsSync(file)) { entities[id]=JSON.parse(fs.readFileSync(file)); return Object.keys(entities[id].labels??{}).length===0; }
    return !entities[id];
  });
  for(let i=0;i<missing.length;i+=30) {
    const batch=missing.slice(i,i+30);
    const params=new URLSearchParams({action:'wbgetentities',ids:batch.join('|'),props:'claims|labels|descriptions',languages:'de|en|mul',format:'json'});
    let result;
    for(let attempt=0;attempt<4;attempt++) {
      const response=await fetch('https://www.wikidata.org/w/api.php?'+params,{headers:{'User-Agent':UA},signal:AbortSignal.timeout(60000)});
      if(response.ok){result=await response.json();break;}
      if(![429,502,503,504].includes(response.status))throw Error('Wikidata '+response.status);
      await new Promise(r=>setTimeout(r,3000*(attempt+1)));
    }
    if(!result?.entities)throw Error('Wikidata response incomplete');
    for(const [id,e] of Object.entries(result.entities)){entities[id]=e;fs.writeFileSync(path.join(cache,id+'.json'),JSON.stringify(e));}
    console.log('Entities',i+batch.length,'/',missing.length);
  }
}
const claims=(e,p)=>(e?.claims?.[p]??[]).filter(s=>s.rank!=='deprecated'&&s.mainsnak.datavalue);
const value=s=>s.mainsnak.datavalue.value;
const ids=(e,p)=>claims(e,p).map(s=>value(s).id).filter(Boolean);
const label=id=>entities[id]?.labels?.de?.value??entities[id]?.labels?.en?.value??entities[id]?.labels?.mul?.value??'';
const date=q=>q?.[0]?.datavalue?.value?.time?.slice(1,11)??'';
function active(e,p,day) {
  return claims(e,p).filter(s=>{
    const start=date(s.qualifiers?.P580),end=date(s.qualifiers?.P582);
    return start&&start<=day&&(!end||day<end);
  }).sort((a,b)=>date(b.qualifiers?.P580).localeCompare(date(a.qualifiers?.P580)));
}
const historical={RUS:'Q15180',CHN:'Q13426199',IRN:'Q107258515',ETH:'Q207521',IND:'Q129286'};
const modern={PSX:'Q219060'};
const officeHistory={};
for(const [year,file] of [[1936,'historical-offices.json'],[2026,'modern-offices.json']]) {
  const location=path.join(cache,file);
  officeHistory[year]=fs.existsSync(location)?JSON.parse(fs.readFileSync(location)):[];
}
await fetchEntities([...source.features.map(f=>f.properties.WIKIDATAID),...Object.values(historical),...Object.values(modern)]);
const peopleIds=new Set(), extraIds=new Set();
for(const e of Object.values(entities)) {
  for(const p of ['P36','P122','P38','P37','P1906','P1313'])ids(e,p).forEach(id=>extraIds.add(id));
  for(const day of ['1936-01-01','2026-01-01']) for(const p of ['P35','P6']) {
    for(const s of active(e,p,day)){peopleIds.add(value(s).id);for(const q of s.qualifiers?.P39??[])if(q.datavalue?.value?.id)extraIds.add(q.datavalue.value.id);}
  }
}
await fetchEntities([...peopleIds,...extraIds]);
// Office statements may preserve a holder when the country item only lists a successor.
for(const e of Object.values(entities))for(const day of ['1936-01-01','2026-01-01'])for(const s of active(e,'P1308',day))peopleIds.add(value(s).id);
for(const row of Object.values(officeHistory).flat())peopleIds.add(row.person);
for(const countries of Object.values(overrides))for(const list of Object.values(countries))for(const person of list)peopleIds.add(person.qid);
await fetchEntities([...peopleIds]);
const partyIds=new Set();
for(const id of peopleIds)ids(entities[id],'P102').forEach(q=>partyIds.add(q));
await fetchEntities([...partyIds]);
function leaders(e,day) {
  const result=[];
  for(const [prop,role] of [['P35','Staatsoberhaupt'],['P6','Regierungsführung']]) {
    const offices=ids(e,prop==='P35'?'P1906':'P1313');
    let statements=active(e,prop,day).concat(offices.flatMap(id=>active(entities[id],'P1308',day)));
    for(const row of officeHistory[+day.slice(0,4)]??[])if(offices.includes(row.office))statements.push({mainsnak:{datavalue:{value:{id:row.person}}},qualifiers:{P580:[{datavalue:{value:{time:'+'+row.start}}}]}});
    statements.sort((a,b)=>date(b.qualifiers?.P580).localeCompare(date(a.qualifiers?.P580)));
    // More than one holder may legitimately share an office (e.g. San Marino).
    const latest=statements[0]&&date(statements[0].qualifiers?.P580);
    for(const s of statements.filter(x=>date(x.qualifiers?.P580)===latest)) {
      const id=value(s).id,person=entities[id];
      if(!label(id)||/^Q\d+$/.test(label(id))||result.some(x=>x.qid===id&&x.role===role))continue;
      let memberships=claims(person,'P102').filter(x=>{
        const start=date(x.qualifiers?.P580),end=date(x.qualifiers?.P582);
        const foundation=claims(entities[value(x).id],'P571').map(value)[0]?.time?.slice(1,11)??'';
        return (!start||start<=day)&&(!end||day<end)&&(!foundation||foundation<=day);
      });
      const dated=memberships.filter(x=>date(x.qualifiers?.P580));
      if(dated.length)memberships=dated.sort((a,b)=>date(b.qualifiers?.P580).localeCompare(date(a.qualifiers?.P580))).slice(0,1);
      const parties=memberships.map(x=>label(value(x).id)).filter(x=>x&&!/^Q\d+$/.test(x));
      const title=offices.length===1?label(offices[0]):role;
      const rawDate=date(s.qualifiers?.P580),since=rawDate.endsWith('-00-00')?rawDate.slice(0,4):rawDate.endsWith('-00')?rawDate.slice(0,7):rawDate;
      result.push({name:label(id),qid:id,role,title:title||role,since,parties:[...new Set(parties)],source:'https://www.wikidata.org/wiki/'+e.id,person_source:'https://www.wikidata.org/wiki/'+id});
    }
  }
  return result;
}
function currentIds(e,p) {
 const candidates=claims(e,p).filter(s=>!date(s.qualifiers?.P582));
 const preferred=candidates.filter(s=>s.rank==='preferred');
 return (preferred.length?preferred:candidates).map(s=>value(s).id).filter(Boolean);
}
const countries=source.features.map(f=>{
  const p=f.properties,e=entities[p.WIKIDATAID];
  const profiles={};
  for(const year of [1936,2026]) {
    const qid=year===1936?(historical[p.ADM0_A3]??p.WIKIDATAID):(modern[p.ADM0_A3]??p.WIKIDATAID);
    const entity=entities[qid],day=year+'-01-01';
    profiles[year]={date:day,entity:qid,name:label(qid)||p.NAME_DE,leaders:leaders(entity,day)};
  }
  return {code:p.ADM0_A3,name:p.NAME_DE??p.ADMIN,english:p.ADMIN,qid:p.WIKIDATAID,sovereign:p.SOVEREIGNT,type:p.TYPE,continent:p.CONTINENT,center:[p.LABEL_X,p.LABEL_Y],population:p.POP_EST,population_year:p.POP_YEAR,capital:currentIds(e,'P36').map(label).filter(Boolean).slice(0,3),currency:currentIds(e,'P38').map(label).filter(Boolean).slice(0,3),profiles};
});
for(const c of countries)for(const [year,profiles] of Object.entries(overrides))for(const person of profiles[c.code]??[]) {
  const profile=c.profiles[year];
  profile.leaders=profile.leaders.filter(p=>p.role!==person.role);
  profile.leaders.push({...person,parties:[],source:'https://www.wikidata.org/wiki/'+profile.entity,person_source:'https://www.wikidata.org/wiki/'+person.qid});
}
for(const c of countries) {
  // Dependent territories show the supervising government's leaders as such, not invented local offices.
  if(!c.profiles[2026].leaders.length&&c.type==='Dependency') {
    const parent=countries.find(p=>p.english===c.sovereign&&p.code!==c.code);
    if(parent){c.profiles[2026].leaders=parent.profiles[2026].leaders.map(p=>({...p}));c.profiles[2026].reference_government=parent.name;}
  }
  if(c.code==='TWN') {
    const japan=countries.find(p=>p.code==='JPN').profiles[1936];
    c.profiles[1936]={...japan,reference_government:'Japan (Taiwan unter japanischer Herrschaft)'};
  }
}
fs.writeFileSync('data/world_profiles.json',JSON.stringify({retrieved:'2026-09-19',source:'Wikidata CC0; Natural Earth public domain',countries},null,2)+'\n');
console.log('Atlas:',countries.length,'regions; leadership coverage',...['1936','2026'].map(y=>y+': '+countries.filter(c=>c.profiles[y].leaders.length).length));
