# Korean Digimon names

Captured on 2026-10-17 from the official Digimon reference EN/KO public lists. The two language lists each contain 1,325 entries and are joined by `directory_name`. The app has 475 species. Exact names and existing DAPI aliases are matched without fuzzy matching; ambiguous directories and game modes are resolved by explicit catalog mappings.

The official site's non-Japanese pages use machine translation; names can differ from Korean anime/game releases. The selected label, reference directory and provenance are recorded per species in `Resources/Digimon/korean-names.json`. The original twelve app IDs, game IDs and DAPI IDs remain unchanged.

## Reviewed identities and exceptions

| App ID | Game name | Display name | Basis |
|---|---|---|---|
| 10086 | Gargomon | 가르고몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=galgomon) |
| 2004 | Greymon | 그레이몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=greymon-first) |
| 10198 | MegaKabuterimon | 아트라캅테리몬(레드) | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=atlurkabuterimon) |
| 10210 | Cyberdramon | 사이버드라몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=cyberdramon) |
| 2005 | MetalGreymon | 메탈그레이몬(백신종) | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=metalgreymon-v) |
| 10225 | Crowmon | 야타가라몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=yatagaramon_axcel) |
| 10227 | Rapidmon | 래피드몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=rapidmon) |
| 10230 | Scorpiomon | 스콜피오몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=anomalocarimon) |
| 10232 | Antylamon | 안티라몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=andiramon_2) |
| 10296 | Lucemon CM | 루체몬: 폴다운 모드 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=rucemonfalldownmode) |
| 10323 | Justimon | 저스티몬: 블리츠 암 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=justimon_blitzarm) |
| 10349 | Ceresmon Medium | 케레스몬메디움 | [official-profile](https://digimon.net/reference_ko/detail.php?directory_name=ceresmon) |
| 10390 | Bacchusmon DM | 바커스몬 (DM) | [base-name-original-suffix](https://digimon.net/reference_ko/detail.php?directory_name=bacchusmon) |
| 10409 | Merukimon | 메르크리몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=mercurymon) |
| 10422 | Rapidmon (Armor) | 래피드몬 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=rapidmon_gold) |
| 10426 | MagnaGarurumon (Detached) | 매그너가루몬 (Detached) | [base-name-original-suffix](https://digimon.net/reference_ko/detail.php?directory_name=magnagarurumon) |
| 10462 | Omnimon MM | 오메가몬: 머시풀 모드 | [reviewed-variant](https://digimon.net/reference_ko/detail.php?directory_name=omegamon_merciful) |

The `DM` and `Detached` suffixes are retained verbatim because separate official Korean mode titles were not confirmed. They are not claimed as complete official Korean localized names. Ceresmon Medium is named in the official Ceresmon profile.

## Runtime behavior

The bundled name catalog supplies Home, evolution choices, Notebook, detail pages and catch-log names. Existing cached names in a save do not hide updated catalog names. Both English and Korean catalog names remain searchable, including for older records. This is a presentation update, not a save migration.
