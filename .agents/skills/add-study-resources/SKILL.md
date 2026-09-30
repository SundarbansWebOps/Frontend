---
name: add-study-resources
description: Add notes or past question papers (PYQs) to a course on the Sundarbans House Study Corner. Use when a team member asks to add, fix or remove study resources, notes, PYQs or question papers for a course.
---

# Add study resources

You are helping a Sundarbans House team member add notes or past question papers (PYQs) to the
website. Your whole job is editing course data files. Every file you change is inside
`src/data/study/courses/`: one JSON file per course, named by course code (`BSMA1001.json` is
Maths 1).

The person is probably not a developer. Explain each command before you run it, and show them the
output.

**Hard limits.** Change only files inside `src/data/study/courses/`. Use only titles and links the
person gave you. If the task needs any other file, or a link you would have to guess, stop and tell
the person to ask Raja. CI rejects pull requests that change any other file.

## 1. Set up (first time only)

Run `npm install`. Done when it finishes without `ERR!` lines.

## 2. Collect the resources

For each resource, get these from the person:

- **course**: a code (`BSCS1002`) or a name ("Python"). Match a name against the `"subject"`
  line of each file, e.g. `grep '"subject"' src/data/study/courses/*.json`.
- **kind**: `notes` or `pyqs`.
- **title**: see the formats below.
- **link**: a full `https://` link, usually a Google Drive link that is shared as "Anyone with the
  link can view". PDFs belong on Google Drive, not in this repository.

Done when every resource has all four. Ask the person for anything missing.

### Title formats

- **PYQ**: exam, then term month and year, then set. The site reads the exam and the term from the
  title, and `npm run check:study` rejects a PYQ title with no month and year.
  - `Quiz 1 (Jan 2025) QP1`
  - `End Term (Sep 2024) Set 2`
  - `OPPE 1 (May 2025) Paper 1`
- **Notes**: course, week if there is one, then the author in brackets as `(by Name)`.
  - `Python Week 3 notes (by Priya Sharma)`

## 3. Edit the course file

Add each resource as a new object at the **end** of the `"notes"` or `"pyqs"` list in that course's
file:

```json
{
  "title": "Quiz 1 (Jan 2025) QP1",
  "link": "https://drive.google.com/file/d/FILE_ID/view"
}
```

Put a comma after the `}` of the entry before it. Every entry has exactly the keys `title` then
`link`. Keep everything else in the file as it is.

To fix or remove an entry, change only that entry.

## 4. Check

Run these two commands:

```bash
npx prettier --write src/data/study/courses
npm run check:study
```

Done when `check:study` prints `✔ Study data OK`. If it prints problems, each line names the file,
the entry (for example `pyqs[85]`) and the fix. Fix them and run it again.

Then run `git status`. Done when every changed file is in `src/data/study/courses/`. Undo any other
change with `git restore <file>`.

## 5. Let the person see it

Run `npm run dev` and give the person the local URL. They open **Resources**, pick the course and
confirm the new entries appear and their links open. Stop the server with Ctrl+C when they are done.

## 6. Commit and open a pull request

Work on a branch named for the change, never on `main`:

```bash
git switch -c feat/study-<course-code>-<what>      # e.g. feat/study-bscs1002-jan-2025-pyqs
git add src/data/study/courses/
git commit -m "feat(study): add <course> <what>"   # e.g. feat(study): add Python Jan 2025 PYQs
git push -u origin HEAD
```

Then open a pull request to `main` on GitHub. In the description, list what was added and where the
files came from. Done when the pull request exists. CI runs the same checks, and Raja reviews and
merges it.
