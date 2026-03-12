# Endurunce — Huisstijl

> Versie 2.0 · Maart 2026

---

## Merkidentiteit

**Endurunce** is een AI-aangedreven trainingspartner voor hardlopers die leren omgaan met blessures, terugkomen na een pauze, of toewerken naar hun eerste (of snelste) race. De tone of voice is **motiverend maar eerlijk** — geen valse beloftes, wel echte begeleiding.

---

## Design Philosophy

**Warm & earthy light theme.** De app gebruikt een licht kleurenschema met warme, aardse tinten — geen donkere mode. Kleuren zijn geïnspireerd door natuur: mos, aarde, zand, hemel en lavendel.

---

## Kleurenpalet

### Primaire kleuren

| Naam        | Hex       | Gebruik                              |
|-------------|-----------|--------------------------------------|
| **Brand (Moss)** | `#5A7A52` | CTA-knoppen, highlights, progress |
| **Brand Deep (Sage)** | `#8AAB7E` | Hover-states, secundaire accenten |

### Achtergronden (licht, gelaagd)

| Naam              | Hex       | Gebruik                             |
|-------------------|-----------|-------------------------------------|
| Background (Bg)   | `#F7F3EE` | Warme beige canvas / scaffold       |
| Surface           | `#FFFCF8` | Kaarten, bottom sheets              |
| Surface High      | `#F0EBE3` | Invoervelden, chips, rijen          |
| Surface Higher    | `#E8E4DD` | Modals, dropdowns, tooltips         |

### Randen & dividers

| Naam          | Hex       |
|---------------|-----------|
| Outline       | `#E2D9CE` |
| Outline High  | `#C9BFB3` |

### Tekst

| Naam      | Hex       | Gebruik                        |
|-----------|-----------|--------------------------------|
| On Bg (Ink)       | `#2D2720` | Primaire tekst                 |
| On Surface (Ink Mid) | `#7A6E64` | Secundaire tekst, labels    |
| Muted (Ink Light)    | `#A89E93` | Placeholders, hints, metadata |
| Disabled  | `#C9BFB3` | Uitgeschakelde elementen       |

### Semantisch

| Naam        | Hex       | Dim        | Gebruik                          |
|-------------|-----------|------------|----------------------------------|
| Success     | `#5A7A52` | `#DEEBD8`  | Voltooide sessies, hersteld     |
| Warning     | `#C49A5A` | `#F5E8CC`  | Gemiddelde blessure-ernst (4–6) |
| Error       | `#B85C3A` | `#F5DDD5`  | Hoge blessure-ernst, fouten     |

### Accenten

| Naam       | Hex       | Dim        | Gebruik               |
|------------|-----------|------------|-----------------------|
| Terra      | `#B85C3A` | `#F5DDD5`  | Waarschuwing, tempo   |
| Sand       | `#C49A5A` | `#F5E8CC`  | Informatief, cross    |
| Sky        | `#4A7FA0` | `#D6E8F5`  | Lange duurloop        |
| Lavender   | `#7A6AAA` | `#E8E3F5`  | Trail, wandel         |
| Stone      | `#9E9488` | `#EDE8E2`  | Rustdag, disabled     |
| Gold       | `#B8862A` | `#F5E8C0`  | Race day, beloning    |
| Strava     | `#FC4C02` | `#FEE8DF`  | Strava integratie     |

### Sessie-kleuren

| Type       | Naam      | Hex       | Dim        |
|------------|-----------|-----------|------------|
| Easy       | Moss      | `#5A7A52` | `#DEEBD8`  |
| Tempo      | Terra     | `#B85C3A` | `#F5DDD5`  |
| Long       | Sky       | `#4A7FA0` | `#D6E8F5`  |
| Interval   | Intens    | `#C0392B` | `#F5DDD5`  |
| Hike       | Lavender  | `#7A6AAA` | `#E8E3F5`  |
| Cross      | Sand      | `#C49A5A` | `#F5E8CC`  |
| Race       | Gold      | `#B8862A` | `#F5E8C0`  |
| Rest       | Stone     | `#9E9488` | `#EDE8E2`  |

---

## Typografie

Het systeem gebruikt de standaard platformfont (Inter op Android/web, SF Pro op iOS). Geen custom fonts nodig — M3 typography scale wordt volledig benut.

### Hiërarchie

| Stijl          | Grootte | Gewicht | Gebruik                          |
|----------------|---------|---------|----------------------------------|
| Display Large  | 57px    | 400     | —                                |
| Headline Large | 32px    | 700     | Paginatitels                     |
| Headline Medium| 28px    | 700     | Secties, plan-namen              |
| Headline Small | 24px    | 600     | Card-titels, modals              |
| Title Large    | 22px    | 600     | AppBar titels                    |
| Title Medium   | 16px    | 600     | Lijst-items, week-nummers        |
| Title Small    | 14px    | 600     | Labels in cards                  |
| Body Large     | 16px    | 400     | Primaire inhoud                  |
| Body Medium    | 14px    | 400     | Secundaire inhoud                |
| Body Small     | 12px    | 400     | Metadata, timestamps             |
| Label Large    | 14px    | 600     | Knopteksten                      |
| Label Medium   | 12px    | 500     | Chips, badges                    |
| Label Small    | 11px    | 500     | Uppercase labels, letter-spacing |

Uppercase labels altijd met `letterSpacing: 1.5`.

---

## Iconografie

Gebruik uitsluitend **Material Icons** (Outlined variant als standaard, Filled voor selected state).

Voorkeursiconen per functie:
- Login / Auth: `mail_outline`, `lock_outline`, `visibility_outlined`
- Training: `directions_run`, `route_outlined`, `flag_outlined`
- Blessures: `healing`, `healing_outlined`, `report_outlined`
- Navigatie: `chevron_right`, `arrow_forward`, `expand_more`
- Acties: `check_circle_outline`, `add`, `rocket_launch_outlined`

---

## Componenten

### Knoppen

| Type           | Gebruik                              | Kleur          |
|----------------|--------------------------------------|----------------|
| `FilledButton` | Primaire CTA (opslaan, volgende)     | Moss green     |
| `OutlinedButton`| Secundaire acties, OAuth-knoppen   | Outline border |
| `TextButton`   | Inline links, navigatie              | Moss green     |
| `FloatingActionButton` | Blessure melden             | Moss green     |

Alle knoppen: `borderRadius: 99px` (pill), minimale hoogte `52px`, breedte `double.infinity`.

### Cards

- Achtergrond: `AppColors.surface` (`#FFFCF8`)
- Border: `AppColors.outline` (`#E2D9CE`, 1px)
- Border radius: `16px`
- Geen `elevation` (flat design, border als scheiding)
- Bij selected/active state: border naar accent-kleur

### Input fields

- Filled style: achtergrond `AppColors.surfaceHigh` (`#F0EBE3`)
- Border radius: `10px`
- Focus border: `AppColors.brand` (`#5A7A52`, 2px)
- Altijd `prefixIcon` waar van toepassing

### Bottom sheets

- Achtergrond: `AppColors.surface` (`#FFFCF8`)
- Border radius top: `28px`
- Drag handle (40×4px, `AppColors.outlineHigh`)
- Gebruik `DraggableScrollableSheet` voor lange content

### Badges / Chips

- Border radius: `99px` (pill)
- Kleur: accent `withValues(alpha: .15)` als achtergrond, accent als tekstkleur
- Gewicht: 700

---

## Ruimte & ritme

| Token    | Waarde | Gebruik                              |
|----------|--------|--------------------------------------|
| xs       | 4px    | Tussen icon en tekst                 |
| sm       | 8px    | Tussen gerelateerde elementen        |
| md       | 12–14px| Padding in compacte cards            |
| base     | 16px   | Standaard padding, kolomgutters      |
| lg       | 20–24px| Card padding, secties                |
| xl       | 28–32px| Tussen secties                       |
| xxl      | 48px   | Boven hero-sectie op auth-schermen   |

---

## Animaties

- **Duur**: 150ms voor micro-interacties (hover, select), 300ms voor transities
- **Easing**: `Curves.easeInOut`, `Curves.easeOutCubic`
- Gebruik `AnimatedContainer` voor kleur/grootte-overgangen op touch
- Geen overdreven animaties — zakelijk en snel

---

## Logo

Het logo bestaat uit twee componenten:

1. **App icon** — vierkant met mos-groen/sage gradiënt, witte rennende figuur met kuitverband
2. **Wordmark** — "**Endur**<moss>unce</moss>" in bold (gewicht 800, letter-spacing -1.0)

### Gebruik
- Lichte achtergrond: gebruik standaard wordmark
- Donkere achtergrond: gebruik `logo-white.svg`
- Minimale grootte icon: 32×32px
- Minimale clearspace: 8px rondom

---

## Navigatie

De app gebruikt **Material 3 NavigationBar** (bottom) met twee tabs:

| Tab        | Icon (default/selected)                    |
|------------|--------------------------------------------|
| Training   | `directions_run_outlined` / `directions_run` |
| Blessures  | `healing_outlined` / `healing`             |

Geselecteerde staat: moss green indicator + label.

---

## Tone of voice

- **Direct**: geen ingewikkeld jargon, spreek de gebruiker aan als "je/jij"
- **Positief**: focus op wat kan, niet op beperkingen
- **Empathisch**: blessures zijn frustrerend — erken dat
- **Actiegericht**: elke melding of feedback leidt tot een concrete vervolgstap

### Woordgebruik
- ✅ "Sessie afronden" (niet "Opslaan")
- ✅ "Jouw plan" (niet "Het plan")
- ✅ "Markeren als hersteld" (niet "Verwijderen")
- ✅ "Plan aanmaken" (niet "Genereer schema")

---

## Platform-specifiek

### Android
- Status bar: transparant, donkere iconen (licht thema)
- Navigatiebar: transparant of matcht `AppColors.bg`

### Web
- Maximale breedte formulieren: 480px (gecentreerd)
- Hover states op interactieve elementen

### iOS
- Zelfde kleurpalet, iOS-specifieke fonts automatisch via Flutter
