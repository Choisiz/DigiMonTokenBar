import {describe,it,expect} from 'vitest';
import {species,byId,next,missingDescendants,patternStyle,total,name} from '../src/catalog';
describe('original catalog integration',()=>{
 it('retains all unique original species and valid evolution destinations',()=>{expect(species).toHaveLength(475);expect(byId.size).toBe(475);for(const s of species)for(const id of next(s.id))expect(byId.has(id)).toBe(true)});
 it('uses Korean character names',()=>{expect(name(2003)).toBe('아구몬')});
 it('stops traversing cycles when the collection is complete',()=>{for(const s of species)expect(missingDescendants(s.id,species.map(s=>s.id))).toBe(false)});
 it('detects undiscovered routes from the starter',()=>{expect(missingDescendants(2003,[2003])).toBe(true)});
 it('includes both original circuit and binary patterns',()=>{const p=patternStyle as Record<string,string>;expect(p['--circuit']).toContain('data:image/svg+xml');expect(p['--binary']).toContain('data:image/svg+xml');expect(p['--circuit']).not.toBe(p['--binary'])});
 it('counts each displayed token bucket once',()=>{expect(total({input:10,output:20,cacheRead:30,cacheWrite:40})).toBe(100)});
});

import shopItems from '../src/shop.json';
import {readFileSync} from 'node:fs';
it('matches the original Swift shop names and image keys',()=>{const labels=readFileSync(new URL('../../Sources/PokeTokenBar/Core/Localization.swift',import.meta.url),'utf8');const model=readFileSync(new URL('../../Sources/PokeTokenBar/Core/CompanionModel.swift',import.meta.url),'utf8');expect(shopItems).toHaveLength(14);for(const item of shopItems){expect(labels).toContain('"'+item.name+'"');if(item.asset.startsWith('capsule-'))expect(model).toContain('"'+item.asset.slice(8)+'"');else expect(item.asset==='evolution-tag'||model.includes('"'+item.asset+'"')).toBe(true)}});
