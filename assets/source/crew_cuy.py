"""The cuy crew of Farpoint HORIZON (issue #44): four cuy astronauts (Andean guinea pigs), our own design, built by
this script in Blender so there is no AI image and no outside model. Stylized and deadpan, next to the game's
documentary-real craft (docs/design/criteria.md: characters may be stylized, real objects never).

  - a bean-shaped cuy with no neck, fur in three colours as patches over a white or cream coat, round ears;
  - a calm, deadpan face: small dark eyes with a lid, a pink nose, a tiny mouth, whiskers;
  - a short space suit in the game's palette (white fabric, horizon blue, sunrise amber), a backpack, boots,
    and a clear bubble helmet so the face reads.

Run: blender -b --factory-startup --python assets/source/crew_cuy.py -- <out_dir> [render]
Writes <out_dir>/crew_<name>.glb for each cuy, and with "render" a line-up picture crew_lineup.png.
"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector, noise

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.abspath("build/crew")
RENDER = "render" in ARGS
os.makedirs(OUT, exist_ok=True)

# The palette of the game (scripts/ui/kit.gd): horizon blue, sunrise amber, navy neutrals.
SUIT = (0.9, 0.91, 0.93)
BLUE = (0.18, 0.42, 0.9)
AMBER = (1.0, 0.55, 0.14)
NAVY = (0.03, 0.05, 0.1)
# Cuy coats: cream, white, ginger, chocolate, slate.
WHITE = (0.93, 0.9, 0.84)
CREAM = (0.95, 0.83, 0.62)
GINGER = (0.85, 0.42, 0.12)
CHOC = (0.28, 0.16, 0.09)
SLATE = (0.42, 0.42, 0.44)
PINK = (0.95, 0.6, 0.62)

## Each cuy: its coat, its patches [(centre (x, y, z) on the head, radius, colour)], its station colour, its prop.
CREW = {
    "rumi": {"coat": WHITE, "patches": [((0.15, -0.28, 0.62), 0.16, GINGER), ((-0.17, -0.25, 0.66), 0.12, CHOC), ((0.0, 0.3, 0.6), 0.3, GINGER)],
             "ears": (CHOC, GINGER), "stripe": AMBER, "prop": "wrench"},
    "killa": {"coat": CHOC, "patches": [((0.0, -0.33, 0.5), 0.13, WHITE), ((0.0, -0.25, 0.74), 0.07, WHITE)],
              "ears": (CHOC, CHOC), "stripe": BLUE, "prop": "flask"},
    "inti": {"coat": GINGER, "patches": [((0.0, -0.34, 0.47), 0.12, CREAM), ((0.16, -0.24, 0.66), 0.1, CHOC)],
             "ears": (GINGER, CHOC), "stripe": AMBER, "prop": "goggles"},
    "wayra": {"coat": WHITE, "patches": [((-0.15, -0.27, 0.64), 0.14, SLATE), ((0.12, 0.25, 0.7), 0.22, SLATE), ((0.22, -0.15, 0.72), 0.08, CHOC)],
              "ears": (SLATE, WHITE), "stripe": BLUE, "prop": "headset"},
}


# ----------------------------------------------------------------------------------------------------------- basics
def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, rough=0.6, metal=0.0, alpha=1.0, emit=0.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        b.inputs["Transmission Weight"].default_value = 0.9
        m.surface_render_method = "BLENDED"
    if emit > 0.0:
        b.inputs["Emission Color"].default_value = (*color, 1.0)
        b.inputs["Emission Strength"].default_value = emit
    return m


def add(obj, parent, material):
    obj.data.materials.append(material)
    obj.parent = parent
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def sphere(name, loc, scale, parent, material, seg=48, ring=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=1.0, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    return add(o, parent, material)


def cyl(name, loc, r, depth, parent, material, rot=(0, 0, 0), verts=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    return add(o, parent, material)


def torus(name, loc, major, minor, parent, material, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=loc, rotation=rot,
                                     major_segments=48, minor_segments=12)
    o = bpy.context.object
    o.name = name
    return add(o, parent, material)


def apply_all(o):
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for md in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=md.name)
    o.select_set(False)


# ----------------------------------------------------------------------------------------------------------- the cuy
def coat_mat(name):
    """The fur: the body's own vertex colours (the coat and its patches), exported with the model."""
    m = bpy.data.materials.new("coat_" + name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = 0.85
    b.inputs["Sheen Weight"].default_value = 0.6   # the soft glow of fur at the edges
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], b.inputs["Base Color"])
    return m


def paint(o, coat, patches):
    """Colours each vertex: the coat, or the patch it falls in (a ragged, slightly soft edge)."""
    me = o.data
    ca = me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="POINT")
    for v in me.vertices:
        p = o.matrix_basis @ v.co
        col = Vector(coat)
        for (c, r, pc) in patches:
            d = (p - Vector(c)).length / r + 0.22 * noise.noise(p * 7.0 + Vector(c) * 5.0)
            k = max(0.0, min(1.0, (1.0 - d) / 0.12))   # 1 inside, 0 outside, a thin soft band
            col = col.lerp(Vector(pc), k)
        ca.data[v.index].color = (col.x, col.y, col.z, 1.0)


def bean(parent, coat):
    """The body: one bean with no neck, wider below, the head its upper front. Units: metres; a cuy is 0.9 m tall
    here, a game size chosen so the crew reads next to a lander (they are characters, not to scale)."""
    o = sphere("Body", (0, 0, 0.42), (0.36, 0.34, 0.44), parent, coat, 96, 48)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        z = v.co.z
        # wider and fuller below, a soft brow at the front
        k = 1.0 + 0.12 * (-z)
        v.co.x *= k
        v.co.y *= k
        if v.co.y < 0 and z > 0.2:
            v.co.y *= 1.06
        v.co += v.normal * 0.012 * noise.noise(v.co * 6.0)   # a little unevenness, as fur
    bm.to_mesh(o.data)
    bm.free()
    return o


def patch(parent, body, centre, radius, colour, i):
    """A fur patch: the part of the coat within `radius` of `centre` (with a ragged edge), lifted a hair above it."""
    o = body.copy()
    o.data = body.data.copy()
    o.name = "Patch%d" % i
    o.data.materials.clear()
    o.data.materials.append(colour)
    bpy.context.collection.objects.link(o)
    o.parent = parent
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.transform(o.matrix_basis)   # body space, to test against the centre
    c = Vector(centre)
    drop = []
    for f in bm.faces:
        p = f.calc_center_median()
        d = (p - c).length / radius + 0.25 * noise.noise(p * 9.0 + c * 3.0)
        if d > 1.0:
            drop.append(f)
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    for v in bm.verts:
        v.co += v.normal * 0.006
    bm.transform(o.matrix_basis.inverted())
    bm.to_mesh(o.data)
    bm.free()
    return o


def face(parent, eyes_mat, nose_mat, line_mat, lid_mat):
    """Deadpan: small dark eyes half under a flat lid, a pink nose, a tiny mouth, whiskers."""
    for sx in (-1, 1):
        e = sphere("Eye", (sx * 0.13, -0.3, 0.66), (0.038, 0.03, 0.042), parent, eyes_mat, 24, 12)
        sphere("Glint", (sx * 0.13 + 0.012, -0.328, 0.673), (0.009, 0.006, 0.009), parent, mat("glint", (1, 1, 1), 0.2, emit=2.0), 12, 6)
        lid = sphere("Lid", (sx * 0.13, -0.302, 0.693), (0.046, 0.034, 0.02), parent, lid_mat, 24, 12)   # the half-closed lid
        lid.rotation_euler = (0.0, sx * 0.08, 0.0)
        for k, ang in enumerate((-0.18, 0.0, 0.2)):
            w = cyl("Whisker", (sx * 0.2, -0.3, 0.54 + k * 0.02), 0.0025, 0.2, parent, line_mat, rot=(0.0, math.pi / 2 + sx * ang, 0.0), verts=6)
            w.rotation_euler = (0.0, math.pi / 2, sx * ang)
    sphere("Nose", (0, -0.35, 0.57), (0.035, 0.022, 0.024), parent, nose_mat, 24, 12)
    # the mouth: a small upside-down "y"
    cyl("Mouth", (0, -0.345, 0.535), 0.004, 0.035, parent, line_mat, verts=6)
    for sx in (-1, 1):
        cyl("MouthL", (sx * 0.012, -0.34, 0.513), 0.004, 0.03, parent, line_mat, rot=(0.0, sx * 0.9, 0.0), verts=6)


def ears(parent, outer, inner):
    for sx in (-1, 1):
        e = sphere("Ear", (sx * 0.24, -0.02, 0.8), (0.1, 0.035, 0.075), parent, outer, 24, 12)
        e.rotation_euler = (0.2, sx * 0.5, sx * 0.6)
        i = sphere("EarIn", (sx * 0.235, -0.04, 0.795), (0.07, 0.02, 0.05), parent, inner, 24, 12)
        i.rotation_euler = (0.2, sx * 0.5, sx * 0.6)


def suit(parent, stripe):
    """The space suit: the lower body in white fabric, a stripe in the station's colour, a chest panel with lights,
    a backpack, arms with gloves, boots, and the helmet ring with its bubble."""
    fab = mat("suit", SUIT, 0.75)
    st = mat("stripe_%d" % int(stripe[2] * 100), stripe, 0.5)
    o = sphere("Suit", (0, 0, 0.3), (0.395, 0.375, 0.34), parent, fab, 64, 32)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z > 0.48], context="FACES")   # the top is open
    bm.to_mesh(o.data)
    bm.free()
    torus("Stripe", (0, 0, 0.18), 0.378, 0.02, parent, st)
    torus("Collar", (0, 0, 0.46), 0.355, 0.035, parent, mat("ring", (0.75, 0.77, 0.8), 0.3, 0.8))
    # chest panel with three small lights
    p = cyl("Panel", (0, -0.36, 0.3), 0.09, 0.03, parent, mat("panel", NAVY, 0.4), rot=(math.pi / 2, 0, 0), verts=6)
    p.scale = (1.0, 0.65, 1.0)
    for k, c in enumerate((BLUE, AMBER, (0.6, 0.9, 1.0))):
        sphere("Light", (-0.035 + k * 0.035, -0.382, 0.3), (0.012, 0.008, 0.012), parent, mat("led%d" % k, c, 0.3, emit=3.0), 12, 6)
    # backpack
    b = cyl("Pack", (0, 0.35, 0.35), 0.17, 0.15, parent, fab, rot=(math.pi / 2, 0, 0), verts=24)
    b.scale = (1.0, 1.3, 1.0)
    cyl("PackStripe", (0, 0.43, 0.35), 0.12, 0.02, parent, st, rot=(math.pi / 2, 0, 0), verts=24)
    # arms: short stubs ending in gloves
    for sx in (-1, 1):
        a = sphere("Arm", (sx * 0.375, -0.05, 0.3), (0.065, 0.065, 0.12), parent, fab, 24, 12)   # a soft sleeve
        a.rotation_euler = (0.0, sx * 0.45, 0.0)
        sphere("Glove", (sx * 0.44, -0.07, 0.21), (0.062, 0.062, 0.062), parent, mat("glove", (0.95, 0.95, 0.96), 0.5), 24, 12)
        sphere("Boot", (sx * 0.16, -0.08, 0.035), (0.1, 0.13, 0.06), parent, mat("boot", (0.22, 0.23, 0.26), 0.6), 24, 12)
    # the bubble helmet around the head, and its ring
    sphere("Helmet", (0, -0.01, 0.66), (0.41, 0.41, 0.39), parent, mat("glass", (0.85, 0.93, 1.0), 0.02, alpha=0.18), 48, 24)


def props(parent, kind):
    m = mat("prop_metal", (0.75, 0.76, 0.78), 0.35, 0.9)
    if kind == "wrench":
        w = cyl("Wrench", (0.47, -0.09, 0.32), 0.016, 0.24, parent, m, rot=(0.0, 0.0, 0.0), verts=12)
        torus("WrenchHead", (0.47, -0.09, 0.45), 0.035, 0.014, parent, m, rot=(math.pi / 2, 0, 0))
    elif kind == "flask":
        sphere("Flask", (-0.47, -0.1, 0.27), (0.05, 0.05, 0.06), parent, mat("flaskglass", (0.6, 1.0, 0.85), 0.05, alpha=0.4), 24, 12)
        cyl("FlaskNeck", (-0.47, -0.1, 0.34), 0.016, 0.06, parent, mat("flaskglass", (0.6, 1.0, 0.85), 0.05, alpha=0.4), verts=12)
    elif kind == "goggles":
        for sx in (-1, 1):
            torus("Goggle", (sx * 0.09, -0.24, 0.79), 0.05, 0.013, parent, mat("gogframe", (0.15, 0.15, 0.16), 0.4), rot=(1.2, 0, 0))
            sphere("GoggleLens", (sx * 0.09, -0.245, 0.79), (0.045, 0.012, 0.045), parent, mat("goglens", AMBER, 0.1, emit=0.3), 16, 8)
    elif kind == "headset":
        band = mat("band", (0.15, 0.15, 0.16), 0.4)
        bpy.ops.mesh.primitive_torus_add(major_radius=0.355, minor_radius=0.014, location=(0, 0.02, 0.6), rotation=(math.pi / 2, 0, 0),
                                         major_segments=48, minor_segments=10)
        hb = bpy.context.object
        hb.name = "Headband"
        add(hb, parent, band)
        bm = bmesh.new()   # only its upper half, over the crown from ear to ear
        bm.from_mesh(hb.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y < -0.02], context="VERTS")   # local y is up once turned
        bm.to_mesh(hb.data)
        bm.free()
        for sx in (-1, 1):
            cyl("EarCup", (sx * 0.35, 0.02, 0.6), 0.06, 0.04, parent, mat("cup", BLUE, 0.4), rot=(0, math.pi / 2, 0), verts=24)
        cyl("Mic", (-0.27, -0.2, 0.55), 0.008, 0.2, parent, band, rot=(0.0, 0.0, -0.95), verts=8)
        sphere("MicTip", (-0.19, -0.27, 0.55), (0.022, 0.022, 0.022), parent, mat("cup", BLUE, 0.4), 12, 6)


def build(name, spec, x):
    root = bpy.data.objects.new("crew_" + name, None)
    bpy.context.collection.objects.link(root)
    coat = mat("lid_" + name, spec["coat"], 0.85)   # the eyelids take the coat's colour
    body = bean(root, coat_mat(name))
    paint(body, spec["coat"], spec["patches"])
    face(root, mat("eye", (0.02, 0.02, 0.03), 0.15), mat("nose", PINK, 0.5), mat("line", (0.08, 0.05, 0.05), 0.6), coat)
    ears(root, mat("ear_" + name, spec["ears"][0], 0.8), mat("earin", PINK, 0.7))
    suit(root, spec["stripe"])
    props(root, spec["prop"])
    for o in root.children:
        apply_all(o)
    root.location = (x, 0, 0)
    return root


def export(root, path):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in root.children:
        o.select_set(True)
    loc = root.location.copy()
    root.location = (0, 0, 0)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True)
    root.location = loc


def render(path):
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.samples = 48
    scn.cycles.use_denoising = True
    scn.render.resolution_x = 1600
    scn.render.resolution_y = 800
    scn.render.film_transparent = False
    world = bpy.data.worlds.new("w")
    scn.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.025, 0.05, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    bpy.context.object.data.materials.append(mat("ground", (0.32, 0.31, 0.33), 0.95))
    scn.view_settings.view_transform = "Standard"
    for loc, energy, col in (((-3, -4, 5), 420, (1.0, 0.94, 0.86)), ((4, -2, 2), 110, (0.6, 0.75, 1.0)), ((0, 4, 3), 260, (1.0, 0.8, 0.6))):
        bpy.ops.object.light_add(type="AREA", location=loc)
        lt = bpy.context.object
        lt.data.energy = energy
        lt.data.size = 3
        lt.data.color = col
        lt.rotation_euler = (Vector((0, 0, 0.5)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(0.0, -6.2, 1.25))
    cam = bpy.context.object
    cam.data.lens = 50
    cam.rotation_euler = (Vector((0, 0, 0.45)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    scn.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    clear()
    names = list(CREW)
    roots = []
    for i, n in enumerate(names):
        r = build(n, CREW[n], (i - 1.5) * 1.1)
        roots.append(r)
        export(r, os.path.join(OUT, "crew_%s.glb" % n))
        print("wrote", "crew_%s.glb" % n)
    if RENDER:
        for r in roots:
            r.rotation_euler = (0, 0, 0.25 if r.location.x < 0 else -0.25)
        render(os.path.join(OUT, "crew_lineup.png"))
        print("rendered crew_lineup.png")


main()
