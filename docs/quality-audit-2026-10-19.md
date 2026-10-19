# WellSpent quality audit — 2026-10-19

What this repo does: WellSpent is a small macOS to-do window. It keeps one person's tasks in a local JSON file and saves each change immediately. Expected load: one person, one app process, and a modest task list; the local Lavender edition shares the same behavior and data.

## Must fix

1. **One undo loses earlier deletions** (`WellSpent/src/TodoStore.swift:133`)
   - **What this is:** The app gives five seconds to undo a deletion.
   - **Problem:** Delete task A, then task B within five seconds: the second delete replaces A's undo record. The banner remains, but undo brings back only B.
   - **Fix:** Keep each deletion as a batch until the timer expires, then restore batches in reverse order. Show the total number of deleted tasks.
   - **If we skip it:** A user can think both tasks are recoverable while A has already become permanent.
   - **Status:** Fixed; a regression test covers two deletions with an addition between them.

## Should fix

2. **Undo changes an unrelated section** (`WellSpent/src/ContentView.swift:253`)
   - **What this is:** The completed-task list can be collapsed.
   - **Problem:** Undoing deletion of an unfinished task always expands completed tasks, even if the user left them collapsed.
   - **Fix:** Make undo report whether it restored a completed task. Expand that section only when it contains restored tasks.
   - **If we skip it:** A routine undo unexpectedly changes the user's layout.
   - **Status:** Fixed; tests cover both kinds of undo.

3. **Download requirements omit the CPU type** (`WellSpent/scripts/build.sh:44`, `README.md:13`)
   - **What this is:** The build script makes an `arm64` app for Apple Silicon.
   - **Problem:** The download instructions say only “macOS 13 or later.” On an Intel Mac, that requirement appears satisfied, but this app cannot run.
   - **Fix:** State the Apple Silicon requirement next to the download and source-build instructions. Do the same in the local Lavender README.
   - **If we skip it:** Intel Mac users may download or build an app they cannot run.
   - **Status:** Fixed in documentation. Intel support is not part of this update.

Verdict: The local data path and recovery behavior are sound for the expected load. Fixing the undo contract was the first priority.

Not checked: Manual GUI and accessibility testing on a desktop, Intel hardware, and notarized distribution. Automated regression tests and release builds were checked for both editions.
