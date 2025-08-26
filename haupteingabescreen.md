Build-Spezifikation: Haupteingabescreen (was die KI bauen soll)
Ziel: In ≤5 s sehen, was heute dran ist; 1‑Tap erfassen/fortsetzen.
Reihenfolge (Top→Bottom):
Header
Protein‑Ring (heute)
Erfassungsleiste: Kamera · Barcode · Mikro · Manuell
Quick‑Adds (6 Chips)
Week‑Strip‑Kalender (Mo–So, swipe)
“Weiter machen”-Card
Empfehlungen (Gerichte) – Carousel mit Inline “Zu Plan hinzufügen”
Heute‑Plan (Liste der Einträge mit Swipe‑Aktionen)
Einkaufslisten‑Hinweis/Preview
Komponenten (UI/UX, Interaktionen, States)
Header

UI: Begrüßung, Datum, Avatar.
Tap Avatar → Profil/Settings.
Protein‑Ring

UI: Fortschrittsring + “x g von y g (−Rest)”.
Tap → “Makros heute” (Detail + Ziel anpassen).
States: Loading‑Skeleton, Ziel erreicht (grün), Fehlerbanner bei Sync‑Fehler.
Erfassungsleiste (4 Buttons)

Kamera: Foto → KI‑Vorschläge → Bestätigen.
Barcode: Scan → Produktdetail → Portion → Hinzufügen.
Mikro: Diktat (“200 g Skyr”) → Parsing‑Preview → Hinzufügen.
Manuell: Suche → Detail → Portion → Hinzufügen.
Alle: Nach Hinzufügen Snackbar 8 s: “Hinzugefügt …” mit “Rückgängig”/“Bearbeiten”.
Quick‑Adds (Chips)

6 personalisierte Chips; 1‑Tap fügt Standardportion hinzu.
Long‑press → Chip bearbeiten/pinnen/löschen.
Doppelte innerhalb 3 s werden zusammengeführt (Hinweis “Zusammengeführt”).
Week‑Strip‑Kalender

UI: 7 Tage sichtbar, heute markiert, horizontales Scroll ±3 Wochen.
Tap → Tag auswählen; Inhalte (Ring, Heute‑Plan, Empfehlungen) filtern auf den Tag.
Long‑press auf Tag → “Eintrag planen” Bottom‑Sheet (Typ, Zeit, Wiederholung).
“Weiter machen”-Card

Zeigt das zuletzt begonnene Item; CTA “Fortsetzen”.
Tap → öffnet Rezept/Workout an letzter Stelle.
Empfehlungen (Gerichte)

UI: Horizontal‑Carousel (2,5 Karten/Viewport), Chips‑Filter (z. B. Schnell, <20 Min, Proteinreich).
Karte: Bild, Titel, Dauer, kcal, Tags; Primary “Zu Plan hinzufügen”.
Tap Karte → Rezept‑Detail; Inline‑Add → Bottom‑Sheet (Tag/Zeit/Portion).
Heute‑Plan (Liste)

Zeilen: Zeit, Titel, Menge/Portion, Status (geplant/erledigt), CTA “Kochen/Starten”.
Swipe links → “Bearbeiten” / “Löschen” (ohne Bestätigungs‑Popup; mit Undo‑Snackbar).
Drag & Drop (optional) → Zeit/Tag verschieben (Undo verfügbar).
Einkaufslisten‑Hinweis

Text: “Heute fehlen 3 Zutaten” → Tap → Einkaufsliste.
Kern‑Flows (End‑to‑End)
Hinzufügen (alle Wege)

Nutzer wählt Erfassungsweg/Quick‑Add → Vorschau/Detail → Hinzufügen
Sofort: Optimistic Update der Liste + Ring, Undo‑Snackbar (8 s), Telemetry.
Undo stellt vorherigen Zustand wieder her (auch offline, solange unsynced).
Bearbeiten/Löschen

Swipe oder Tap → Bottom‑Sheet “Eintrag bearbeiten” (Menge, Einheit, Uhrzeit, Tag).
Speichern: Update Liste + Ring. Löschen: Entfernen + Undo‑Snackbar.
Kalender & Empfehlungen

Tag wählen → Ring/Plan/Empfehlungen für diesen Tag aktualisieren.
Empfehlung per Inline‑Add dem gewählten Tag hinzufügen.
Fortsetzen

“Weiter machen”-Card → öffnet Detail (Rezept/Workout) an letzter Position; nach Abschluss: Completion‑Toast/Modal.
Zustände/Fehler/Offline
Loading: Skeletons für Ring, Empfehlungen (3 Platzhalter), Heute‑Plan (3 Zeilen).
Offline: Badge “Ausstehend” an neuen/editierten Einträgen, Sync‑Banner bei Fehlern (“Erneut versuchen”).
Doppelteingabe‑Merge: Gleiches Item + Portion <3 s → Mengen addieren, Hinweis + Undo.
Accessibility: Targets ≥44 dp; ARIA‑Labels/Accessible Names; Fokusreihenfolge: Ring → Erfassung → Quick‑Adds → Kalender → Cards → Liste; Live‑Region bei Add/Undo; Kontrast AA.
Datenmodelle (minimal)
// Eintrag (Nahrungsaufnahme)
{
  "id": "int_1",
  "type": "intake",
  "title": "Skyr",
  "proteinGrams": 20,
  "amount": 200,
  "unit": "g",
  "day": "2025-08-25",
  "time": "08:15",
  "status": "planned" // or "done"
}

// Geplanter Eintrag (Gericht/Workout)
{
  "id": "itm_1",
  "type": "meal",
  "recipeId": "r_123",
  "title": "Kichererbsen-Curry",
  "time": "12:30",
  "day": "2025-08-25",
  "servings": 2,
  "status": "planned"
}

// Tagesplan
{
  "day": "2025-08-25",
  "scheduledItems": [ ... ],
  "intakes": [ ... ],
  "macroTotals": { "proteinGrams": 62, "goalProteinGrams": 120 }
}

// Empfehlungskarte
{
  "recipeId": "r_123",
  "title": "Kichererbsen-Curry",
  "image": "https://...",
  "durationMin": 20,
  "kcal": 520,
  "tags": ["Vegan", "<20 Min", "Proteinreich"]
}
API‑Contracts (für die Verknüpfung)
GET /api/plan/day?userId=U&day=YYYY‑MM‑DD → DayPlan
POST /api/intake { userId, title|foodId|recipeId?, proteinGrams, amount, unit, day, time } → { status, id }
PATCH /api/intake/:id { proteinGrams?, amount?, unit?, time?, day?, status? } → { status }
DELETE /api/intake/:id → { status }
GET /api/recommendations?userId=U&day=YYYY‑MM‑DD&filters=... → { recipes: [...] }
POST /api/plan { userId, type, recipeId, day, time, servings } → { status, entryId }
PATCH /api/plan/:id { time?, day?, servings?, status? } → { status }
POST /api/vision/food { image } → { candidates:[{title, proteinGrams, amount, unit}] }
POST /api/barcode/lookup { ean } → { title, macros, defaultPortion }
POST /api/nlp/parse-intake { text } → { title, amount, unit, proteinGrams }
Telemetry (Events)
intake_added, intake_edited, intake_deleted, intake_undo_used
quick_add_used, quick_add_edited
calendar_day_selected, calendar_entry_added, calendar_item_moved, calendar_item_move_undone
rec_impression, rec_card_opened, rec_added_to_plan, rec_filter_used
recipe_started, recipe_completed
sync_failed, sync_retry_clicked
Performance‑Budgets
First interactive ≤1.5 s; Interaktionslatenz (Sheet/Undo) ≤200 ms.
Week‑Strip scrollen/flips butterweich (60 fps).
Optimistic Updates für Add/Edit/Delete; Undo ohne Netzwerkwartezeit.
Akzeptanzkriterien (Home)
Protein‑Ring zeigt aktuelle/Rest‑Protein; nach jeder Änderung korrekt.
4 Erfassungsbuttons funktionieren inkl. Preview/Bestätigung; Undo‑Snackbar 8 s.
Quick‑Adds: 6 Chips, 1‑Tap Add, Long‑press bearbeiten.
Week‑Strip: Tag‑Auswahl synchronisiert Ring/Plan/Empfehlungen.
Empfehlungen: Inline “Zu Plan hinzufügen” → Bottom‑Sheet (Tag/Zeit/Portion).
Heute‑Plan: Swipe Edit/Delete, Drag‑Drop (optional), Sticky CTA beim nächsten Item.
Offline‑Fälle: Markierung “Ausstehend”, Retry‑Option, keine Datenverluste.
Wie es zusammenhängt

Auswahl eines Tages im Week‑Strip setzt den Kontext; alle Module (Ring, Empfehlungen, Heute‑Plan) lesen/aktualisieren diesen Kontext.

Jeder Add/Edit/Delete triggert: Optimistic Update → Ring/Listen aktualisieren → Undo anbieten → Hintergrund‑Sync → Erfolg/Fehler‑Handling.

Empfehlungen lesen Präferenzen + Tageskontext und schreiben via “Zu Plan hinzufügen” in den Plan, der sofort im Heute‑Plan sichtbar wird.