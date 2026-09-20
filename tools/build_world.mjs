// node tools/build_world.mjs path/to/ne_50m_admin_0_countries.geojson
// Natural Earth public-domain reference geography; campaign geometry is separate.
import fs from 'node:fs';
const source=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
function simplify(points, tolerance=0.035) {
  if(points.length<8)return points;
  const sq=tolerance*tolerance,keep=new Set([0,points.length-1]),stack=[[0,points.length-1]];
  while(stack.length){const [a,b]=stack.pop(),[x,y]=points[a],[xx,yy]=points[b],dx=xx-x,dy=yy-y;let max=sq,index=-1;
    for(let i=a+1;i<b;i++){const [px,py]=points[i],t=Math.max(0,Math.min(1,((px-x)*dx+(py-y)*dy)/(dx*dx+dy*dy||1))),d=(px-x-t*dx)**2+(py-y-t*dy)**2;if(d>max){max=d;index=i;}}
    if(index>=0){keep.add(index);stack.push([a,index],[index,b]);}
  }
  const result=[...keep].sort((a,b)=>a-b).map(i=>points[i]);return result.length>=4?result:points;
}
const countries=source.features.map(f=>({code:f.properties.ADM0_A3,name:f.properties.NAME_DE??f.properties.ADMIN,center:[f.properties.LABEL_X??0,f.properties.LABEL_Y??0],polygons:(f.geometry.type==='Polygon'?[f.geometry.coordinates]:f.geometry.coordinates).map(p=>simplify(p[0]).slice(0,-1).map(v=>v.map(x=>Math.round(x*10000)/10000))).filter(p=>p.length>=3)}));
fs.writeFileSync('data/world.json',JSON.stringify({source:'Natural Earth 1:50m; public domain; simplified at 0.035 degrees',countries}));
console.log('World reference regions:',countries.length);
