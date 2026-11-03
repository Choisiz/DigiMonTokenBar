import {describe,it,expect} from 'vitest';
import {canContinueSpecies,missingDescendants,species} from '../src/catalog';
import type {Game} from '../src/types';
function game():Game{return{version:2,active:{speciesId:2003,path:[2001,2002,2003],progress:0,selected:null,continuing:false,boost:false},stored:null,eggProgress:0,earned:0,spent:0,collected:[2001,2002,2003,10300],inventory:{},ledger:{},initialized:[],history:[],captureLog:[],settings:{difficulty:1,shopDifficulty:1,motion:true,showPet:false,petTopmost:true,codexRoots:[],claudeRoots:[]}}}
describe('special continuation availability',()=>{
 it('never offers a merely collected ordinary form',()=>{const g=game();expect(missingDescendants(2001,g.collected)).toBe(true);expect(canContinueSpecies(g,2001)).toBe(false)});
 it('supports old saves with registered capture records',()=>{const g=game();g.captureLog=[{id:'special',speciesId:10300,path:[10300],caughtAt:null,status:'registered'}];expect(missingDescendants(10300,g.collected)).toBe(true);expect(canContinueSpecies(g,10300)).toBe(true)});
 it('supports durable special markers after old records roll off',()=>{const g=game();g.specialCollected=[10300];expect(canContinueSpecies(g,10300)).toBe(true)});
 it('excludes the active and parked training base',()=>{const g=game();g.specialCollected=[10300];g.active={...g.active!,speciesId:10300,path:[10300]};expect(canContinueSpecies(g,10300)).toBe(false);g.stored=g.active;g.active={...g.active,speciesId:2003,path:[2003]};expect(canContinueSpecies(g,10300)).toBe(false)});
 it('does not offer a completed collection',()=>{const g=game();g.specialCollected=[10300];g.collected=species.map(mon=>mon.id);expect(canContinueSpecies(g,10300)).toBe(false)});
});