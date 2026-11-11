# Tree ID

Photograph a leaf or bark to identify the tree, or photograph a cut stump to estimate its age. Field-guide look: paper background, serif type, forest green. Finds you save are kept in a local journal on the phone. No account, no analytics.

## What it does
- **Identify a tree** — leaf or bark photo, top match plus alternates, genus notes, save to journal.
- **Age a stump** — drag a line from the stump's center to the bark. The app reads brightness along the line, marks the dark ring bands it finds, and shows a year estimate you can nudge with +/−.

## Species matching engine
iOS has no built-in species classifier, so the app uses one of two engines:
1. **Offline (preferred):** put a Core ML model named `TreeSpecies.mlmodel` (an image classifier) in `Resources/Models/` and rebuild. It is picked up automatically and no photo leaves the phone.
2. **Pl@ntNet (default):** get a free key at https://my.plantnet.org, then tap the key button in *Identify a tree* and paste it. The photo is sent to Pl@ntNet for matching. The key is stored on the phone only. The free tier has a daily limit.

Stump aging is fully on-device.

## Build

### Option A: you have a Mac
```
brew install xcodegen
xcodegen generate
open TreeID.xcodeproj
```

### Option B: no Mac (cloud build + sideload)
1. Push this folder to a private GitHub repo. The *iOS Build (unsigned IPA)* workflow runs on `macos-15`.
2. Download the `TreeID-unsigned-ipa` artifact from the Actions run.
3. Sideload with AltServer for Windows (altstore.io), signing in with your Apple ID.

## Notes and limits
- Ring counting is an estimate. Cracks, a rough cut, or a stump cut well above the ground will throw it off. Shoot straight down in even light.
- Not compiled yet when first written; if the CI build fails, paste the failing step.
