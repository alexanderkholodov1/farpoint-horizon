# The teammate's laptop runs the game (resolved 2026-11-14)

Asus VivoBook Go, integrated AMD Radeon, Windows, Godot 4.7.2 Steam (in `Program Files (x86)`, now found by
`tools/godot.sh`). Version 1 (Forward+ with Vulkan) closed on start; with `gl_compatibility` and no 3D MSAA it works.
Checked on 2026-11-14 on branch `v0.2.0`: Godot reports `OpenGL API 3.3.0 Core Profile ... AMD Radeon(TM) Graphics`,
every `[SKH]` startup step through `menu listo` and the first frames print, 600 frames in a window end with exit 0;
`tools/shots.sh` produced all 16 screenshots (menu and launch looked at); `tools/check.sh` passed. The only messages are
the same texture-leak warnings at exit as on the lead's laptop. The safe mode is no longer needed for this laptop.
