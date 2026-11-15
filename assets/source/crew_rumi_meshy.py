"""Rumi, the engineer, matched to the team's Meshy reference (issue #44).

The body (suit, tool belt, wrench, screwdriver, knee pads, boots, tape, backpack) is `rumi_trellis_body.glb`: a mesh
made with TRELLIS (an AI image-to-3D model, the Hugging Face Space trellis-community/TRELLIS) from a screenshot of the
Meshy (AI) model. Its head came out wrong (the glass helmet confused it), so this script cuts it off above the collar
and builds the head here, in Blender, from primitives, to the reference: a soft boxy cream head, a ginger patch around
its right eye and ear, a brown patch around its left eye and ear, glossy black eyes under small brows, a pink nose, a
small mouth, whiskers, and a clear bubble helmet with a silver rim.
Both tools are AI: the README's "Use of AI" must say so if this model is used.

Run: blender -b --factory-startup --python assets/source/crew_rumi_meshy.py -- <out.glb>
"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else os.path.join(HERE, "crew_rumi.glb")
BODY = os.path.join(HERE, "rumi_trellis_body.glb")

NECK_Z = 0.118      # above this the generated head is cut off (the collar ring stays)
HEAD_C = Vector((0.0, -0.01, 0.282))
HEAD_R = Vector((0.186, 0.158, 0.162))

CREAM = (0.98, 0.9, 0.82)
GINGER = (0.96, 0.52, 0.12)
BROWN = (0.42, 0.18, 0.07)
PINK = (0.97, 0.6, 0.66)
DARK = (0.06, 0.04, 0.04)


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


def finish(o, material):
    o.data.materials.clear()
    o.data.materials.append(material)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def sphere(name, loc, scale, material, seg=32, ring=16, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=1.0, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    return finish(o, material)


def cyl(name, loc, r, depth, material, rot=(0, 0, 0), verts=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    return finish(o, material)


def body():
    bpy.ops.import_scene.gltf(filepath=BODY)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    b = bpy.context.object
    b.name = "Body"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bm = bmesh.new()
    bm.from_mesh(b.data)
    # only the head goes: the backpack, behind it (y > 0.15), rises above the collar too and stays whole
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z > NECK_Z and v.co.y < 0.15], context="VERTS")
    bm.to_mesh(b.data)
    bm.free()
    return b


def head():
    """The head: a soft block with the coat's patches painted on its vertices."""
    m = bpy.data.materials.new("coat_rumi")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.75
    bsdf.inputs["Sheen Weight"].default_value = 0.4
    vc = m.node_tree.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    m.node_tree.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=64, radius=1.0)
    o = bpy.context.object
    o.name = "Head"
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        n = v.co.normalized()
        k = 2.8
        r = (abs(n.x) ** k + abs(n.y) ** k + abs(n.z) ** k) ** (1.0 / k)
        p = n / r
        p.x *= 1.0 + 0.05 * max(0.0, -p.z)     # fuller cheeks below
        v.co = Vector((p.x * HEAD_R.x, p.y * HEAD_R.y, p.z * HEAD_R.z)) + HEAD_C
    bm.to_mesh(o.data)
    bm.free()
    ca = o.data.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="POINT")
    # patches on the unit head: ginger around the right eye (viewer's left, -x) reaching the ear and the cheek;
    # brown around the left eye, over the top right and the back
    patches = [((-0.62, -0.55, 0.35), 0.62, GINGER), ((0.62, -0.5, 0.42), 0.58, BROWN), ((0.5, 0.45, 0.6), 0.6, BROWN)]
    for v in o.data.vertices:
        u = Vector(((v.co.x - HEAD_C.x) / HEAD_R.x, (v.co.y - HEAD_C.y) / HEAD_R.y, (v.co.z - HEAD_C.z) / HEAD_R.z))
        col = Vector(CREAM)
        for c, rr, pc in patches:
            d = (u - Vector(c)).length / rr + 0.12 * noise.noise(u * 4.0 + Vector(c))
            col = col.lerp(Vector(pc), max(0.0, min(1.0, (1.0 - d) / 0.07)))
        # the muzzle and the chin stay cream
        if u.y < -0.6 and u.z < 0.1 and abs(u.x) < 0.45:
            col = Vector(CREAM)
        ca.data[v.index].color = (col.x ** 2.2, col.y ** 2.2, col.z ** 2.2, 1.0)   # float colours are linear
    finish(o, m)
    fy = HEAD_C.y - HEAD_R.y
    line = mat("line", DARK, 0.6)
    for sx, ear_col in ((-1, GINGER), (1, BROWN)):
        # eyes: glossy black, a highlight
        ex = Vector((sx * 0.062, fy + 0.012, HEAD_C.z + 0.012))
        sphere("Eye", ex, (0.024, 0.016, 0.028), mat("eye", (0.01, 0.01, 0.012), 0.08), 24, 12)
        sphere("Glint", ex + Vector((0.008, -0.014, 0.012)), (0.007, 0.004, 0.007), mat("glint", (1, 1, 1), 0.2, emit=3.0), 12, 6)
        # a small brow, a little worried
        br = cyl("Brow", (ex.x, fy + 0.006, ex.z + 0.046), 0.0055, 0.04, mat("brow_%d" % sx, BROWN if sx > 0 else (0.75, 0.35, 0.08), 0.6))
        br.rotation_euler = (0.0, math.pi / 2 + sx * 0.18, 0.0)
        # ears: round, set on the top corners, pink inside
        at = HEAD_C + Vector((sx * 0.135, 0.0, HEAD_R.z * 0.88))
        e = sphere("Ear", at, (0.052, 0.024, 0.048), mat("ear_%d" % sx, ear_col, 0.75), 24, 12)
        e.rotation_euler = (0.15, sx * 0.45, sx * 0.3)
        i = sphere("EarIn", at + Vector((sx * -0.004, -0.014, -0.004)), (0.034, 0.012, 0.032), mat("earin", PINK, 0.6), 24, 12)
        i.rotation_euler = (0.15, sx * 0.45, sx * 0.3)
        # whiskers
        for k, ang in enumerate((-0.12, 0.02, 0.16)):
            w = cyl("Whisker", (sx * 0.1, fy + 0.008, HEAD_C.z - 0.03 + k * 0.011), 0.0016, 0.1, line, verts=6)
            w.rotation_euler = (0.0, math.pi / 2, sx * ang)
    nz = HEAD_C.z - 0.028
    sphere("Nose", (0, fy - 0.004, nz), (0.022, 0.012, 0.015), mat("nose", PINK, 0.45), 24, 12)
    cyl("Mouth", (0, fy - 0.001, nz - 0.022), 0.0026, 0.02, line, verts=6)
    for sx in (-1, 1):
        m2 = cyl("MouthL", (sx * 0.01, fy - 0.001, nz - 0.034), 0.0026, 0.024, line, verts=6)
        m2.rotation_euler = (0.0, sx * 1.0, 0.0)
    # the bubble helmet and its rim
    sphere("Helmet", HEAD_C + Vector((0, 0.0, 0.018)), (0.235, 0.22, 0.215), mat("glass", (0.9, 0.95, 1.0), 0.02, alpha=0.1), 48, 24)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.233, minor_radius=0.004, location=HEAD_C + Vector((0, 0.0, 0.018)),
                                     rotation=(math.pi / 2, 0, 0), major_segments=64, minor_segments=8)
    rim = bpy.context.object
    rim.name = "HelmetRim"
    rim.scale = (1.0, 0.98, 1.0)
    finish(rim, mat("rim", (0.92, 0.93, 0.95), 0.25, 0.6))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    body()
    head()
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # stand it on the ground, 1.0 tall as the rest of the crew
    zs = [(o.matrix_world @ v.co).z for o in bpy.context.scene.objects if o.type == "MESH" for v in o.data.vertices]
    zmin = min(zs)
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            o.location.z -= zmin
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=False, export_apply=True)
    print("wrote", OUT)


main()
