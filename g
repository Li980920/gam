<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<title>魔法小镇探险 - 增强版</title>
<style>
  body { margin: 0; overflow: hidden; background: #a0d8f0; }
  canvas { display: block; margin: auto; background: #87ceeb; }
  #joystick { position: fixed; bottom: 20px; left: 20px; width: 100px; height: 100px; border-radius: 50%; background: rgba(0,0,0,0.2); touch-action: none;}
  #stick { position: absolute; width: 40px; height: 40px; border-radius: 50%; background: rgba(0,0,255,0.5); left: 30px; top: 30px; }
  #info { position: fixed; top: 10px; left: 10px; color: black; font-family: sans-serif; font-size: 16px; }
</style>
</head>
<body>
<canvas id="gameCanvas" width="800" height="600"></canvas>
<div id="joystick"><div id="stick"></div></div>
<div id="info"></div>

<script>
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
const info = document.getElementById('info');

// --- 玩家 ---
const player = { x: 400, y: 300, size: 40, color: 'blue', speed: 4, hp: 100, maxHp: 100, exp: 0, level: 1, inventory: [] };

// --- 道具 ---
const items = [];
for(let i=0;i<8;i++){
  items.push({x:Math.random()*760+20, y:Math.random()*560+20, size:20, color:'green', name:'魔法材料'});
}

// --- 怪物 ---
const monsters = [];
for(let i=0;i<5;i++){
  monsters.push({x:Math.random()*770+15, y:Math.random()*570+15, size:30, color:'red', hp:30, alive:true, name:'小怪'+(i+1)});
}

// --- NPC ---
const npcs = [
  { x: 100, y: 100, size: 30, color: 'yellow', name: '老魔导师', dialogue: '完成任务可获得奖励哦！', taskCompleted:false },
  { x: 700, y: 500, size: 30, color: 'yellow', name: '商店老板', dialogue: '欢迎来到商店！', taskCompleted:false }
];

// --- 摇杆控制 ---
let dx=0, dy=0;
const stick = document.getElementById('stick');
const joystick = document.getElementById('joystick');

joystick.addEventListener('pointerdown', (e)=>{ stick.setPointerCapture(e.pointerId); });
joystick.addEventListener('pointermove', (e)=>{
  const rect = joystick.getBoundingClientRect();
  const cx = rect.width/2;
  const cy = rect.height/2;
  let tx = e.clientX - rect.left - cx;
  let ty = e.clientY - rect.top - cy;
  const dist = Math.sqrt(tx*tx + ty*ty);
  const maxDist = 40;
  if(dist>maxDist){ tx = tx/dist*maxDist; ty = ty/dist*maxDist; }
  stick.style.left = (tx+cx-20)+'px';
  stick.style.top = (ty+cy-20)+'px';
  dx = tx/10; dy = ty/10;
});
joystick.addEventListener('pointerup', ()=>{ dx=0; dy=0; stick.style.left='30px'; stick.style.top='30px'; });

// --- 游戏循环 ---
function gameLoop(){
  // --- 更新玩家位置 ---
  player.x += dx;
  player.y += dy;
  player.x = Math.max(0, Math.min(canvas.width - player.size, player.x));
  player.y = Math.max(0, Math.min(canvas.height - player.size, player.y));

  // --- 道具拾取 ---
  for(let i=items.length-1;i>=0;i--){
    const it = items[i];
    if(Math.abs(player.x-it.x)<(player.size+it.size)/2 && Math.abs(player.y-it.y)<(player.size+it.size)/2){
      player.inventory.push(it.name);
      items.splice(i,1);
      player.exp += 10;
      if(player.exp >= player.level*50){ player.level++; player.hp=player.maxHp; player.exp=0; }
      console.log('收集了: '+it.name,'背包:',player.inventory);
    }
  }

  // --- 怪物战斗 ---
  for(let m of monsters){
    if(m.alive && Math.abs(player.x-m.x)<(player.size+m.size)/2 && Math.abs(player.y-m.y)<(player.size+m.size)/2){
      m.hp -= 10;
      player.exp += 5;
      if(m.hp<=0){ m.alive=false; console.log(m.name+' 被击败'); }
    }
  }

  // --- NPC 互动 ---
  let npcText = '';
  for(let n of npcs){
    if(Math.abs(player.x-n.x)<(player.size+n.size)/2 && Math.abs(player.y-n.y)<(player.size+n.size)/2){
      npcText = n.dialogue;
      if(!n.taskCompleted && items.length===0){
        npcText += ' 任务完成！奖励经验50！';
        player.exp += 50;
        n.taskCompleted = true;
        if(player.exp >= player.level*50){ player.level++; player.hp=player.maxHp; player.exp=0; }
      }
    }
  }

  // --- 绘制 ---
  ctx.clearRect(0,0,canvas.width,canvas.height);
  // 绘制地图格子
  ctx.fillStyle='#d4f0c0';
  for(let i=0;i<canvas.width;i+=40){
    for(let j=0;j<canvas.height;j+=40){
      ctx.strokeRect(i,j,40,40);
    }
  }

  // 绘制道具
  for(let it of items){ ctx.fillStyle=it.color; ctx.fillRect(it.x-it.size/2,it.y-it.size/2,it.size,it.size); }
  // 绘制怪物
  for(let m of monsters){ if(m.alive){ ctx.fillStyle=m.color; ctx.fillRect(m.x-m.size/2,m.y-m.size/2,m.size,m.size); } }
  // 绘制NPC
  for(let n of npcs){ ctx.fillStyle=n.color; ctx.fillRect(n.x-n.size/2,n.y-n.size/2,n.size,n.size); }
  // 绘制玩家
  ctx.fillStyle=player.color; ctx.fillRect(player.x-player.size/2,player.y-player.size/2,player.size,player.size);

  // --- HUD ---
  ctx.fillStyle='red'; ctx.fillRect(10,10,player.hp*2,20);
  info.innerText = `等级: ${player.level} 经验: ${player.exp}\n背包: ${player.inventory.join(', ')}\n${npcText}`;

  requestAnimationFrame(gameLoop);
}

gameLoop();
</script>
</body>
</html>
