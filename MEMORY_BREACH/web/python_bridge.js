(function(){
'use strict';
const scriptURL=new URL(document.currentScript.src);
const workerAddress=new URL('python_worker.mjs',scriptURL);
workerAddress.search=scriptURL.search;
const workerURL=workerAddress.href;
let queue=[];
let worker=null;
let active=null;
let ready=false;
function deliver(message){
    if(active&&message.id===active.id){
        try{active.callback(JSON.stringify(message));}catch(error){console.warn('Python callback unavailable',error);}
    }
}
function reset(){
    if(active)clearTimeout(active.timer);
    if(worker)worker.terminate();
    worker=null;
    active=null;
    ready=false;
}
function fail(message){
    if(active)deliver({id:active.id,phase:'result',ok:false,numeric:null,output:message});
    reset();
}
function arm(milliseconds){
    clearTimeout(active.timer);
    active.timer=setTimeout(()=>fail(ready?
        'Execution exceeded 5 seconds. Python stopped; variables reset on the next command.':
        'Browser Python could not load in time. Check your connection and try again.'),milliseconds);
}
window.memoryBreachPythonRun=function(code,a,b,id,callback){
    if(active)return false;
    active={id,callback,timer:null};
    try{
        if(!worker){
            worker=new Worker(workerURL,{type:'module',name:'memory-breach-python'});
            worker.onmessage=function(event){
                const message=event.data;
                if(!active||message.id!==active.id)return;
                if(message.phase==='ready'){
                    ready=true;
                    arm(5000);
                }
                deliver(message);
                if(message.phase==='result'){
                    clearTimeout(active.timer);
                    active=null;
                    if(message.fatal){worker.terminate();worker=null;ready=false;}
                }
            };
            worker.onerror=function(event){
                fail('Browser Python could not start. Check your connection or browser settings, then retry. '+(event.message||''));
            };
        }
        arm(ready?5000:120000);
        worker.postMessage({id,code,a,b});
        return true;
    }catch(error){
        fail('Browser Python is unavailable: '+String(error.message||error));
        return false;
    }
};
window.memoryBreachPythonSubmit=function(request){
 return window.memoryBreachPythonRun(String(request.code),Number(request.a),Number(request.b),Number(request.id),
  message=>queue.push(message));
};
window.memoryBreachPythonPoll=function(){return queue.length?queue.shift():'';};
window.memoryBreachPythonCancel=function(){reset();queue=[];};
})();
