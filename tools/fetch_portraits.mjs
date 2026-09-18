// Download attributed Commons portraits selected through Wikipedia/Wikidata identities.
// Run from the repository: node tools/fetch_portraits.mjs [--resolve-only]
import fs from 'node:fs';
import path from 'node:path';
const UA='Staatskunst/0.5 (https://github.com/badcookie-hd/staatskunst; portrait attribution collector)';
const cacheDir=path.resolve(process.env.STAATSKUNST_PORTRAIT_CACHE??'.portrait-cache');
fs.mkdirSync(cacheDir,{recursive:true});
fs.mkdirSync('assets/portraits',{recursive:true});
const data=JSON.parse(fs.readFileSync('data/politics.json','utf8'));
const names={};
for(const [year,countries] of Object.entries(data))for(const c of Object.values(countries)) {
 for(const name of [c.head,c.premier,...c.parties.flatMap(p=>p.candidates.filter(x=>!x.fictional).map(x=>x.name))]) (names[name]??=new Set()).add(+year);
}
names['Paul Löbe']=new Set([1936]); names['Wilhelm II.']=new Set([1936]);
const overrides=fs.existsSync('data/portrait_sources.json')?JSON.parse(fs.readFileSync('data/portrait_sources.json','utf8')):{};
const resolvedFile=path.join(cacheDir,'resolved.json');
let resolved=fs.existsSync(resolvedFile)?JSON.parse(fs.readFileSync(resolvedFile,'utf8')):{};
const save=()=>fs.writeFileSync(resolvedFile,JSON.stringify(resolved,null,2));
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function request(url,raw=false) {
 for(let i=0;i<5;i++) {
  const response=await fetch(url,{headers:{'User-Agent':UA},signal:AbortSignal.timeout(45000)});
  if([429,503,502,504].includes(response.status)){await wait(Math.max(2000*(i+1),Number(response.headers.get('retry-after')??0)*1000));continue;}
  if(!response.ok)throw Error(`${response.status}: ${url}`);
  return raw?Buffer.from(await response.arrayBuffer()):response.json();
 }
 throw Error('Retry limit: '+url);
}
const api=(host,params)=>request(`https://${host}/w/api.php?`+new URLSearchParams({...params,format:'json',formatversion:'2'}));
const chunks=(items,size)=>Array.from({length:Math.ceil(items.length/size)},(_,i)=>items.slice(i*size,(i+1)*size));
for(const language of ['de','en']) {
 const pending=Object.keys(names).filter(n=>!resolved[n]?.qid&&!overrides[n]?.qid);
 for(const batch of chunks(pending,30)) {
  const result=await api(language+'.wikipedia.org',{action:'query',titles:batch.join('|'),prop:'pageprops',redirects:1});
  const redirects={};for(const x of [...result.query.normalized??[],...result.query.redirects??[]])redirects[x.from]=x.to;
  for(const name of batch){let title=name;for(let i=0;i<5&&redirects[title];i++)title=redirects[title]; const page=result.query.pages.find(p=>p.title===title); if(page?.pageprops?.wikibase_item&&!('disambiguation' in page.pageprops))resolved[name]={qid:page.pageprops.wikibase_item,page_image:page.pageprops.page_image_free??'',wikipedia:`https://${language}.wikipedia.org/wiki/`+encodeURIComponent(page.title.replaceAll(' ','_'))};}
  save(); console.log('Resolved',language,Object.keys(resolved).length,'/',Object.keys(names).length);
 }
}
for(const [name,entry] of Object.entries(overrides))resolved[name]={...(resolved[name]?.qid===entry.qid?resolved[name]:{}),...entry};
save();
for(const batch of chunks(Object.entries(resolved).filter(([n,e])=>!e.entity),35)) {
 const result=await api('www.wikidata.org',{action:'wbgetentities',ids:[...new Set(batch.map(([n,e])=>e.qid))].join('|'),props:'claims|labels|descriptions',languages:'de|en'});
 for(const [name,entry] of batch){const entity=result.entities[entry.qid];if(!entity)continue; const claim=p=>(entity.claims?.[p]??[]).filter(x=>x.rank!=='deprecated').map(x=>x.mainsnak.datavalue?.value).filter(Boolean);entry.entity={label:entity.labels?.de?.value??entity.labels?.en?.value,description:entity.descriptions?.en?.value??entity.descriptions?.de?.value,born:claim('P569')[0]?.time??'',died:claim('P570')[0]?.time??'',human:claim('P31').some(v=>v.id==='Q5'),images:claim('P18')};}
 save();console.log('Entities checked',batch.length);
}
const manifestFile='data/portraits.json';
const manifest=fs.existsSync(manifestFile)?JSON.parse(fs.readFileSync(manifestFile,'utf8')):{};
const issueList=[];
for(const name of Object.keys(names)) {

 if(manifest[name]?.kind==='illustration')continue;
 const r=resolved[name];
 if(!r?.entity){issueList.push({name,issue:'unresolved'});continue;}
 const birth=Number(r.entity.born.match(/^\+(\d{4})/)?.[1]??0),death=Number(r.entity.died.match(/^\+(\d{4})/)?.[1]??9999);
 if(!r.entity.human||[...names[name]].some(y=>birth>y-18||death<y)){issueList.push({name,issue:'identity/dates',...r.entity,qid:r.qid});continue;}
 if(!r.file&&!r.entity.images.length&&!r.page_image){issueList.push({name,issue:'no image',qid:r.qid,...r.entity});continue;}
}
fs.writeFileSync(path.join(cacheDir,'issues.json'),JSON.stringify(issueList,null,2));
console.log('Identity/image issues:',issueList.length);for(const x of issueList)console.log(JSON.stringify(x));
if(process.argv.includes('--resolve-only'))process.exit(0);
const blocked=new Set(issueList.map(x=>x.name));
const strip=html=>String(html??'').replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&#0?39;/g,"'").replace(/&quot;/g,'"').replace(/\s+/g,' ').trim();
async function collect(name) {
 const r=resolved[name];
 if(manifest[name]?.file&&fs.existsSync(manifest[name].file.replace('res://','')))return;
 const options=[...new Set([r.file,...r.entity.images,r.page_image].filter(Boolean))];
 for(const file of options) {
  try {
   const cacheName=path.join(cacheDir,r.qid+'-'+Buffer.from(file).toString('base64url').slice(0,100)+'.json');
   const info=fs.existsSync(cacheName)?JSON.parse(fs.readFileSync(cacheName,'utf8')):await api('commons.wikimedia.org',{action:'query',titles:'File:'+file,prop:'imageinfo',iiprop:'url|extmetadata|size|mime',iiurlwidth:240});
   fs.writeFileSync(cacheName,JSON.stringify(info));
   const image=info.query?.pages?.[0]?.imageinfo?.[0];if(!image)continue;
   const meta=image.extmetadata??{},license=strip(meta.LicenseShortName?.value);
   if(!/^(CC0|CC BY(?:-SA)? \d\.\d|Public domain|PDM|Attribution$|Copyrighted free use$|OGL 3$)/i.test(license)){console.log('License skipped',name,license);continue;}
   const url=image.thumburl??image.url;
   const ext=/\.(png|webp|gif)(?:$|\?)/i.exec(url)?.[1]?.toLowerCase()??'jpg';
   const dest='assets/portraits/'+r.qid+'.'+ext;
   if(!fs.existsSync(dest)){const bytes=await request(url,true);if(bytes.length<100)throw Error('Empty image');fs.writeFileSync(dest,bytes);}
   manifest[name]={file:'res://'+dest,qid:r.qid,label:r.entity.label,description:r.entity.description,source:image.descriptionurl??'https://commons.wikimedia.org/wiki/File:'+encodeURIComponent(file),wikipedia:r.wikipedia??'https://www.wikidata.org/wiki/'+r.qid,commons_file:file,author:strip(meta.Artist?.value)||strip(meta.Credit?.value)||'See source page',license,license_url:meta.LicenseUrl?.value??'',attribution:strip(meta.Attribution?.value),download_url:url,modifications:'Unmodified Wikimedia thumbnail; displayed scaled in the game.'};
   fs.writeFileSync(manifestFile,JSON.stringify(manifest,null,2));
   console.log('Portrait',Object.keys(manifest).length,'/',Object.keys(names).length,name,license);
   return;
  }catch(error){console.log('Image error',name,error.message);}
 }
 issueList.push({name,issue:'download/license failed',qid:r.qid});
}
const queue=Object.keys(names).filter(n=>!blocked.has(n));
await Promise.all(Array.from({length:3},async()=>{while(queue.length){await collect(queue.shift());await wait(150);}}));
fs.writeFileSync(path.join(cacheDir,'issues.json'),JSON.stringify(issueList,null,2));
console.log('COMPLETE',Object.keys(manifest).length,'portraits; unresolved',issueList.length);
