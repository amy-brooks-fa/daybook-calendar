import {HebrewCalendar, HDate, flags, gematriya} from '@hebcal/core';
const S=new Date(2025,0,1), E=new Date(2031,11,31);
const ev = HebrewCalendar.calendar({start:S, end:E, il:false, locale:'ashkenazi', noModern:true, noSpecialShabbat:true});
const skip=new Set(['Chag HaBanot','Sigd','Yom HaAliyah','Yom Kippur Katan']);
const H={};
const iso=d=>d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');
for (const e of ev){
  const f=e.getFlags(), desc=e.getDesc();
  if (f & (flags.MODERN_HOLIDAY|flags.SPECIAL_SHABBAT|flags.PARSHA_HASHAVUA)) continue;
  if (skip.has(desc)) continue;
  let n=e.render('ashkenazi').replace(/’’/g,'"').replace(/’/g,"'");
  n=n.replace(/^Rosh Hashana \d+$/,'Rosh Hashana I').replace(/\(CH"M\)/,'· Chol Hamoed').replace('Chanukah: 1 Candle','Chanukah: 1st light (tonight)')
     .replace(/Chanukah: (\d) Candles/,(m,k)=>'Chanukah · '+k+(k==2?'nd':k==3?'rd':'th')+' light').replace('Chanukah: 8th Day','Chanukah · 8th day');
  let t='m'; const isErev=/^Erev /.test(n);
  if (f & flags.CHAG) t='y'; else if (/^(Chanukah|Purim|Shushan Purim)/.test(n)) t='p'; else if (f & flags.CHOL_HAMOED) t='c'; else if (!isErev && (f & (flags.MINOR_FAST|flags.MAJOR_FAST))) t='f'; else if (f & flags.EREV) t='e'; else if (f & flags.ROSH_CHODESH) t='r';
  const k=iso(e.getDate().greg());
  (H[k]=H[k]||[]).push([n,t]);
}
// Hebrew month starts (day 1) for Hebrew date in each cell
const M=[]; let d=new Date(2024,11,1);
while(d<=E){ const h=new HDate(d); if(h.getDate()===1||M.length===0){ M.push([iso(d), h.getDate(), h.renderGematriya(true).split(' ').slice(1,-1).join(' ')]); } d.setDate(d.getDate()+1); }
import fs from 'fs';
fs.writeFileSync('jhol.js','/* Jewish holidays, diaspora (2-day Yom Tov), Ashkenazi spelling. Generated with @hebcal/core '+JSON.parse(fs.readFileSync('node_modules/@hebcal/core/package.json')).version+' on '+iso(new Date())+'. Range 2025-2031. */\nconst JHOL='+JSON.stringify(H)+';\nconst JHM='+JSON.stringify(M)+';\n');
console.log(Object.keys(H).length, M.length, M.slice(0,4), fs.statSync('jhol.js').size);
