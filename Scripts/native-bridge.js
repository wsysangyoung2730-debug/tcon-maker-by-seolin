// Native adapter. Original rendering/model functions above are preserved.
document.body.style.display='none';
document.documentElement.setAttribute('aria-hidden','true');
const nativeBlob = b => new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(r.result);r.onerror=()=>reject(new Error('사진 데이터를 읽을 수 없어요'));r.readAsDataURL(b);});
const nativeDefaults = JSON.parse(JSON.stringify(S));
// Aggregate timings only; no image or face data is recorded.
let nativeMetrics={};
function nativeMeasure(name, fn){return async function(...args){
  const start=performance.now();
  try{return await fn(...args);}finally{
    const metric=nativeMetrics[name]||(nativeMetrics[name]={count:0,ms:0});
    metric.count++;metric.ms+=performance.now()-start;
  }
};}
fileToCanvas=nativeMeasure('decode',fileToCanvas);
detectFaces=nativeMeasure('face',detectFaces);
personAlpha=nativeMeasure('background',personAlpha);
reencode=nativeMeasure('preview',reencode);

const nativeRanges={wmm:[10,200],hmm:[10,200],maxkb:[20,20000],bright:[-50,50],head:[55,85],top:[3,16],below:[0.6,1.8]};
function nativeSettings(input){
  const out={};
  for(const [k,v] of Object.entries(input||{})){
    if(nativeRanges[k]){if(!Number.isFinite(v))throw new Error('올바른 숫자를 입력해 주세요');out[k]=Math.max(nativeRanges[k][0],Math.min(nativeRanges[k][1],v));}
    else if(['orig','whitebg','clear','grid'].includes(k))out[k]=!!v;
    else if(k==='center'&&['face','mix','body'].includes(v))out[k]=v;
    else if(k==='mode'&&['chest','face'].includes(v))out[k]=v;
  }return out;
}
// Reuse immutable preview bytes instead of reading every old Blob on each import.
const nativePreviewData=new WeakMap();
async function nativePreview(blob){
  if(!blob)return null;
  if(!nativePreviewData.has(blob))nativePreviewData.set(blob,await nativeBlob(blob));
  return nativePreviewData.get(blob);
}
// Adjustment-only edits keep the analysis canvas and its downsample pyramid.
// The upstream low-memory path releases the source after segmentation; do not
// decode that source again just to reuse the already prepared foreground.
const nativePrepareBase=prepareBase;
prepareBase=async function(it){
  const foreground=bgOf(it)!=='orig';
  const cached=foreground?it.whiteBase:it.rawBase;
  const rotation=foreground?it.whiteK:it.rawK;
  if(cached&&cached.width>0&&rotation===(it.k||0)){
    if(it.base!==cached){releaseCache(it);it.base=cached;it.nativeMeasuredFace=null;}
    if(it.nativeMeasuredFace!==it.face){measureTorso(it);it.nativeMeasuredFace=it.face;}
    if(LOWMEM&&foreground){
      if(it.rawBase&&it.rawBase!==it.src)freeCv(it.rawBase);
      freeCv(it.src);it.rawBase=null;it.src=null;
    }
    return;
  }
  await nativePrepareBase(it);it.nativeMeasuredFace=it.face;
};
function nativeApplyState(it,state){
  const saved=JSON.parse(state);
  if(saved.version!==1)throw new Error('Unsupported saved photo version');
  it.k=((saved.k||0)%4+4)%4;it.face=saved.face;it.face0=saved.face0;
  it.adj={zoom:1,dx:0,dy:0,tilt:0,bright:0,...saved.adj};
  it.overrides=nativeSettings(saved.overrides);it.snap=saved.snap!==false;
  if(['white','clear','orig'].includes(saved.bg))it.bg=saved.bg;else delete it.bg;
}
const nativeMaskArchives=new WeakMap();
async function nativeAnalysis(it){
  const mask=it.mask,person=it.whiteBase;
  if(!mask||!person||!mask.width||!person.width)return null;
  if(!nativeMaskArchives.has(mask)){
    nativeMaskArchives.set(mask,JSON.stringify({version:1,sourceWidth:it.srcW,naturalWidth:it.natW,
      rotation:it.whiteK,width:person.width,height:person.height,scale:mask.s,
      bgc:person.bgc,mask:await nativeBlob(await toPng(mask))}));
  }
  return nativeMaskArchives.get(mask);
}
// Derived caches are optional. An absent, incompatible or damaged cache falls
// back to the original segmentation path; persisted edits and originals survive.
async function nativeRestoreAnalysis(it,text){
  if(!text||text.length>8*1024*1024)return false;
  let raw=null,mask=null,person=null;
  try{
    const saved=JSON.parse(text);
    if(saved.version!==1||saved.rotation!==it.k||saved.sourceWidth!==it.srcW||saved.naturalWidth!==it.natW
      ||!Number.isFinite(saved.scale)||saved.scale<=0||saved.scale>1
      ||!Array.isArray(saved.bgc)||saved.bgc.length!==3||!saved.bgc.every(v=>Number.isFinite(v)&&v>=0&&v<=255)
      ||typeof saved.mask!=='string'||!saved.mask.startsWith('data:image/png;base64,'))return false;
    raw=rot90(it.src,it.k);
    if(raw.width!==saved.width||raw.height!==saved.height)return false;
    const image=await loadImage(saved.mask);
    if(image.naturalWidth<8||image.naturalHeight<8||image.naturalWidth>1280||image.naturalHeight>1280
      ||image.naturalWidth!==Math.round(raw.width*saved.scale)||image.naturalHeight!==Math.round(raw.height*saved.scale))return false;
    mask=document.createElement('canvas');mask.width=image.naturalWidth;mask.height=image.naturalHeight;
    const mx=mask.getContext('2d',{willReadFrequently:true});mx.drawImage(image,0,0);
    const pixels=mx.getImageData(0,0,mask.width,mask.height).data;
    mask.s=saved.scale;mask.alpha=new Uint8Array(mask.width*mask.height);
    for(let i=0;i<mask.alpha.length;i++)mask.alpha[i]=pixels[i*4+3];
    person=document.createElement('canvas');person.width=raw.width;person.height=raw.height;
    const px=person.getContext('2d');px.drawImage(raw,0,0);px.globalCompositeOperation='destination-in';
    px.imageSmoothingQuality='high';px.drawImage(mask,0,0,person.width,person.height);
    decontam(person,saved.bgc);person.mask=mask;person.person=person;person.bgc=saved.bgc;
    it.whiteBase=it.whiteBase0=person;it.whiteK=it.k;it.mask=mask;
    nativeMaskArchives.set(mask,text);mask=null;person=null;
    return true;
  }catch(_){return false;}
  finally{if(raw&&raw!==it.src)freeCv(raw);freeCv(mask);freeCv(person);}
}
async function nativeImport(payload){
  const raw=atob(payload.base64),bytes=new Uint8Array(raw.length);
  for(let i=0;i<raw.length;i++)bytes[i]=raw.charCodeAt(i);
  const file=new File([bytes],payload.name||'사진.jpg',{type:payload.mime||'image/jpeg'});
  let it;
  if(payload.state){
    it={id:++seq,file,name:file.name,status:'work',adj:{zoom:1,dx:0,dy:0,tilt:0},open:false};
    items.push(it);
    try{
      it.src=await fileToCanvas(file);it.srcW=it.src.width;it.natW=it.src.natW;
      nativeApplyState(it,payload.state);
      await nativeRestoreAnalysis(it,payload.analysis);
      await nativeContext(it,async()=>{await prepareBase(it);await reencode(it);});
    }catch(error){items.splice(items.indexOf(it),1);nativeDispose(it);throw error;}
  }else{
    addFiles([file]);await queue;it=items[items.length-1];
  }
  return payload.single?nativeSnapshot(it):nativeAll();
}
function nativeRenderKey(it){
  const settings={...S,...it.overrides};
  return JSON.stringify([
    ...['wmm','hmm','bright','head','top','below','center','mode','whitebg','clear'].map(k=>settings[k]),
    it.bg||null,it.adj
  ]);
}

async function nativeContext(it,fn){const old={...S};Object.assign(S,it.overrides||{});try{return await fn();}finally{Object.assign(S,old);}}
async function nativeSnapshot(it){return nativeContext(it,async()=>{
  let eye=null;let warnings=[];
  if(it.status==='done'){
    const g=cropGeom(it);eye=it.face?((it.face.crown||it.face.fl*1.12)/g.ch+S.top/100+it.adj.dy):null;
    const holder=document.createElement('div');holder.innerHTML=chips(it);warnings=[...holder.querySelectorAll('.warn,.bad')].map(x=>x.textContent);
  }
  return {id:it.id,name:it.name,status:it.status,error:it.err||null,preview:await nativePreview(it.blob),width:it.w||0,height:it.h||0,face:!!it.face,warnings,adjustment:{bright:0,...it.adj},background:bgOf(it),snap:it.snap!==false,rotation:it.k||0,custom:!!it.bg||Object.keys(it.overrides||{}).length>0||Object.entries(it.adj).some(([k,v])=>v!==(k==='zoom'?1:0)),composition:{mode:S.mode,center:S.center,head:S.head,top:S.top,below:S.below},eye};
});}
async function nativeAll(){const photos=[];for(const it of items)photos.push(await nativeSnapshot(it));return {photos,faceAvailable:modelOK,backgroundAvailable:!!segModel};}
function nativeDispose(it){
  if(it.url)URL.revokeObjectURL(it.url);releaseCache(it);
  for(const c of new Set([it.src,it.rawBase,it.whiteBase,it.whiteBase0,it.base,it.mask]))freeCv(c);
}
// No web UI is mounted by the native app; avoid retained preview cards/canvases.
renderCard=()=>{};updateBar=()=>{};saveSet=()=>{};
let nativeQueue=Promise.resolve();
window.TCONNative={execute(command,payload={}){
  const operation=nativeQueue.then(async()=>{
    await readyPromise;
    if(command==='metrics')return nativeMetrics;
    if(command==='resetMetrics'){nativeMetrics={};return true;}
    if(command==='ready')return {faceAvailable:modelOK,backgroundAvailable:!!segModel};
    if(command==='import')return nativeImport(payload);
    if(command==='settings'){
      const before=new Map(items.map(it=>[it.id,nativeRenderKey(it)]));
      Object.assign(S,nativeSettings(payload.settings));
      window.TCONNative.globalSettings={...S};
      for(const it of items){
        if(payload.preserve===false){it.adj={zoom:1,dx:0,dy:0,tilt:0,bright:0};it.overrides={};delete it.bg;}
        if(it.status==='done'&&before.get(it.id)!==nativeRenderKey(it))await nativeContext(it,async()=>{await prepareBase(it);await reencode(it);});
      }return nativeAll();
    }
    if(command==='snapshot')return nativeAll();
    if(command==='archive'){
      const result=[];
      for(const it of items.filter(it=>!payload.ids||payload.ids.includes(it.id)))result.push({id:it.id,
        state:JSON.stringify({version:1,k:it.k||0,face:it.face||null,face0:it.face0||null,adj:it.adj,overrides:it.overrides||{},bg:it.bg||null,snap:it.snap!==false}),
        analysis:payload.includeAnalysis?await nativeAnalysis(it):null});
      return result;
    }
    if(command==='clear'){items.splice(0).forEach(nativeDispose);return nativeAll();}
    if(command==='delete'){
      const ids=new Set(payload.ids||[]);for(let i=items.length-1;i>=0;i--)if(ids.has(items[i].id))nativeDispose(items.splice(i,1)[0]);return nativeAll();
    }
    if(command==='export'){
      const list=items.filter(it=>(payload.ids||[]).includes(it.id));if(!list.length)throw new Error('저장할 사진을 선택해 주세요');
      const result=[];const used=new Set();const zip=new JSZip();
      for(const it of list){
        if(it.status!=='done')throw new Error('처리가 완료되지 않은 사진이 있어요');
        await nativeContext(it,async()=>{
          const blob=await originalBlob(it);if(!blob)throw new Error('이미지를 저장할 수 없어요');
          let name=outName(it).replace(/[\/\\:\x00-\x1f]/g,'_');const dot=name.lastIndexOf('.'),stem=name.slice(0,dot),ext=name.slice(dot);let n=2;
          while(used.has(name.toLowerCase()))name=stem+'_'+(n++)+ext;used.add(name.toLowerCase());
          const limitExceeded=!clearMode(it)&&!S.orig&&blob.size>S.maxkb*1024;
          if(limitExceeded)throw new Error(name+': 최대 용량을 맞출 수 없어요. 용량 제한을 높여 주세요.');
          if(bgOf(it)!=='orig'&&!(it.whiteBase&&it.base===it.whiteBase))throw new Error(name+': 배경 분리를 완료하지 못했어요. 원본 배경을 선택하거나 다시 시도해 주세요.');
          if(payload.zip)zip.file(name,blob);
          else result.push({name,mime:blob.type,size:blob.size,base64:(await nativeBlob(blob)).split(',')[1]});
        });
      }
      if(payload.zip){const b=await zip.generateAsync({type:'blob'});return [{name:'TCON_'+list.length+'장.zip',mime:'application/zip',size:b.size,base64:(await nativeBlob(b)).split(',')[1]}];}
      return result;
    }
    const it=items.find(x=>x.id===payload.id);if(!it)throw new Error('사진을 찾을 수 없어요');
    if(command==='restore')nativeApplyState(it,payload.state);
    return nativeContext(it,async()=>{
      if(command==='restore'){
        await prepareBase(it);
      }else if(command==='update'){
        const ranges={zoom:[0.4,3],tilt:[-45,45],dx:[-0.5,0.5],dy:[-0.5,0.5],bright:[-50,50]};
        for(const [k,v]of Object.entries(payload.adjustment||{}))if(ranges[k]&&Number.isFinite(v))it.adj[k]=Math.max(ranges[k][0],Math.min(ranges[k][1],v));
        if(['white','clear','orig'].includes(payload.background))it.bg=payload.background;
        if(typeof payload.snap==='boolean')it.snap=payload.snap;
        if(payload.composition){it.overrides={...(it.overrides||{}),...nativeSettings(payload.composition)};Object.assign(S,it.overrides);}
        await prepareBase(it);
        if(payload.realign&&it.snap!==false&&modelOK)await snapToPerson(it);
      }else if(command==='rotate'){
        await ensureSrc(it);it.k=((it.k||0)+(payload.direction===-1?3:1))%4;
        const rb=rot90(it.src,it.k);it.face=modelOK?await detect(rb):null;if(rb!==it.src)freeCv(rb);it.face0=it.face?{...it.face}:null;
        await prepareBase(it);it.adj={zoom:1,dx:0,dy:0,tilt:0,bright:it.adj.bright||0};
      }else if(command==='reset'){
        it.adj={zoom:1,dx:0,dy:0,tilt:0,bright:0};it.overrides={};delete it.bg;it.snap=true;
        Object.assign(S,nativeDefaults,window.TCONNative.globalSettings||{});
        await ensureSrc(it);await analyze(it);
      }else throw new Error('지원하지 않는 사진 작업입니다');
      await reencode(it);return nativeSnapshot(it);
    });
  });
  nativeQueue=operation.catch(()=>{});return operation;
}};
