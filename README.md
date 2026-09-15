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
