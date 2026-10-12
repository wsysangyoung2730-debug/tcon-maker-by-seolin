// Deterministic HTML/CSS composition using unchanged, real app captures.
// Dependencies: playwright, sharp. See Design/AppStore/README.md.
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';
import { createHash } from 'node:crypto';
const require = createRequire(import.meta.url);
const dependency = name => require(process.env.TCON_RENDER_MODULES ? path.join(process.env.TCON_RENDER_MODULES, name) : name);
const { chromium } = dependency('playwright');
const sharp = dependency('sharp');
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dir = path.join(root, 'Design/AppStore');
const devices = [
 ['iPhone-Large-1320x2868',1320,2868],
 ['iPhone-Medium-1179x2556',1179,2556],
 ['iPad-13-2064x2752',2064,2752]
];
const sha256 = data => createHash('sha256').update(data).digest('hex');
const browser = await chromium.launch({headless:true,...(process.env.TCON_RENDER_BROWSER ? {executablePath:process.env.TCON_RENDER_BROWSER} : {})});
const manifest=[];
const previousManifest=JSON.parse(await fs.readFile(path.join(dir,'manifest.json'),'utf8'));
try {
 const page=await browser.newPage({deviceScaleFactor:1,colorScheme:'light',locale:'ko-KR'});
 for(const [device,width,height] of devices){
  await page.setViewportSize({width,height});
  await fs.mkdir(path.join(dir,'ko-KR',device),{recursive:true});
  for(let slide=0;slide<7;slide++){
   const url=pathToFileURL(path.join(dir,'Source/promotion.html'));
   url.searchParams.set('device',device);url.searchParams.set('slide',String(slide));
   await page.goto(url.href);await page.evaluate(()=>document.fonts.ready);
   await page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth>0));
   const spec=await page.evaluate(()=>{
    const selectors=window.renderSpec.slide.cover?['h1','.hero-icon','.hero-name','.hero-detail','.cover-signature']:['h1','.description','.frame'];
    const boxes=selectors.map(s=>document.querySelector(s).getBoundingClientRect());
    for(let i=0;i<boxes.length-1;i++)if(boxes[i].bottom>boxes[i+1].top)throw Error('Overlapping layout');
    if(boxes.some(b=>b.left<0||b.right>innerWidth||b.bottom>innerHeight))throw Error('Layout outside canvas');
    if(!window.renderSpec.slide.cover&&!window.renderSpec.device.startsWith('iPad')){
     const viewport=document.querySelector('.capture-viewport'),screen=document.querySelector('.screen');
     const mask=document.querySelector('.status-cover'),capture=document.querySelector('#capture');
     const island=getComputedStyle(screen,'::before');
     if(parseFloat(mask.style.height)<parseFloat(island.top)+parseFloat(island.height))throw Error('Island overlaps app content');
     const screenBox=screen.getBoundingClientRect(),viewBox=viewport.getBoundingClientRect(),imageBox=capture.getBoundingClientRect();
     for(const box of [viewBox,imageBox])for(const key of ['left','top','width','height'])if(Math.abs(box[key]-screenBox[key])>1)throw Error('Capture does not fill the display');
    }
    if(document.querySelector('.eyebrow'))throw Error('Feature caption still present');
    return window.renderSpec;
   });
   const buffer=await sharp(await page.screenshot({animations:'disabled'})).flatten({background:'#ffffff'}).removeAlpha().png({compressionLevel:9}).toBuffer();
   const metadata=await sharp(buffer).metadata();
   if(metadata.width!==width||metadata.height!==height||metadata.hasAlpha||metadata.channels!==3)throw Error('Invalid PNG');
   const file=`ko-KR/${device}/${spec.slide.id}.png`;
   if(spec.slide.cover){
    const previous=previousManifest.find(m=>m.file===file);
    if(previous&&previous.sha256!==sha256(buffer))throw Error('Approved cover changed');
   }
   await fs.writeFile(path.join(dir,file),buffer);
   manifest.push({file,width,height,alpha:false,sha256:sha256(buffer),title:spec.slide.title,description:spec.slide.description,source:spec.source,sourceSHA256:spec.source?sha256(await fs.readFile(path.join(dir,spec.source))):null,sourceCrop:spec.crop,statusMask:spec.statusMask||null});
   console.log(`Rendered ${file}`);
  }
 }
 const currentFiles=new Set(manifest.map(m=>m.file));
 for(const old of previousManifest){if(!currentFiles.has(old.file)&&old.file.startsWith('ko-KR/'))await fs.unlink(path.join(dir,old.file));}
 await fs.writeFile(path.join(dir,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
 const sections=devices.map(([device,w,h])=>`<section><h2>${device}</h2><p>${w} × ${h} · PNG · 표지 + 기능 소개 6장 · 시간/배터리 영역 제외</p><div class="grid">${manifest.filter(m=>m.file.includes(device)).map(m=>`<a href="${m.file}" target="_blank"><img src="${m.file}" alt="${escape(m.title.replaceAll('\n',' '))}"><span>${escape(m.title.replaceAll('\n',' '))}</span></a>`).join('')}</div></section>`).join('');
 await fs.writeFile(path.join(dir,'index.html'),`<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>TCON Maker · App Store 홍보 이미지</title><style>*{box-sizing:border-box}body{margin:0;padding:48px;background:#f1f4fa;color:#18275e;font-family:'Apple SD Gothic Neo',sans-serif}header,section{max-width:1600px;margin:0 auto 64px}h1{font-size:38px;margin:8px 0}h2{font-size:22px}.grid{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:18px}a{color:inherit;text-decoration:none}img{width:100%;border-radius:12px;box-shadow:0 8px 22px #13255416}span{display:block;margin-top:14px;font-size:14px}p{color:#626f89;line-height:1.6}.links{display:flex;gap:24px}@media(max-width:900px){body{padding:24px}.grid{grid-template-columns:repeat(3,minmax(0,1fr))}}@media(max-width:500px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}</style><header><small>TCON MAKER / BY SEOLIN</small><h1>App Store 홍보 이미지</h1><p>실제 앱 화면에 기능별 제목과 설명을 더한 최종 이미지입니다.<br>각 기기 폴더에서 01–07 순서로 업로드하세요. 원본 캡처는 Captures 폴더에 보관되어 있습니다.</p><div class="links"><a href="Source/promotion.html">디자인 원본</a><a href="Captures/index.html">원본 캡처</a><a href="README.md">제작·업로드 안내</a></div></header>${sections}</html>`);
 // A compact, readable overview rendered from the same final PNGs.
 for(const [device] of devices){
  const cards=manifest.filter(m=>m.file.includes(device));
  const ipad=device.startsWith('iPad');
  const thumbW=ipad?320:270;
  const thumbH=cards[0].height/cards[0].width*thumbW;
  const overviewW=4*thumbW+5*24,overviewH=Math.ceil(2*thumbH+3*24);
  await page.setViewportSize({width:overviewW,height:overviewH});
  await page.setContent(`<html><style>*{box-sizing:border-box}body{margin:0;background:#e9edf5;padding:24px;display:grid;grid-template-columns:repeat(4,${thumbW}px);gap:24px}img{width:${thumbW}px;display:block;box-shadow:0 4px 15px #18275e18}</style>${cards.map(()=>'<img>').join('')}</html>`);
  const sources=await Promise.all(cards.map(async m=>'data:image/png;base64,'+(await fs.readFile(path.join(dir,m.file))).toString('base64')));
  await page.evaluate(sources=>{[...document.images].forEach((image,i)=>image.src=sources[i]);},sources);
  await page.waitForFunction(()=>[...document.images].every(i=>i.complete&&i.naturalWidth>0));
  await fs.mkdir(path.join(dir,'Overview'),{recursive:true});
  await fs.writeFile(path.join(dir,'Overview',`${device}.jpg`),await sharp(await page.screenshot()).jpeg({quality:92}).toBuffer());
 }
 console.log(`Validated ${manifest.length} opaque RGB PNGs and 3 overview sheets.`);
} finally {await browser.close();}
