# Takka v1.0.1 Release Notes

## What's New in v1.0.1

### 🎵 Customizable Sound Effects
- Added interactive sound effects for core user actions (completing tasks, saving events, mascot interactions, clicking buttons, and deletions).
- 5 customizable sound effect themes:
  - **Melodic Chimes**: Elegant musical bells and chimes.
  - **Digital Synth**: Crisp futuristic electronic tones.
  - **Soft Bubble Pops**: Organic, playful pop sounds.
  - **Tactile Clicks**: Subtle mechanical feedback.
  - **Muted**: Fully silent operation when preferred.
- Toggle sound effects on or off with a single tap in Settings.

### 🔔 Customizable Ringtones with Live Audition
- 6 rich preset ringtones for event reminders and alarms:
  - **Gentle Chime**: Serene rising chime melody.
  - **Digital Pulse**: Fast-paced, high-visibility electronic pulse.
  - **Zen Bell**: Deep, calming resonant bell.
  - **Radar Alert**: Clear directional sonar alert.
  - **Crystal Harp**: Sparkling multi-tone arpeggio.
  - **Classic Alarm**: Insistent high-attention alert.
- Interactive Preview / Stop button in Settings allows listening to each ringtone before selecting.

### ⏰ Alarm Mode
- New dedicated Alarm Mode setting for reminders and critical appointments.
- Persistent audio ringing until explicitly dismissed or snoozed.
- Full-width, high-visibility active alarm banner displaying event title, time, and quick actions.
- Customizable snooze duration (5, 10, or 15 minutes).
- Test Alarm Mode button in Settings and Event Details for immediate trial.
- Per-event alarm designation via Critical / Alarm importance.

### 🎨 Icon Improvements & RTL Fixes
- Replaced generic category icons with semantic category icons (`menu_book` for Study, `work` for Work, `fitness_center` for Exercise, `groups` for Meeting, `school` for University, `star` for Important, `person` for Personal).
- Fixed RTL arrow directions in the timeline and event cards for Arabic layout.
- Upgraded navigation and action icons to rounded Material 3 variants.

### 📱 Live Next Up Widget Auto-Updates
- Fixed home-screen widget getting stuck until the app is opened:
  - Event schedule JSON is persisted to shared widget storage.
  - Kotlin `NextUpWidgetProvider` dynamically recalculates current "NOW" vs "NEXT" status autonomously.
  - Schedules exact Android `AlarmManager` wakeup alarms right when an event begins or ends, updating the widget on the home screen immediately without opening the app.
  - Triggering widget refresh whenever tasks or events are modified in the app.
