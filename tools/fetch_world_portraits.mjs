// Offline Commons photos for the atlas. Usage: node tools/fetch_world_portraits.mjs cache-dir
import fs from 'node:fs';
import path from 'node:path';
const cache=process.argv[2],manifestPath='data/world_portraits.json';
const atlas=JSON.parse(fs.readFileSync('data/world_profiles.json'));
const original=JSON.parse(fs.readFileSync('data/portraits.json'));
const manifest=fs.existsSync(manifestPath)?JSON.parse(fs.readFileSync(manifestPath)):{};
const people=new Map(atlas.countries.flatMap(c=>Object.values(c.profiles).flatMap(p=>p.leaders)).map(p=>[p.name,p]));
const issues=[];
fs.mkdirSync('assets/world-portraits',{recursive:true});
const strip=html=>String(html??'').replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&#0?39;/g,"'").replace(/&quot;/g,'"').replace(/\s+/g,' ').trim();
async function request(url,raw=false){
 for(let i=0;i<4;i++){
  const r=await fetch(url,{headers:{'User-Agent':'Staatskunst/0.7 (https://github.com/badcookie-hd/staatskunst; offline portrait attribution)'},signal:AbortSignal.timeout(40000)});
  if([429,502,503,504].includes(r.status)){await new Promise(done=>setTimeout(done,2500*(i+1)));continue;}
  if(!r.ok)throw Error('HTTP '+r.status);
  return raw?Buffer.from(await r.arrayBuffer()):r.json();
 }
 throw Error('Retry limit');
}
async function collect(p){
 if(original[p.name]||manifest[p.name]?.file)return;
 const reused=Object.values({...original,...manifest}).find(x=>x.qid===p.qid);
 if(reused){manifest[p.name]={...reused};return;}
 const entity=JSON.parse(fs.readFileSync(path.join(cache,p.qid+'.json')));
 const images=(entity.claims.P18??[]).filter(x=>x.rank!=='deprecated').map(x=>x.mainsnak.datavalue?.value).filter(Boolean);
 for(const file of images){
  try{
   const cacheFile=path.join(cache,p.qid+'-image-'+Buffer.from(file).toString('base64url').slice(0,90)+'.json');
   const data=fs.existsSync(cacheFile)?JSON.parse(fs.readFileSync(cacheFile)):await request('https://commons.wikimedia.org/w/api.php?'+new URLSearchParams({action:'query',titles:'File:'+file,prop:'imageinfo',iiprop:'url|extmetadata|size|mime',iiurlwidth:240,format:'json',formatversion:'2'}));
   fs.writeFileSync(cacheFile,JSON.stringify(data));
   const image=data.query?.pages?.[0]?.imageinfo?.[0];if(!image)continue;
   const meta=image.extmetadata??{},license=strip(meta.LicenseShortName?.value);
   if(!/^(CC0|CC BY(?:-SA)? \d\.\d|Public domain|PDM|Attribution$|Copyrighted free use$|OGL 3$)/i.test(license))continue;
   const url=image.thumburl??image.url;if(/\.gif(?:$|\?)/i.test(url))continue;
   const ext=/\.(png|webp)(?:$|\?)/i.exec(url)?.[1]?.toLowerCase()??'jpg',dest='assets/world-portraits/'+p.qid+'.'+ext;
   if(!fs.existsSync(dest)){const bytes=await request(url,true);if(bytes.length<100)throw Error('Empty image');fs.writeFileSync(dest,bytes);}
   const source=image.descriptionurl??'https://commons.wikimedia.org/wiki/File:'+encodeURIComponent(file);
   let licenseUrl=meta.LicenseUrl?.value??source;if(licenseUrl.startsWith('//'))licenseUrl='https:'+licenseUrl;
   manifest[p.name]={file:'res://'+dest,qid:p.qid,label:p.name,source,commons_file:file,author:strip(meta.Artist?.value)||strip(meta.Credit?.value)||'See source page',license,license_url:licenseUrl,attribution:strip(meta.Attribution?.value),download_url:url,modifications:'Unmodified Wikimedia thumbnail; displayed scaled in the game.'};
   fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
   console.log('Atlas photo',Object.keys(manifest).length,p.name);return;
  }catch(e){console.log('Photo retry',p.name,e.message);}
 }
 issues.push({name:p.name,qid:p.qid,issue:images.length?'No usable licensed image downloaded':'No image in source'});
}
const queue=[...people.values()];
await Promise.all(Array.from({length:3},async()=>{while(queue.length)await collect(queue.shift());}));
fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync(path.join(cache,'photo-issues.json'),JSON.stringify(issues,null,2));
const esc=s=>String(s??'').replaceAll('|','\\|').replaceAll('\n',' ');
let doc='# Weltatlas: zusätzliche Bildnachweise\n\nAm 19. September 2026 von Wikimedia Commons geladen. Fotos zeigen reale Personen, nicht zwingend zum Szenariostart. Unveränderte Vorschaubilder; nur die Anzeige wird skaliert. Die jeweiligen Lizenzen gelten unabhängig von der MIT-Lizenz des Programmcodes. Alle Bilder und Nachweise werden offline mitgeliefert. Bestehende Kampagnenporträts: [PORTRAIT-CREDITS.md](PORTRAIT-CREDITS.md). Fehlende frei verwendbare Bilder werden im Atlas ausdrücklich als fehlend dargestellt.\n\n| Person | Urheber / Attribution | Lizenz | Quelle |\n|---|---|---|---|\n';
for(const [name,p]of Object.entries(manifest).sort(([a],[b])=>a.localeCompare(b)))doc+=`| ${esc(name)} | ${esc(p.author)} ${esc(p.attribution)} | [${esc(p.license)}](${p.license_url}) | [${esc(p.commons_file)}](${p.source.replaceAll(' ','%20')}) |\n`;
fs.writeFileSync('docs/WORLD-PORTRAIT-CREDITS.md',doc);
console.log('Atlas photos:',Object.keys(manifest).length,'missing:',issues.length);
