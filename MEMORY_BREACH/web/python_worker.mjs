// Python is loaded only after the first command; it runs off the game thread.
const CDN = 'https://cdn.jsdelivr.net/pyodide/v314.0.7/full/';
let interpreter = null;
let evaluate = null;
let loading = null;
async function initialize(){
    if(interpreter)return;
    if(!loading){
        loading=(async()=>{
            const module=await import(CDN+'pyodide.mjs');
            interpreter=await module.loadPyodide({indexURL:CDN,stdout:()=>{},stderr:()=>{}});
            const response=await fetch(new URL('browser_eval.py',import.meta.url));
            if(!response.ok)throw new Error('Python evaluator could not be downloaded.');
            interpreter.runPython(await response.text());
            evaluate=interpreter.globals.get('_memory_breach_eval');
        })();
    }
    await loading;
}
self.onmessage=async(event)=>{
    const {id,code,a,b}=event.data;
    try{
        if(!interpreter)self.postMessage({id,phase:'loading',output:'[PYTHON] Loading browser Python on first use. Combat and the sector timer wait during this download.'});
        await initialize();
        self.postMessage({id,phase:'ready',output:'[PYTHON] Runtime ready. Executing command...'});
        const result=JSON.parse(evaluate(code,a,b));
        self.postMessage({id,phase:'result',...result});
    }catch(error){
        self.postMessage({id,phase:'result',ok:false,numeric:null,fatal:!evaluate,output:'Python initialization/execution failed: '+String(error.message||error)});
    }
};
