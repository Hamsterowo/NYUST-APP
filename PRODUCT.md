# Product

## Register

product

## Platform

android

## Users

YunTech (國立雲林科技大學 / 雲科大) students, using their own phone to check the things the official student portal holds — grades, class schedule, graduation progress, attendance, academic calendar. They reach for the app in short, purposeful bursts between classes or when a grade is due, often one-handed and sometimes on a flaky campus connection. The job to be done is always the same shape: get to one specific piece of school information as fast as possible and get out.

## Product Purpose

An unofficial third-party client for YunTech's student portal (SSO / WebNewCAS / eStudent), built because the official web portal is slow, cluttered, and painful on a phone. The app scrapes the same portal pages the student would otherwise navigate by hand and presents them as a fast, cache-first mobile experience, with a few features going through the reverse-engineered captcha-free app endpoint. Success is a student choosing this over logging into the official portal — because it is quicker, clearer, and works even when the network is momentarily gone.

## Brand Personality

**Efficient and no-nonsense.** The app is a tool, and the tool should disappear into the task: fast, direct, done. Its voice is plain and helpful, not chatty or promotional. Any personality it shows is in the polish of getting out of the student's way — never in decoration that slows the answer down.

## Anti-references

Explicitly should NOT look or feel like:
- **The official school portal** it replaces — cramped, cluttered, dated form-heavy pages.
- **A generic template app** — the off-the-shelf, no-identity look that could belong to anything.
- **An over-designed / flashy showpiece** — elaborate animation, layered gradients, decorative color that gets between the student and the data.
- **An ad / marketing app** — pop-ups, promos, engagement bait, anything that pushes rather than serves.

## Design Principles

- **The tool disappears into the task.** Students come to check a grade or a schedule, not to admire the interface. Speed and directness beat decoration every time.
- **Better than the source.** Every screen should be measurably faster and clearer than the official portal page it stands in for; if it isn't, it hasn't earned its place.
- **Earned familiarity.** Lean on standard Material patterns students already understand. Don't reinvent affordances for standard tasks; save any surprise for genuine moments, not whole screens.
- **Honest about state.** The app is cache-first and offline-aware. It must always distinguish "can't reach the server" from "you're logged out", and never mislead the student about whether what they're seeing is live or cached.
- **Restraint over flash.** Density and clarity serve the student. No marketing gloss, no engagement bait, no motion that doesn't convey state.

## Accessibility & Inclusion

No specific accessibility target has been set. Follow sensible defaults regardless: legible text contrast, comfortable touch targets, and never conveying meaning (grades, status) by color alone.
