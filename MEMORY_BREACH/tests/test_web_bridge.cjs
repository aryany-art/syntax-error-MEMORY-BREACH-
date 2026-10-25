const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const workers=[],timers=new Map();
let next=0;
class Worker{
 constructor(url,options){this.url=url;this.options=options;workers.push(this);}
 postMessage(value){this.sent=value;}
 terminate(){this.terminated=true;}
}
const context={window:{},document:{currentScript:{src:'https://example.invalid/repo/play/python_bridge.js'}},URL,Worker,console,
 setTimeout:(callback,delay)=>{timers.set(++next,{callback,delay});return next;},
 clearTimeout:id=>timers.delete(id)};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../web/python_bridge.js'),'utf8'),context);
const results=[],run=context.window.memoryBreachPythonRun;
assert.equal(workers.length,0);
assert.equal(run('print(a^b)',13,7,1,value=>results.push(JSON.parse(value))),true);
assert.equal(workers[0].options.type,'module');
assert.equal(run('blocked',0,0,2,()=>{}),false);
workers[0].onmessage({data:{id:1,phase:'ready',output:'ready'}});
assert.equal([...timers.values()][0].delay,5000);
workers[0].onmessage({data:{id:0,phase:'result',ok:true}});
assert.equal(results.length,1);
workers[0].onmessage({data:{id:1,phase:'result',ok:true,numeric:10,output:'10'}});
assert.equal(results.at(-1).numeric,10);
assert.equal(timers.size,0);
assert(run('while True: pass',0,0,3,value=>results.push(JSON.parse(value))));
assert.equal(workers.length,1);
[...timers.values()][0].callback();
assert(workers[0].terminated);
assert(results.at(-1).output.includes('5 seconds'));
assert(run('retry',0,0,4,value=>results.push(JSON.parse(value))));
assert.equal(workers.length,2);
workers[1].onmessage({data:{id:4,phase:'result',ok:false,fatal:true}});
assert(workers[1].terminated);
context.window.memoryBreachPythonCancel();
assert.equal(timers.size,0);
console.log('PASS: lazy worker, request serialization, IDs, timeout, failure recovery and cleanup');
assert(context.window.memoryBreachPythonSubmit({id:5,code:'print(2+3)',a:1,b:2}));
const queuedWorker=workers.at(-1);
queuedWorker.onmessage({data:{id:5,phase:'ready',output:'ready'}});
queuedWorker.onmessage({data:{id:5,phase:'result',ok:true,numeric:5,output:'5'}});
assert.equal(JSON.parse(context.window.memoryBreachPythonPoll()).phase,'ready');
assert.equal(JSON.parse(context.window.memoryBreachPythonPoll()).numeric,5);
assert.equal(context.window.memoryBreachPythonPoll(),'');
context.window.memoryBreachPythonCancel();
console.log('PASS: polled game queue preserves progress and result messages');
