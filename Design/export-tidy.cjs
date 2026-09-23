// Render static deliverables from the same screen components as the prototype.
const {chromium}=require(process.env.PLAYWRIGHT_PATH || '/Users/shurashipai/.npm/_npx/420ff84f11983ee5/node_modules/playwright');
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
(async()=>{
  const browser=await chromium.launch({executablePath:process.env.BROWSER_PATH||'/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',headless:true});
  const page=await browser.newPage({viewport:{width:1440,height:1100},deviceScaleFactor:1});
  await page.goto(pathToFileURL(path.resolve('tidy_design.html')).href);
  await page.evaluate(async()=>{await document.fonts.ready;for(const img of document.images)img.loading='eager';await Promise.all([...document.images].map(img=>img.decode().catch(()=>{})));document.getElementById('board').style.zoom=1;});
  fs.mkdirSync('exports/screens',{recursive:true});
  const screens=await page.evaluate(()=>Tidy.definitions.map((d,i)=>({id:d.id,title:d.title,index:i+1})));
  const capture=await browser.newPage({viewport:{width:393,height:852},deviceScaleFactor:1});
  await capture.goto(pathToFileURL(path.resolve('tidy_design.html')).href);
  await capture.evaluate(()=>document.fonts.ready);
  const only=process.argv.find(arg=>arg.startsWith('--only='))?.slice(7);
  for(const s of screens.filter(s=>!only||s.id===only)){
    const html=await page.locator(`[data-screen="${s.id}"] .screen`).evaluate(el=>el.outerHTML);
    await capture.evaluate(async html=>{document.body.innerHTML=html;document.body.style.cssText='margin:0;padding:0;width:393px;height:852px;overflow:hidden';window.scrollTo(0,0);for(const img of document.images)img.loading='eager';await Promise.all([...document.images].map(img=>img.decode().catch(()=>{})));},html);
    const file=`exports/screens/${String(s.index).padStart(2,'0')}-${s.id}.png`;
    const png=await capture.screenshot({path:file});
    if(png.readUInt32BE(16)!==393||png.readUInt32BE(20)!==852)throw Error(`Incorrect exported dimensions: ${file}`);
  }
  await capture.close();
  await page.evaluate(()=>{document.getElementById('board').style.zoom=.5;window.scrollTo(0,0);});
  await page.screenshot({path:'exports/complete-flow-board.png',fullPage:true});
  await page.setViewportSize({width:393,height:1180});
  await page.evaluate(()=>{Tidy.openPrototype('welcome');document.querySelector('.toast')?.remove();});
  await page.screenshot({path:'.impeccable/review/mobile.png'});
  console.log(`Exported ${screens.length} raw 393 × 852 PNG screens and the full flow board.`);
  await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
