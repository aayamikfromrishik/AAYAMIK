Please add a "Client quiz" feature to the Karukrit Work Desk, so the admin (Saptarshi) and every project in-charge can create a personal questionnaire link for a client.

WHAT IT IS FOR
Karukrit Designs sends each client a link to a questionnaire (built in Manus). The link opens on our website at karukritdesigns.com/quiz/. The website only opens the questionnaire for a valid, unexpired link that was made by the Work Desk. The project code inside the link is passed on to the questionnaire, so each result saved in Google Drive is filed under the right project.

WHO CAN USE IT
- Saptarshi (admin): can create links for any project, including projects on Hold, and sees every link anyone has created, with who created it.
- Project in-charges / team members: can create links for the projects they can see, and see the links they created.

THE SCREEN
Add "Client quiz" to the navigation for both roles. On it:
1. Project: a dropdown of the projects (grouped by category, same codes as the worklists, e.g. RES-03), plus an option "A new client, not a project yet".
2. Client's name: optional for a project, required for a new client. Only used in the message.
3. Link works for: 7 days, 14 days or 30 days (default 14).
4. A "Create link" button.
After creating, show:
- the link, in a monospace box that is easy to select
- an editable message, prefilled: "Hello {name}, here is your personal Karukrit Designs questionnaire for {project name}. It helps us understand how you want to live in your home. The link works until {day month}.\n\n{link}" (leave out " {name}" and " for {project name}" when empty)
- buttons: Copy link, Copy message, Send on WhatsApp (opens https://wa.me/?text= followed by the URL-encoded message)
Below or beside it, a list of links created: client or project name, project code, created by, date made, valid until (shown as expired when past), and a Copy button. Store this list in the Work Desk's own data so it survives reloads.
Admin only: a small "Website setting" box that can reveal and copy the signing key (see below), with the note that it goes into GitHub as the secret QUIZ_SECRET and should only be shared with the web developer.

THE LINK FORMAT (must match exactly, the website checks it)
https://karukritdesigns.com/quiz/?c={PROJECT}_{YYMMDD}_{RAND}_{SIG}
- PROJECT: the project code in capitals, e.g. RES-03. For a new client: "NEW-" followed by the client's name in capitals with everything except A-Z and 0-9 removed, at most 12 characters (e.g. Mr Sharma -> NEW-MRSHARMA). Allowed characters: A-Z, 0-9 and "-", 2 to 24 characters.
- YYMMDD: the last day the link works, in India time (Asia/Kolkata), e.g. 261202 for 2 Dec 2026. The link works until 23:59:59 that day.
- RAND: 4 random characters from ABCDEFGHJKLMNPQRSTUVWXYZ23456789, from a secure random source (crypto.getRandomValues).
- SIG: HMAC-SHA256 of the text "{PROJECT}_{YYMMDD}_{RAND}" using the signing key, written as hexadecimal, first 10 characters, in capitals.
In a browser this is crypto.subtle.importKey("raw", key bytes, {name:"HMAC", hash:"SHA-256"}, false, ["sign"]) then crypto.subtle.sign("HMAC", key, text bytes), with both the key and the text encoded as UTF-8.

TEST EXAMPLES (with the test key "test-key-123", not the real key)
- RES-03_261202_ENGD  ->  RES-03_261202_ENGD_3D4D07C683
- NEW-SHARMA_261116_K7Q2  ->  NEW-SHARMA_261116_K7Q2_D58D323BEF
Please check the implementation produces exactly these before switching to the real key.

THE SIGNING KEY
Saptarshi will give you the real key separately. Keep it in the Work Desk's configuration, not in anything a client can see. Anyone who has the key can make valid links, so the Work Desk must only be open to the studio team.

NOT NEEDED
No change to the website is needed; it already checks these links. Don't call the website from the Work Desk.
