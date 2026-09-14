import fs from "node:fs";
export const CATALOG = [
  {"id":"outfit_cream","name":"奶油針織背心","type":"outfit","price":0,"color":"#ead9b9","description":"免費領取的約會入門款，搭配細緻鈕扣與口袋。"},
  {"id":"outfit_rose","name":"莓果短外套","type":"outfit","price":35,"color":"#c87989","description":"奶油翻領與金色鈕扣，溫柔的莓果色。"},
  {"id":"outfit_sailor","name":"海風水手領","type":"outfit","price":40,"color":"#526984","description":"象牙白上衣搭配海軍藍領片。"},
  {"id":"outfit_mint","name":"薄荷圍巾套裝","type":"outfit","price":30,"color":"#78aaa0","description":"燕麥色背心與柔軟薄荷圍巾。"},
  {"id":"outfit_lilac","name":"丁香約會外套","type":"outfit","price":45,"color":"#a293bb","description":"淡紫短外套與胸前小蝴蝶結。"},
  {"id":"outfit_cocoa","name":"可可學院背心","type":"outfit","price":30,"color":"#92725e","description":"暖棕背心、奶油領口與雙口袋。"},
  {"id":"hat_bow","name":"莓果蝴蝶結","type":"hat","price":20,"color":"#c87989","description":"側戴雙層蝴蝶結，搭配每一款髮型。"},
  {"id":"hat_flower","name":"雛菊小花冠","type":"hat","price":30,"color":"#eedda4","description":"象牙白花瓣與嫩綠葉片。"},
  {"id":"bag_satchel","name":"焦糖約會側包","type":"bag","price":30,"color":"#b58a64","description":"小巧側背包，帶著喜歡出門。"},
  { id: 'hat_beret', name: '莓果貝雷帽', type: 'hat', price: 50, color: '#d58088', description: '今天也想和你穿得很可愛。' },
  { id: 'hat_bunny', name: '兔耳帽', type: 'hat', price: 90, color: '#eedfca', description: '一對搖搖晃晃的小耳朵。' },
  { id: 'glasses_round', name: '圓框眼鏡', type: 'glasses', price: 45, color: '#e6bc68', description: '金色細框，適合每一種造型。' },
  { id: 'bag_daypack', name: '薄荷小背包', type: 'bag', price: 65, color: '#69a99e', description: '把今天的約會回憶帶回家。' },
  { id: 'sofa_rose', name: '莓果雙人沙發', type: 'furniture', price: 110, color: '#d58088', width: 3, depth: 1.6 },
  { id: 'table_oak', name: '橡木小茶几', type: 'furniture', price: 65, color: '#bc9670', width: 1.5, depth: 1.5 },
  { id: 'plant_leaf', name: '窗邊小綠植', type: 'furniture', price: 35, color: '#69a99e', width: 0.8, depth: 0.8 },
];
export const BASES = ["female-a","female-b","female-c","female-d","female-e","female-f","male-a","male-b","male-c","male-d","male-e","male-f"];
export const ZONES = [
  { name: '客廳角落', x: -11.5, z: 7.5, width: 3, depth: 5 },
  { name: '遊戲室休息區', x: -3.8, z: 11, width: 7.6, depth: 3.7 },
  { name: '書房閱讀區', x: 10, z: 10, width: 7.5, depth: 3.5 },
];
export const GARDEN = [{x:-20,z:35},{x:-10,z:35},{x:12,z:35}];
export const CATALOG_MAP = Object.fromEntries(CATALOG.map(x => [x.id,x]));
export const QUIZ = [
  {title:'一起放假的早晨，你最想做什麼？',options:['睡到自然醒','出門吃早餐','去郊外散步','在家玩遊戲']},
  {title:'今天只能選一種約會，你會選？',options:['逛動物園','看夜景','一起煮飯','看電影']},
  {title:'想替我們的家添購什麼？',options:['舒服的沙發','滿滿的植物','一張大餐桌','可愛的裝飾']},
];

export const ZOO = JSON.parse(fs.readFileSync(new URL('../data/zoo.json',import.meta.url),'utf8').replace(/^\uFEFF/,''));

