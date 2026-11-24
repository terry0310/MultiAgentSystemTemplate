# Interaction patterns

Reusable rules learned from real UI defects. Each rule is framework-neutral. Add a rule only when it applies beyond one screen. Framework mechanics and project-specific regression mappings stay in the project (`RUNBOOK.md`, `MEMORY.md`, the task's defect ledger).

Use these rules as A1 or A2 evidence only when the project has adopted them or the cited kind of source supports the case; otherwise research the case.

## IP-001 A pointer changes the current item only when it actually moves

- **Rule.** In lists and menus, moving the pointer onto a row makes it the current (highlighted) item, and moving out of the component restores the default. Content that scrolls or re-lays out under a stationary pointer does not change the current item. Leaving the window directly from the component counts as moving out.
- **Why.** An item chosen with the keyboard must not be replaced because the page scrolled; otherwise Enter selects something else.
- **Sources.** Component libraries that react to pointer movement rather than to pointer-over events; listboxes in which hover never changes the selection.
- **Test.** Hover a row, keep the pointer still, and scroll the page or the list so that another row passes under it: the current item does not change. Then move the pointer out across the window edge: the default returns.

## IP-002 Tab dismisses a suggestion list without selecting

- **Rule.** With a suggestion list open under a text input, Tab or Shift+Tab closes the list, keeps the input text, commits nothing, and moves focus in the normal order. List rows never take focus.
- **Why.** Mature comboboxes let Tab leave and close the list. Whether Tab commits varies between them; not committing matches the other dismissals (Esc, an outside click).
- **Sources.** WAI-ARIA Authoring Practices combobox examples; the Windows auto-suggest box; framework autocomplete widgets.
- **Test.** Open the list and press Tab: the list is closed, the text is unchanged, nothing is queried, and the next control has focus. Press Shift+Tab to return, then an arrow key: the list comes back.

## IP-003 Popups attached to an input belong to the input's focus group

- **Rule.** On desktop platforms, pressing outside a focused text input usually blurs it at pointer-down, before the click completes. A suggestion list, its scrollbar and any other popup attached to the input must belong to the input's focus or tap group; otherwise pressing them blurs the input first. Check every "close on blur" rule against this.
- **Test.** With a mouse on a desktop target, press a list row and hold for at least one frame before releasing: the list stays and the row is selected on release. Drag the scrollbar: the input keeps focus and the keyboard still works.

## IP-004 Discard late asynchronous results after focus leaves

- **Rule.** If a popup is not shown yet and its asynchronous results are still pending when the input loses focus (Tab, a click elsewhere, navigation, a window switch, or a programmatic change), discard the pending results. Never open a popup that the keyboard cannot reach. When focus returns, an explicit action (for example an arrow key) brings the list back.
- **Sources.** Autocomplete widgets that show options only while the field has focus; the Windows auto-suggest box; WAI-ARIA Authoring Practices.
- **Test.** Use a controlled delay. Move focus while the result is pending, then release the result: the popup stays hidden. A real-device test usually cannot hit this window; say so in the evidence.

## IP-005 Every dismissal leaves the input in the same state

- **Rule.** Esc, an outside click and every other dismissal leave the focus, the caret position and the selection exactly as they were, so the user can keep typing.
- **Why.** On some desktop platforms an input that loses focus and gets it back selects all its text, so the next keystroke replaces the whole input. Asserting only "the input has focus" misses this.
- **Test.** Dismiss in each way, then type one more character. Compare the caret, the selection and the text across all dismissal methods and on each target platform.

## IP-006 Stacked popups close from the top down

- **Rule.** When a text-editing menu (cut, copy, paste, select all) is open above a suggestion list:
  - Esc, or a press anywhere outside the menu with any mouse button (including inside the list), closes only the menu. The next Esc or press closes the list.
  - Committing a selection (choosing a candidate, Enter, the submit button) performs the selection and closes the menu as well.
- **Related.** While the list is shown, right- and middle-clicks outside the list and the input dismiss it just like a left click.
- **Why.** Framework layering, native menus and browsers all close the topmost popup first. A menu opened for text that has since been replaced must not stay open.
- **Sources.** Browser popup handling (Firefox, Chromium); "light dismiss" in Microsoft Learn.
- **Known gap.** Scrolling the list with the wheel may leave the menu open; decide per project and record the ruling.
- **Test.** Open the list, open the text menu, then try each dismissal and each commit in turn, with each mouse button.
