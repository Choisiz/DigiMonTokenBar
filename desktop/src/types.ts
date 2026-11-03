export interface CaptureRecord{id:string;speciesId:number;path:number[];caughtAt:string|null;status:string}
export interface Partner {speciesId:number;path:number[];progress:number;selected:number|null;continuing:boolean;boost:boolean;startedAt?:string|null}
export interface Settings {language?:"ko"|"en";representativeId?:number|null;refreshInterval?:number;animationQuality?:"powerSaver"|"balanced"|"smooth";limitDisplayMode?:"used"|"remaining";difficulty:number;shopDifficulty:number;motion:boolean;showPet:boolean;petTopmost:boolean;codexRoots:string[];claudeRoots:string[]}
export interface Game {version:number;active:Partner|null;stored:Partner|null;eggProgress:number;earned:number;spent:number;collected:number[];specialCollected?:number[];inventory:Record<string,number>;ledger:Record<string,number>;initialized:string[];history:string[];captureLog?:CaptureRecord[];settings:Settings}
export interface Bucket{input:number;output:number;cacheRead:number;cacheWrite:number}
export interface Provider{provider:string;files:number;today:Bucket;week:number;month:number;days:Record<string,number>}
export interface Usage{providers:Provider[];warnings:string[];updatedAt:string;roots:Record<string,string[]>}
export interface Item{id:string;name:string;price:number;description:string}
export interface Snapshot{game:Game;usage:Usage;threshold:number;choices:number[];ready:number[];shop:Item[];demo:boolean;savePath:string;error:string|null}
export interface Action{kind:string;id?:number;item?:string;count?:number;settings?:Settings}
export interface Species{id:number;gameID:number;name:string;stage:number;generation:string;next:number[];source:string}
export interface Rule{source:number;target:number;kind:string;ingredients:number[];item?:string;dailyTokens?:number}
