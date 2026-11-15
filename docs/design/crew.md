# The cuy crew (issue #44, for v0.3.0)

Four cuy astronauts (Andean guinea pigs), the protagonists of the v0.3.0 story (`docs/design/story-v0.3.0.md`).
Our own design, modelled by script in Blender (`assets/source/crew_cuy.py`): no AI image, no outside model.

![The crew](crew_lineup.png)

| Name (proposed) | Station | Build and face | Coat | Stripe | Prop |
|---|---|---|---|---|---|
| Rumi (stone) | Engineer | short and stocky; unimpressed, one brow up, a flat mouth | white, ginger and chocolate | amber | a wrench |
| Killa (moon) | Scientist | tall and slim; wide open eyes, brows up, a small "o" | chocolate, white blaze | blue | a flask |
| Inti (sun) | Pilot | middle; eyes narrowed, brows slanted in, a half smile | ginger, cream muzzle | amber | goggles |
| Wayra (wind) | Ground control | middle, softest corners; nearly asleep, the cuy's "y" mouth | white, slate | blue | a headset |

The look: an upright, slightly boxy body with no neck (as the reference sticker's cuy), a deadpan face (small dark eyes half under a flat lid, a pink nose, a tiny
mouth, whiskers), fur in three colours as vertex colours, a short white suit in the game's palette, and a clear bubble
helmet so the face reads. Stylized next to documentary-real craft, as `docs/design/criteria.md` allows for characters.

Names and look to be confirmed by both team members before they go into the game.

## Second look: full figures in T-pose (the team's reference)

![T-pose](crew_tpose.png)

Rumi with a work suit, tool belt, pouches, knee pads and a roll of tape; Wayra with a blue vest, a badge on a lanyard,
a headset and an antenna; Killa with a long lab coat and a blue stripe. Built by `assets/source/crew_cuy_tpose.py`
(Blender, from primitives) to match a reference sheet the team made with **Meshy (an AI 3D tool)**: if these are used,
the README's "Use of AI" says so. The pilot (Inti) waits for its reference. Models:
`assets/models/crew/crew_{rumi,wayra,killa}_tpose.glb`.
