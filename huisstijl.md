# Endurunce — Huisstijl

> Versie 1.0 · Maart 2026

---

## Merkidentiteit

**Endurunce** is een AI-aangedreven trainingspartner voor hardlopers die leren omgaan met blessures, terugkomen na een pauze, of toewerken naar hun eerste (of snelste) race. De tone of voice is **motiverend maar eerlijk** — geen valse beloftes, wel echte begeleiding.

---

## Kleurenpalet

### Primaire kleuren

| Naam        | Hex       | Gebruik                              |
|-------------|-----------|--------------------------------------|
| **Brand**   | `#FF7043` | CTA-knoppen, highlights, progress    |
| **Brand Deep** | `#E53935` | Accenten, gradiënten, race sessions |

### Achtergronden (donker systeem)

| Naam              | Hex       | Gebruik                             |
|-------------------|-----------|-------------------------------------|
| Canvas            | `#0D0D16` | Scaffold background                 |
| Surface           | `#14141E` | Cards, bottom sheets                |
| Surface High      | `#1C1C2A` | Elevated cards, input fields        |
| Surface Higher    | `#242436` | Modals, dropdowns, tooltips         |

### Randen & dividers

| Naam          | Hex       |
|---------------|-----------|
| Outline       | `#2A2A3C` |
| Outline High  | `#3A3A50` |

### Tekst

| Naam      | Hex       | Gebruik                        |
|-----------|-----------|--------------------------------|
| On Bg     | `#EEEEF8` | Primaire tekst                 |
| On Surface| `#CCCCDC` | Secundaire tekst, labels       |
| Muted     | `#7070A0` | Placeholders, hints, metadata  |
| Disabled  | `#44445A` | Uitgeschakelde elementen       |

### Semantisch

| Naam        | Hex       | Gebruik                         |
|-------------|-----------|----------------------------------|
| Success     | `#4CAF82` | Voltooide sessies, hersteld      |
| Warning     | `#FFC107` | Gemiddelde blessure-ernst (4–6)  |
| Error       | `#EF5350` | Hoge blessure-ernst (7–10), fouten |

### Sessie-kleuren

| Type       | Kleur     | Hex       |
|------------|-----------|-----------|
| Easy       | Mint      | `#4CAF82` |
| Tempo      | Oranje    | `#FF7043` |
| Long       | Blauw     | `#5BA4D4` |
| Interval   | Rood      | `#EF5350` |
| Hike       | Paars     | `#B39DDB` |
| Cross      | Geel      | `#FFCA28` |
| Race       | Goud      | `#FFD54F` |
| Rest       | Grijs     | `#6E6E9E` |

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
| `FilledButton` | Primaire CTA (opslaan, volgende)     | Brand orange   |
| `OutlinedButton`| Secundaire acties, OAuth-knoppen   | Outline border |
| `TextButton`   | Inline links, navigatie              | Brand orange   |
| `FloatingActionButton` | Blessure melden             | Brand orange   |

Alle knoppen: `borderRadius: 14px`, minimale hoogte `52px`, breedte `double.infinity`.

### Cards

- Achtergrond: `AppColors.surface`
- Border: `AppColors.outline` (1px)
- Border radius: `16–20px`
- Geen `elevation` (flat design, border als scheiding)
- Bij selected/active state: border naar accent-kleur

### Input fields

- Filled style: achtergrond `AppColors.surfaceHigh`
- Border radius: `12px`
- Focus border: `AppColors.brand` (2px)
- Altijd `prefixIcon` waar van toepassing

### Bottom sheets

- Achtergrond: `AppColors.surfaceHigh`
- Border radius top: `28px`
- Drag handle (40×4px, `AppColors.outlineHigh`)
- Gebruik `DraggableScrollableSheet` voor lange content

### Badges / Chips

- Border radius: `6–10px`
- Kleur: accent `withOpacity(.15)` als achtergrond, accent als tekstkleur
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
- **Easing**: `Curves.easeInOut`
- Gebruik `AnimatedContainer` voor kleur/grootte-overgangen op touch
- Geen overdreven animaties — zakelijk en snel

---

## Logo

Het logo bestaat uit twee componenten:

1. **App icon** — vierkant met oranje/rood gradiënt, witte rennende figuur met kuitverband
2. **Wordmark** — "**Endur**<orange>unce</orange>" in bold (gewicht 800, letter-spacing -1.0)

### Gebruik
- Donkere achtergrond: gebruik standaard wordmark
- Witte/lichte achtergrond: gebruik `logo-white.svg`
- Minimale grootte icon: 32×32px
- Minimale clearspace: 8px rondom

---

## Navigatie

De app gebruikt **Material 3 NavigationBar** (bottom) met twee tabs:

| Tab        | Icon (default/selected)                    |
|------------|--------------------------------------------|
| Training   | `directions_run_outlined` / `directions_run` |
| Blessures  | `healing_outlined` / `healing`             |

Geselecteerde staat: brand orange indicator + label.

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
- Status bar: transparant, lichte iconen
- Navigatiebar: transparant of matcht `AppColors.bg`

### Web
- Maximale breedte formulieren: 480px (gecentreerd)
- Hover states op interactieve elementen

### iOS
- Zelfde kleurpalet, iOS-specifieke fonts automatisch via Flutter
