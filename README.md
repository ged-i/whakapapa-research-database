# Whakapapa Research Database — Iwi, Hapū, Marae & Representative Organisations

Relational database structure for iwi, hapū, rohe, marae and representative-organisation
information from **Te Kāhui Māngai** (TKM), the Te Puni Kōkiri directory at
https://www.tkm.govt.nz/ — built so marae can be mapped as points with clickable
pop-ups showing hapū, iwi, rohe and representative contacts.

## Files

| File | What it is |
|---|---|
| `TKM_Iwi_Hapu_Marae_Database.xlsx` | The database as a workbook (10 sheets). Region and Iwi are fully populated (13 regions, 117 iwi/groups). Other tables are seeded with Ngātiwai as a worked example. `Map_Export` is a formula-driven flat view with a ready-made `popup_html` column. |
| `tkm_schema.sql` | Same model as PostGIS / SQLite DDL, with a `v_marae_map` view and a GeoJSON export query. |
| `tkm_scraper.py` | Walks every iwi page on TKM and writes CSVs matching the sheets. `pip install requests beautifulsoup4 openpyxl` then `python tkm_scraper.py TKM_Iwi_Hapu_Marae_Database.xlsx`. |

## Data model

```
Region ──< Iwi_Region >── Iwi ──< Hapu ──< Marae_Hapu >── Marae (lat/long)
                           │
                           ├──< Iwi_LocalAuthority
                           └──< Representative_Org ──< Contact
```

## Next steps

1. Run the scraper to populate Hapu / Marae / Representative_Org / Contact.
2. Fill `Marae.latitude` / `longitude` from the Te Puni Kōkiri marae layer on ArcGIS Online
   (GIS Marae Viewer, linked from https://www.tkm.govt.nz/links/) or by geocoding the addresses.
3. Export `Map_Export` (or `v_marae_map`) to your mapping platform.

## Source & use

Data sourced from Te Kāhui Māngai, owned and maintained by Te Puni Kōkiri. Read the TKM
Disclaimer and Copyright pages before republishing. Rohe map images/PDFs on TKM may not be
reproduced without permission of the relevant iwi organisation, and contact details are
published at each organisation's discretion — keep them current and treat them with care.

## Web map

`docs/index.html` is a live map of every marae in Te Puni Kōkiri's *Marae of Aotearoa* layer
(loaded straight from their ArcGIS service, so it is always current), with search, region and
iwi filters, hapū and iwi for each marae, a toggle showing the iwi's area of interest, and the
representative organisations and contacts held in this database. It is served by GitHub Pages
from the `docs/` folder.

`docs/data/*.json` is generated from the spreadsheet by `gen_data.py` — re-run it and commit
after updating the workbook (for example after running the scraper) and the map updates itself.

## Whakapapa layer (tupuna)

The map's **Tupuna** tab holds a profile card per ancestor, each linked to any number of
locations of interest — a marae, a hapū, an iwi, or a place picked on the map (kāinga, urupā,
land block). Selecting a tupuna highlights their marae, drops pins for their places and shades
their iwi rohe; a marae's card lists the tupuna connected to it, with a one-click link.

Entries are saved in the browser. **Export JSON** gives a file you can commit as
`docs/data/tupuna.json` (the shared baseline), and **Export CSV** produces `Tupuna.csv` and
`Tupuna_Location.csv` in exactly the columns of the two matching sheets in the workbook, so the
spreadsheet remains the master record. Pātaka Whenua block boundaries and owner lists are the
planned next layer (see `tkm_schema.sql`).

## Sources and claims (provenance)

Nothing from outside the live TPK layer is merged into it. Information from Māori Maps, Te Ara,
whānau records or any other source is stored as **claims** — one row per statement, attributed
to a **source** with its own colour (`Source` and `Claim` sheets; `docs/data/sources.json`,
`docs/data/claims.json`). On the map each source can be switched on or off; marae that other
sources describe get a coloured ring; a marae card shows what each source says side by side and
flags where they differ; the Sources tab lists every conflict. Claims can be added from a marae
card and exported as JSON/CSV in the sheet's columns. Māori Maps is all-rights-reserved: enter
citations by hand, never bulk-copy.

### Whakapapa links and the whakapapa collection

A tupuna link can also point at a **Waka** or at another **Tupuna** (`location_type` = Tupuna,
`location_ref` = the other tupuna_id, relationship = Mother / Father / Child / Spouse / Sibling /
Grandparent / …). Kin links show from both sides. On the Tupuna tab, *Collect* adds a tupuna to
the whakapapa collection and *Collect connected* pulls in everyone linked to them (repeat to go a
generation further); the map then shows the union of all collected tupuna's marae, hapū, iwi,
waka and places, labelled with who connects there and how.

## Whenua — Māori land blocks

`docs/data/blocks/` holds the Māori Land Court **Māori Land Spatial Dataset (May 2017)** — all
27,212 Māori freehold and customary land blocks — converted from the MLC shapefile to WGS84
GeoJSON, lightly simplified (4 m), and split by Māori Land Court district so the map loads only
what's in view. `index.json` is a name/ID lookup; `districts.json` holds each district's bounds.
The `Block` sheet in the workbook carries every block's attributes. Licence: CC BY 4.0, Ministry
of Justice / Māori Land Court. The data is a static 2017 release — partitions, amalgamations and
ownership changes since then are not reflected; Pātaka Whenua is the current record.

On the map, the **Whenua** button (top right) shows block boundaries once zoomed in; the search box
finds a block by name or ID; a block card shows title order, area, minute book, owner and share
counts and management structures. Blocks can be collected, and a tupuna can be linked to a block
(`location_type` = Block, `location_ref` = block_id) as owner, land interest, lived, born, died or
buried — owner lists are not public, so these come from your own Pātaka Whenua lookups.
