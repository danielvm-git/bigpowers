import { writeSync } from 'node:fs';
function fmt(l,e,d={}){return JSON.stringify({level:l,event:e,timestamp:new Date().toISOString(),...d})+'\n'}
export const log = {
  info(e,d={}){writeSync(2,fmt('info',e,d))},
  warn(e,d={}){writeSync(2,fmt('warn',e,d))},
  error(e,d={}){writeSync(2,fmt('error',e,d))},
  user(m){writeSync(1,m+'\n')},
};
