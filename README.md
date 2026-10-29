# Karukrit Designs website

A working prototype of the Karukrit Designs website, built from the "FINAL · Option 3, chapters · leather textures" design.

## What it does so far

**Opening.** The Karukrit Designs logo draws itself on the leather paper, then fades away to show the home page. Visitors can skip it.

**Chapter I · Home.** The 3D house tells the line "Every house begins as a line on paper." in three stages:
1. **Plan.** The site plan draws itself on a drawing sheet, with walls, door swings, dimension lines and trees. Then the walls rise as line drawings, floor by floor.
2. **Model.** As you scroll, the lines fill in to make a white study model with real sun and shadow.
3. **Home.** Scrolling further adds colour (plaster, wooden fins, glass, grass), and the camera comes down to eye level at the front of the house.

The camera circles the house slowly, and moving the mouse tilts the view. The frosted glass card also leans toward the cursor.

**Chapter II · About.** A 3D copy of *The 100 Decisions Before the First Brick* turns as you scroll and opens when clicked.

**Chapter II · Book pages.** When the book is open, it shows the sample pages from the book (Introduction, Chapter 1 and Chapter 13), with arrows that turn the page.

**Chapter III · Team.** Portrait cards tilt toward the cursor, with a soft light following it. Hovering lifts a card and brings it into colour.

**Chapter IV · Philosophy.** Three statements change as you scroll, one per screen. Behind them a faint plan drawing draws itself and moves more slowly than the words, which gives the section depth.

**Chapter V · Work.** Projects sit on a curved gallery wall that drifts slowly. Hovering pauses it and brings a project forward in colour, and the wall can be dragged.

**Chapter VI · Completed project.** Scrolling walks you through the front door: the elevation grows until you pass through the door into the interior.

**Chapter VII · Ongoing project.** The stage bar fills up to the current stage, and an elevation drawing builds itself to match. Stages still to come show as dashed lines.

**Chapter VIII · Contact.** Studio address, phone, email and a button to book a first meeting.

**Phones and accessibility.** The page is laid out for phones. If a visitor's device asks for less motion, the animations are switched off.

## Viewing it on your computer

Browsers block the 3D files when `index.html` is opened directly from disk, so run a small local server from this folder:

```bash
python3 -m http.server 8000
```

Then open <http://localhost:8000>.

## Putting it online

On GitHub, go to **Settings → Pages**, choose **Deploy from a branch**, then pick this branch and the root folder. You can also drag the folder into Vercel or Netlify. The site has no build step.

## Using one of your own houses

1. Export the house from SketchUp, Revit or Rhino as a **.glb** file. Use metres, with the front of the house facing +Z.
2. Put the file in `assets/models/`, for example `assets/models/house.glb`.
3. In `assets/js/hero3d.js`, set `const MODEL_URL = 'assets/models/house.glb';`.

The plan outline, the rising line drawing, and the colour and shadow stages work the same way on your model.

## Files

- `index.html`: the page
- `assets/css/style.css`: colours, leather texture, glass card and the 3D book
- `assets/js/hero3d.js`: the 3D house in Chapter I (three.js)
- `assets/js/main.js`: the logo opening, the glass card, the book and the effects in Chapters III to VII
- `assets/img/`: the logo, the leather texture and the sample book pages from the design canvas
- `assets/vendor/three/`: three.js r160 (MIT licence), kept in the repository so the site has no outside dependencies

Text in square brackets, like `[Your story in two short paragraphs.]`, is a placeholder waiting for real content.
