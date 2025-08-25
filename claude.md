## ProteinPilot – iOS Brainstorming (Startpunkt)

### Zielbild
* **Versprechen**: Protein-Ziel ohne lästiges Tracken erreichen. App passt sich dem echten Alltag an, schlägt passende Mahlzeiten vor und reduziert Reibung beim Erfassen auf ein Minimum.
* **Ergebnis**: Täglicher Protein-Ring wie bei Activity. Einfache Erfassung, smarte Vorschläge, stetige Anpassung.

### Kernnutzer
* Berufstätige/Studierende mit wenig Zeit, die Muskeln aufbauen oder Gewicht halten wollen.
* Frustriert von komplexem Kalorientracking, möchten nur Protein sicherstellen.

### Value Proposition
* **Minimaler Aufwand**: 3–5 Taps pro Tag statt Mikrologging
* **Personalisierte Planung**: Vorschläge basierend auf Gewohnheiten, Supermarkt, Budget, Kochzeit
* **Automatische Anpassung**: Verpasste Mahlzeiten werden am selben Tag elegant kompensiert

### Differenzierung
* Fokus ausschließlich auf Protein-Outcome statt Vollzählung aller Makros
* Proaktive Tagesplanung statt reaktives Logging
* Kamera/Barcode/Voice als Primär-Input, Text als Fallback

## MVP-Scope (v1.0)
* **Onboarding**: Ziel, Körperdaten, Essensfenster, Koch-Skills, No-Gos
* **Protein-Ring**: Tagesziel, Fortschritt, Restmenge, Schnell-Add
* **Schnell-Erfassung**: Barcode-Scan, Label/OCR für Proteingehalt, Voice („200g Skyr“)
* **Vorschläge heute**: 3–5 Optionen mit Rest-Protein-Ausgleich
* **Verlauf**: Letzte 20 Items, 1‑Tap Re-Add
* **Benachrichtigungen**: Smarte Reminder auf Basis Essensfenster/Restziel

Nice-to-have nach MVP: Wochenplan, Einkaufslisten, Freunde/Streaks, HealthKit-Export, iPad/Watch.

## Screen-Map
1. **Onboarding**: Zieldefinition, Protein-Tagesziel, Präferenzen
2. **Home**: Protein-Ring, Restziel, Quick Add, „Heute vorgeschlagen“
3. **Add**: Kamera/Barcode/Voice/Text, Portionsregler, Sofort-Feedback
4. **Historie**: Liste, Suche, Duplicate, Edit
5. **Einstellungen**: Ziele, Erinnerungen, Datenschutz

## UX-Prinzipien
* Ein Screen, ein primärer Call-To-Action
* Progressive Enthüllung: Details nur bei Bedarf
* Offline‑first Erfassung, Sync später

## Datenmodell (MVP)
* `User`: id, proteinDailyTarget, eatingWindowStart/End
* `FoodItem`: id, name, proteinPer100g, source (scan, template, custom)
* `ProteinEntry`: id, date, quantity, proteinGrams, foodItemId
* `PlanSuggestion`: id, date, options[] (FoodItemRef, protein, prepTime)

Persistenz: SwiftData (iOS 17+) oder Core Data fallback. Tagesaggregation per Derived Model.

## KI/Logik (AI‑first)
* **LLM‑basiert**: OpenAI (GPT‑4o/mini) für Normalisierung, Tagesplanung/Vorschläge und Catch‑up‑Empfehlungen mit strukturierter JSON‑Ausgabe.
* **Voice**: OpenAI Whisper für Transkription (Streaming, mehrsprachig).
* **Vision**: OpenAI Vision‑Modell zum Auslesen von Nährwert‑Labels/Verpackungen und Portionsschätzung; Barcode als schneller Pfad via DB.
* **Guardrails**: Schema‑Parsing, Einheiten‑Normalisierung, Allergene/No‑Gos‑Filter.
* **Reminder**: Zeitfenster‑basierte, kontextuelle Hinweise aus LLM‑State.

## Rolling Catch-up (Proteinkonto)
* **Prinzip**: Unter‑/Übererfüllung wird auf ein 7‑Tage‑Konto gebucht und sanft ausgeglichen.
* **Modell**: Tagesziel \(T\). Gestern‑Delta \(d = \text{consumed} - T\). Konto heute \(k' = \text{clip}(k + d, -1.0\times T, +1.0\times T)\). Neues Ziel heute \(T' = T - \alpha\cdot k'\) mit \(\alpha=0.3\).
* **Caps**: Max. Catch‑up pro Tag 30% von \(T\); Wochen-Cap ±1× \(T\) um Extreme zu vermeiden.
* **Vorschlagslogik**: Bei Defizit Priorisierung von schnell verfügbaren, protein‑dichten Optionen; Verteilung über 2–3 Mahlzeiten, keine „Riesenmahlzeit“.
* **UX**: Sekundärer Ring/Arc zeigt Konto‑Ausgleich; Tooltip „−18g von gestern, heute empfohlen +9g“.
* **Preferences**: Toggle „Flexibel“ vs. „Strikt“ (Catch‑up aus); Slider für Catch‑up‑Intensität \(\alpha\).
* **Sicherheit**: Pro‑Mahlzeit‑Obergrenze, Tagesobergrenze, Ruhemodus bei Krankheit/fasten.

Datenschutz: PII-minimiert, Bilder lokal verarbeitet, opt-in Cloud für Verlauf/Modelle.

## Architektur (iOS)
* **UI**: SwiftUI, iOS 17+, Dark/Light, Dynamic Type
* **State**: MVVM mit Observable/State, Nebenläufigkeit via `async/await`
* **Persistenz**: SwiftData Repositories (Unit‑Test‑bar)
* **Services**: Camera/BarcodeService, VisionExtractionService (OpenAI), WhisperTranscriptionService, OpenAILLMService (Vorschläge/Normalisierung), FoodDBService, NotificationService, SyncService, APIProxyService
* **Hintergrund**: BackgroundTasks für Sync/Model-Refresh
* **Modularität**: Feature-Module `Home`, `Add`, `History`

## Backend/Proxy (leichtgewichtig)
* API‑Proxy versteckt OpenAI‑Keys, setzt Rate Limits, loggt Kosten/Latenz, signiert Requests (App Attest) und bietet Feature Flags/Prompt‑Versionierung.
* Kein User‑Image‑Upload ohne Opt‑in; temporäre URL‑Uploads mit sofortiger Löschung nach Extraktion.

## System-Integrationen
* HealthKit (optional) für Protein als Ernährungseintrag
* App Intents/Shortcuts: „Protein hinzufügen 20g“
* Push/Local Notifications: Restziel, Meal Window

## Risiken & Gegenmaßnahmen
* Barcode-Abdeckung: Hybrid DB (OpenFoodFacts + Caching), Fallback auf OCR/Text
* Erkennungsfehler: Confidence-Score, schnelle manuelle Korrektur, Favoriten
* KI-Kosten: On-Device so viel wie möglich, Server batching/caching

## Erfolgsmessung
* D1/D7 Retention, tägliche Erfassungen/Tag, Zeit bis Zielerreichung
* Anteil Erfassungen via Kamera/Voice vs. manuelles Eingeben

## Privacy & Compliance
* Einwilligung für Trial/Abo, Privacy Policy im Onboarding, klare Kostenkommunikation.
* DSGVO: Datenminimierung, Export/Löschung in‑app, Auftragsverarbeitung mit OpenAI im Proxy gekapselt.
* Kein Gesundheitsversprechen; Disclaimer, kein Ersatz für medizinische Beratung.
* Key‑Sicherheit: Keine API‑Keys im Client, Keychain nur für Tokens, App Attest/DeviceCheck.

## Reliability & Fallbacks
* Offline: Manuelle Eingabe bleibt verfügbar, Queuing für Sync wenn LLM/Netz nicht erreichbar.
* Retries mit Exponential Backoff; Circuit Breaker; Nutzerfreundliche Fehlertexte.
* Caching: Normalisierte `FoodItem`/Barcode‑Ergebnisse lokal, Vision‑Extrakte persistent.

## Kosten & Observability
* Budgets: p50 Latenz < 1.2s Add‑Flow, p95 < 2.5s; Kosten/Tag pro aktiven Nutzer ≤ 0.05€ im Schnitt.
* Telemetrie: Prompt‑Version, Token usage, Latenz, Fehlercodes, Conversion Events (Trial→Paid, Paywall Views).
* Prompt‑Versionierung + automatische A/B Tests über Feature Flags.

## Accessibility & Localization
* VoiceOver, Dynamic Type, hohe Kontraste; alle Kernflows per Tastatur/Voice bedienbar.
* Sprachen: DE/EN zum Start; Einheitenumschaltung (g/oz).

## Science Rationale (kurz)
* **Gesamtdosis > Timing**: Wöchentlicher Proteindurchschnitt ist entscheidend; kleine Tagesdefizite können 24–72h später ausgeglichen werden.
* **Mahlzeiten‑Sättigung**: Pro Mahlzeit ca. 0.3–0.4 g/kg Körpergewicht effektiv; daher Catch‑up über 2–3 Mahlzeiten statt Einzelbolus.
* **Sichere Obergrenzen**: Tagesziel typ. 1.6–2.2 g/kg; App limitiert Catch‑up auf ≤30% pro Tag und ±1×T pro Woche.
* **Praxis**: Leicht verdauliche, protein‑dichte Optionen; Hydration; Option „Strikt“ ohne Catch‑up für Nutzerpräferenz.

## Monetarisierung
* Abo: Voller Funktionsumfang inkl. Smarte Vorschläge 2.0, HealthKit, erweiterte Erinnerungen, Offline‑Barcode, Watch
* Preise (A/B Test): 5,99/8,99/11,99 € mtl.; Jahresabo −40% mit 5‑Tage Test
* AI‑Credits (Add‑on): Zusätzliche Chat/OCR‑Kontingente als Top‑Up; nur für Abonnenten
* Bundles: Family‑Plan (bis 5), Studenten‑/Edu‑Plan
* B2B (später): Teams/Family‑Seats, Wochenreports
* Paywall‑Momente: Harte Sperre nach Tag 5 der Trial; Pre‑Trial Upsell (Tag 2–3), HealthKit‑Export zeigt Paywall mit Test‑Restzeit
* KPI‑Ziele: Trial→Paid ≥ 20%, Annual Mix ≥ 60%, Churn < 3,5%/Monat

### Trial & Paywall
* **5‑Tage Vollzugriff**: Alle Features frei nutzbar, aktives Schreiben von Daten ausdrücklich erwünscht.
* **Nach Trial kein Free‑Fallback**: App wechselt in gesperrten Modus (Lesen der eigenen Daten erlaubt), neue Einträge nur mit aktivem Abo.
* **Auto‑Renew**: Abo startet automatisch nach 5 Tagen, klar kommuniziert inkl. Preis, Zeitraum, Cancel‑Option; Push 24h vor Trial‑Ende.
* **Experimente**: Preisanker, Tag‑2/3 Starter‑Rabatt, Countdown‑Banner, Paywall‑Copy‑Varianten.

## Roadmap (kompakt)
1) v0.1 Prototype: Home, Quick Add, Local DB, Offline Persistenz
2) v0.2 Scan/Barcode/OCR, Favoriten, Vorschlags-Stub
3) v0.3 LLM‑gestützte Normalisierung, smarte Reminder
4) v1.0 App Store, Pro-Abo, HealthKit

## Nächste Schritte (konkret)
* Domain-Model + SwiftData Schemata
* Home-UI mit Protein-Ring, Quick Add
* OpenAI‑Anbindung: Whisper (Transkription), Vision (Label‑Parsing), LLM (Vorschläge/Catch‑up) mit strikt definiertem JSON‑Schema
* Benachrichtigungen: Time‑boxed Reminder nach Essensfenster
* Evaluations‑Harness: Prompt‑Versionierung, Kosten/Response‑Latenz‑Logging, Fallbacks bei API‑Errors


