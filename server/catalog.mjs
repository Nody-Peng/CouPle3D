import fs from "node:fs";
export const CATALOG = [
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

