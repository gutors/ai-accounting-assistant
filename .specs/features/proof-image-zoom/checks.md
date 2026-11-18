# Proof image zoom checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/proof-image-zoom/plan.md`

22 checks in 3 slices · 0 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Raster proof zooms on insert

**C1** - Coordinator attaches JPEG `spec/fixtures/files/ocr/amount_only.jpg`: the lote proof pane shows buttons whose accessible names are `Ampliar` and `Reduzir`, `[data-controller=image-zoom]` has `data-image-zoom-scale-value` `1`, and `Reduzir` is disabled (AC 1)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG starts at scale 1 with Ampliar and Reduzir disabled"`

**C2** - On that JPEG at scale `1`, `Ampliar` sets `data-image-zoom-scale-value` `1.25` and enables `Reduzir` (AC 2)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG Ampliar from 1 sets scale 1.25"`

**C3** - On that JPEG at scale `4`, `Ampliar` leaves `data-image-zoom-scale-value` `4` and `Ampliar` is disabled (AC 3)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG Ampliar at 4 stays 4 and disables Ampliar"`

**C4** - On that JPEG at scale `1.25`, `Reduzir` sets `data-image-zoom-scale-value` `1` and disables `Reduzir` (AC 4)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG Reduzir from 1.25 sets scale 1"`

**C5** - On that JPEG at scale `1`, a `wheel` with `deltaY` `-120` sets scale `1.25`; a `wheel` with `ctrlKey` true and `deltaY` `-120` at scale `1` sets `1.25`; a `wheel` with `deltaY` `120` at scale `1` stays `1`; a `wheel` with `deltaY` `-120` at scale `4` stays `4` (AC 5)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG wheel and pinch zoom clamp between 1 and 4"`

**C6** - On that JPEG at scale `2`, a pointer-drag of `40` px on the image changes the proof pane `scrollLeft` or `scrollTop` from `0` (AC 6)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG drag at scale 2 pans the proof pane"`

**C7** - Coordinator attaches PNG `spec/fixtures/files/ocr/amount_only.png`: `Ampliar` at scale `1` sets `data-image-zoom-scale-value` `1.25` (AC 7)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote PNG Ampliar from 1 sets scale 1.25"`

**C8** - Coordinator attaches WebP `spec/fixtures/files/ocr/amount_only.webp`: `Ampliar` at scale `1` sets `data-image-zoom-scale-value` `1.25` (AC 8)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote WebP Ampliar from 1 sets scale 1.25"`

**C9** - Coordinator attaches a PDF: `Ampliar` and `Reduzir` are absent, and the proof `embed` `src` includes `#toolbar=1` (AC 9)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote PDF has no Ampliar and embed toolbar=1"`

**C10** - Coordinator attaches authorized XML `proc-nfe-padaria.xml`: `Ampliar` and `Reduzir` are absent (AC 10)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote XML-only has no Ampliar"`

**C11** - Coordinator attaches two JPEGs `amount_only.jpg` then `danfe_fields.jpg`, uses `Ampliar` on the first (scale `1.25`), then selects the second row: that image's `data-image-zoom-scale-value` is `1` (AC 11)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote second JPEG row resets scale to 1"`

**C12** - Submitter attaches JPEG `amount_only.jpg` on Incluir documento: `Ampliar` at scale `1` sets `data-image-zoom-scale-value` `1.25` (AC 12)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "submitter JPEG Ampliar from 1 sets scale 1.25"`

**C13** - Coordinator attach JPEG shown at viewport width `390`: `Ampliar` and `Reduzir` are visible and `document.documentElement.scrollWidth` is `<= 390` (AC 13)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "lote JPEG Ampliar visible at 390 without horizontal scroll"`

### S2 - Raster proof zooms on Editar

**C14** - Coordinator `GET /supporting_documents/:id/edit` of a document whose photo is JPEG `amount_only.jpg` responds `200`, the proof pane shows `Ampliar` and `Reduzir` at `data-image-zoom-scale-value` `1`, and `Ampliar` sets scale `1.25` (AC 14)
Proof: `bin/rspec spec/system/image_zoom_spec.rb -e "edit JPEG starts at scale 1 and Ampliar sets 1.25"`

**C15** - Coordinator `GET /supporting_documents/:id/edit` of a document whose photo is a PDF: the proof pane has no `Ampliar` or `Reduzir`, and the `embed` `src` includes `#toolbar=1` (AC 15)
Proof: `bin/rspec spec/requests/supporting_documents_proof_zoom_spec.rb -e "GET edit PDF has no Ampliar and embed toolbar=1"`

**C16** - Coordinator `GET /supporting_documents/:id/edit` of a document with XML and no photo: the proof pane has no `Ampliar` or `Reduzir` (AC 16)
Proof: `bin/rspec spec/requests/supporting_documents_proof_zoom_spec.rb -e "GET edit XML-only has no Ampliar"`

### S3 - Sem mês does not show the chave

**C17** - Authenticated `GET /supporting_documents` of a document whose chave is `35240612345678000190550010000012341000012340` responds `200`; `#sem-mes` has no `[data-chave]` and does not contain `3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340` (AC 17)
Proof: `bin/rspec spec/requests/supporting_documents_proof_zoom_spec.rb -e "GET supporting_documents omits grouped chave from Sem mes"`

**C18** - `GET /supporting_documents/:id/edit` of that document: `input#chave` has value `35240612345678000190550010000012341000012340` (AC 18)
Proof: `bin/rspec spec/requests/supporting_documents_proof_zoom_spec.rb -e "GET edit keeps raw chave digits"`

**C19** - That document listed in `#sem-mes` still includes payee `Padaria Central`, `R$ 155,00`, kind `Nota fiscal`, and original filename `recibo.jpg` (AC 19)
Proof: `bin/rspec spec/requests/supporting_documents_proof_zoom_spec.rb -e "GET supporting_documents Sem mes still shows payee amount kind filename"`

**C20** - Submitter `POST /supporting_documents/identify` with authorized XML whose chave is `35240612345678000190550010000012341000012340`: `#identify-preview` contains `3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340` (AC 20)
Proof: `bin/rspec spec/requests/supporting_documents_proof_zoom_spec.rb -e "POST identify preview still shows grouped chave"`

**C21** - Unauthenticated `GET /supporting_documents` responds `302` to `/login` (Surface)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

**C22** - Unauthenticated `GET /supporting_documents/:id/edit` responds `302` to `/login` (Surface)
Proof: `bin/rspec spec/requests/supporting_documents_edit_spec.rb -e "unauthenticated GET edit responds 302 to /login"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| raster formats (3) | JPEG C1 · PNG C7 · WebP C8 | - |
| scale bounds (4) | start `1` C1 · Ampliar `1.25` C2 · cap `4` C3 · Reduzir `1` C4 | - |
| gestures (3) | buttons C2 · wheel/pinch C5 · drag pan C6 | - |
| wheel/pinch inputs (2) | `deltaY` `-120` C5 · `ctrlKey` wheel C5 | - |
| insert proof kinds (3) | JPEG C1 · PDF C9 · XML-only C10 | - |
| surfaces (3) | coordinator lote C1 · submitter identify C12 · Editar C14 | - |
| edit proof kinds (3) | JPEG C14 · PDF C15 · XML-only C16 | - |
| lote row reset (1) | C11 | - |
| 390 viewport (1) | C13 | - |
| Sem mês omit chave (2) | no `[data-chave]` C17 · no grouped text C17 | - |
| list identity fields (4) | payee C19 · `R$` amount C19 · kind C19 · filename C19 | - |
| edit raw chave (1) | C18 | - |
| identify preview grouped chave (1) | C20 | - |
| `GET /supporting_documents` statuses (2) | 200 C17 · 302 C21 | - |
| `GET /supporting_documents/:id/edit` statuses (2) | 200 C14 · 302 C22 | - |

- Gesture proofs that attach the picker or click `Ampliar`: C1–C14
- C15–C22 cross the HTTP boundary
- No other check claims more than the single case its proof exercises

## Swept

- validation: C3, C5 - scale stays in `1`..`4` step `0.25`; no new server input
- failure modes: n/a - zoom is client-only and does not persist
- idempotency: n/a - no write
- authorization: C21, C22 - existing session 302 on list and edit; no new route
- concurrency: n/a - per-pane client scale; no shared write
- data lifecycle: C18 - stored chave returns raw on Editar; C17 does not delete it
- dependency failure: n/a - no external call
- state transitions: C1, C2, C3, C4, C11 - scale `1` / `1.25` / `4` and reset on lote row change
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** none
- **Dispatched:** none
- **Boundary:** none
- **Abandoned:** none
- **Walked:** Coordinator `/login` Ambiente local `gutors@gmail.com` then `/supporting_documents`. Sem mês rows show payee, date, kind, `R$` amount and filename, not a grouped chave. Editar of `nota-gasolina-ranger-2205.jpeg` shows `Ampliar` / `Reduzir` (`Reduzir` disabled at fit); `Ampliar` enables `Reduzir` and the proof pane grows scrollbars; `input#chave` keeps raw digits. Insert JPEG attach is C1–C13 (IDE tab cannot set `<input type=file>`). No capture.
