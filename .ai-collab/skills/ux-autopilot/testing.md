# Choosing UI evidence

| Claim | Check |
| --- | --- |
| Geometry, text or a visible state | Compare the specified viewport, design revision and rendered result. Record a measurement or screenshot. |
| Focus, keyboard, pointer, scrolling or stacked overlays | Reproduce the event sequence using the declared platform and input kind. Record the starting state, action and what the user can do next. |
| Race or delayed result | Use a controlled clock or delayed fixture, demonstrate the failure on the original behavior and the passing regression. State which timing the physical test could reach. |
| IME composition, assistive technology or physical gestures | Use a capable device and operator, or record the outstanding coverage and its effect on acceptance. |

Distinguish static inspection, screenshot, simulated framework input, OS/app input and human device evidence. Record the build commit, platform, input and artifact for each observation. A simulator using a platform override provides simulated evidence for that environment.

Select the platform and the input kind explicitly in automated tests. A test harness's default (for example a mobile platform with touch input) can hide desktop pointer behavior, such as an input losing focus at pointer-down. Assert the selection, not only "has focus": losing focus and regaining it is not the same as keeping it.

Simulated framework input and real OS-level input find different defects. Plan both: automated tests for every matrix cell they can reach, and a real-input sweep of the interaction matrix at T2 (`UI-POLICY.md` "UI repair loop").

Test prerequisites too: assert that the scrollbar exists before dragging, the overlay is open before dismissal, and a delayed response is still pending before moving focus. After dismissing a popup, type one more character and inspect the caret, selection and resulting text. Split pointer down, render and release when timing matters. For each confirmed defect, connect the stable defect ID to its red/green regression or a documented equivalent reproduction.
