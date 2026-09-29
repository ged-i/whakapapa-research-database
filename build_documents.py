"""
build_documents.py — build / refresh docs/data/documents.json from drive_manifest.json.

The manifest lists every Pātaka Whenua export sitting in the Google Drive folder
"Ownership Schedules" (one sub-folder per block group). File names follow the Pātaka
Whenua pattern  {batch}_{docId}_{firstPage}_{lastPage}_{TYPE}_Document-{docId}.pdf
with TYPE = ORD (court order), LHO (list of owners / holders), MIN (minute book),
HMS (historical memorial schedule). The odd export lacks the "_Document-{docId}" suffix;
the document number is then taken from the second field.

Existing entries in documents.json are kept: anything already transcribed (title,
dates, blocks, names on record, status, notes) is never overwritten by this script;
only the Drive metadata (id, url, file name, size, pages) is refreshed.

    python build_documents.py
"""
import json, re, pathlib

ROOT = pathlib.Path(__file__).parent
MAN = json.loads((ROOT / "drive_manifest.json").read_text(encoding="utf-8"))
OUT = ROOT / "docs" / "data" / "documents.json"
TYPE_LABEL = {"ORD": "Court order", "LHO": "List of owners", "MIN": "Minute book", "HMS": "Historical memorial schedule"}

existing = {}
if OUT.exists():
    for d in json.loads(OUT.read_text(encoding="utf-8")):
        existing[d["document_id"]] = d

pat = re.compile(r"^(\d+)_(\d+)_(\d+)_(\d+)_([A-Z]{3})(?:_Document-(\d+))?(?: \(\d+\))?\.pdf$")
docs = []
for folder, drive_id, fname, size in MAN["files"]:
    m = pat.match(fname)
    if not m:
        raise SystemExit(f"unexpected file name: {fname}")
    batch, doc_no, p1, p2, typ, doc_no2 = m.groups()
    assert doc_no2 is None or int(doc_no) == int(doc_no2), fname
    doc_no = str(int(doc_no))
    pages = int(p2) - int(p1) + 1
    did = f"PW-{doc_no}"
    base = {
        "document_id": did,
        "doc_no": doc_no,                       # Pātaka Whenua document number
        "type": typ,
        "type_label": TYPE_LABEL.get(typ, typ),
        "folder": folder,                       # Drive sub-folder = block group the record was filed under
        "title": f"{TYPE_LABEL.get(typ, typ)} — {folder} (Pātaka Whenua doc {doc_no})",
        "blocks_recorded": [],                  # block name(s) exactly as written on the document
        "block_ids": [],                        # MLC 2017 block ids this record has been matched to
        "record_date": "",                      # date on the document (order / list compiled)
        "effective_date": "",                   # e.g. date an interest vests from
        "court": "", "judge": "", "minute_book": "",
        "pages": pages, "page_range": f"{int(p1)}–{int(p2)}" if typ == "MIN" else "",
        "file_name": fname, "drive_id": drive_id, "file_size": size,
        "url": f"https://drive.google.com/file/d/{drive_id}/view",
        "source_id": "S07",
        "status": "indexed",                    # indexed → partly transcribed → transcribed
        "summary": "",
        "names": [],                            # [{name, role, sex, age, shares, tupuna_id, confidence, note}]
        "notes": "",
    }
    if did in existing:
        keep = existing[did]
        for k in ("file_name", "drive_id", "file_size", "url", "pages", "page_range", "folder", "type", "type_label", "doc_no"):
            keep[k] = base[k]
        for k, v in base.items():
            keep.setdefault(k, v)
        docs.append(keep)
    else:
        docs.append(base)

order = list(MAN["folders"].keys())
docs.sort(key=lambda d: (order.index(d["folder"]) if d["folder"] in order else 99, d["type"], d["doc_no"]))
OUT.write_text(json.dumps(docs, ensure_ascii=False, indent=1), encoding="utf-8")
print(f"{len(docs)} documents → {OUT}")
