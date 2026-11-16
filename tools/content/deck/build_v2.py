"""Builds EN_17_SK-Horizons_v2.pptx from the presented v1 deck, keeping its look (Segoe UI, glass cards, amber dashes).
Usage (from the repository root): python tools/content/deck/build_v2.py spaceapps/local-pitch/EN_17_SK-Horizons.pptx spaceapps/global-submission/deck/EN_17_SK-Horizons_v2.pptx spaceapps/global-submission/deck/img
The images are in-game captures (shots/ from tests/*shot.tscn, cropped) and the crew portraits of assets/story/portraits.
"""
import sys, copy
from xml.sax.saxutils import escape
from lxml import etree
from pptx import Presentation
from pptx.util import Emu, Inches

SRC, OUT, IMG = sys.argv[1], sys.argv[2], sys.argv[3]
NS = {"a": "http://schemas.openxmlformats.org/drawingml/2006/main",
      "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
      "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships"}
E = lambda inch: int(round(inch * 914400))
WHITE, MUTED, AMBER, BLUE = "EFF4FF", "A9B9D4", "FFA842", "78B8FF"
FOOT = "Farpoint HORIZON · SK-Horizons · NASA Space Apps Challenge 2026 · Sangolquí"

prs = Presentation(SRC)
S = list(prs.slides)


def run(text, size=1350, color=MUTED, semibold=False, spc=None, link=None):
    face = "Segoe UI Semibold" if semibold else "Segoe UI"
    sp = f' spc="{spc}"' if spc else ""
    return (f'<a:r><a:rPr sz="{size}"{sp} lang="en-US"><a:solidFill><a:srgbClr val="{color}"/></a:solidFill>'
            f'<a:latin typeface="{face}"/></a:rPr><a:t xml:space="preserve">{escape(text)}</a:t></a:r>')


def para(runs, line=None, after=0, bullet=False, align=None, indent=False):
    ln = f'<a:lnSpc><a:spcPts val="{line}"/></a:lnSpc>' if line else ""
    al = f' algn="{align}"' if align else ""
    if indent:
        al += ' marL="215900"'
    if bullet:
        return (f'<a:p><a:pPr marL="215900" indent="-215900"{al}>{ln}<a:spcAft><a:spcPts val="{after}"/></a:spcAft>'
                f'<a:buClr><a:srgbClr val="{AMBER}"/></a:buClr><a:buFont typeface="Segoe UI"/><a:buChar char="–"/></a:pPr>'
                + "".join(runs) + "</a:p>")
    return f'<a:p><a:pPr{al}>{ln}<a:spcAft><a:spcPts val="{after}"/></a:spcAft></a:pPr>' + "".join(runs) + "</a:p>"


def textbox(name, x, y, w, h, paras, anchor="t"):
    return (f'<p:sp xmlns:p="{NS["p"]}" xmlns:a="{NS["a"]}"><p:nvSpPr><p:cNvPr id="0" name="{name}"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>'
            f'<p:spPr><a:xfrm><a:off x="{E(x)}" y="{E(y)}"/><a:ext cx="{E(w)}" cy="{E(h)}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr>'
            f'<p:txBody><a:bodyPr wrap="square" lIns="0" tIns="0" rIns="0" bIns="0" anchor="{anchor}"><a:noAutofit/></a:bodyPr><a:lstStyle/>'
            + "".join(paras) + "</p:txBody></p:sp>")


def card(name, x, y, w, h, radius=8399):
    return (f'<p:sp xmlns:p="{NS["p"]}" xmlns:a="{NS["a"]}"><p:nvSpPr><p:cNvPr id="0" name="{name}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr>'
            f'<a:xfrm><a:off x="{E(x)}" y="{E(y)}"/><a:ext cx="{E(w)}" cy="{E(h)}"/></a:xfrm><a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val {radius}"/></a:avLst></a:prstGeom>'
            '<a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:srgbClr val="78B8FF"><a:alpha val="17000"/></a:srgbClr></a:gs>'
            '<a:gs pos="55000"><a:srgbClr val="1447A8"><a:alpha val="11000"/></a:srgbClr></a:gs><a:gs pos="100000"><a:srgbClr val="FFA842"><a:alpha val="9000"/></a:srgbClr></a:gs></a:gsLst>'
            '<a:lin ang="2100000" scaled="0"/></a:gradFill><a:ln w="6350"><a:solidFill><a:srgbClr val="78B8FF"><a:alpha val="30000"/></a:srgbClr></a:solidFill></a:ln></p:spPr>'
            '<p:txBody><a:bodyPr rtlCol="0" anchor="ctr"/><a:lstStyle/><a:p><a:endParaRPr lang="en-US"/></a:p></p:txBody></p:sp>')


def chip(name, x, y, w, text):
    return (f'<p:sp xmlns:p="{NS["p"]}" xmlns:a="{NS["a"]}"><p:nvSpPr><p:cNvPr id="0" name="{name}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr>'
            f'<a:xfrm><a:off x="{E(x)}" y="{E(y)}"/><a:ext cx="{E(w)}" cy="{E(0.32)}"/></a:xfrm><a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 50000"/></a:avLst></a:prstGeom>'
            '<a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:srgbClr val="78B8FF"><a:alpha val="24000"/></a:srgbClr></a:gs><a:gs pos="100000"><a:srgbClr val="1447A8"><a:alpha val="18000"/></a:srgbClr></a:gs></a:gsLst><a:lin ang="5400000" scaled="0"/></a:gradFill>'
            '<a:ln w="6350"><a:solidFill><a:srgbClr val="78B8FF"><a:alpha val="35000"/></a:srgbClr></a:solidFill></a:ln></p:spPr>'
            '<p:txBody><a:bodyPr wrap="none" lIns="0" tIns="0" rIns="0" bIns="0" rtlCol="0" anchor="ctr"/><a:lstStyle/>'
            + para([run(text, 1050, WHITE, True)], 1260, 0, align="ctr") + "</p:txBody></p:sp>")


def arrow(x, y):
    return textbox("Flow arrow", x, y, 0.28, 0.32, [para([run("→", 1200, BLUE)], align="ctr")], anchor="ctr")


def add(slide, xml):
    el = etree.fromstring(xml)
    tree = slide.shapes._spTree
    ids = [int(e.get("id")) for e in tree.iter("{%s}cNvPr" % NS["p"])]
    el.find(".//p:cNvPr", NS).set("id", str(max(ids + [1]) + 1))
    tree.append(el)
    return el


def shape(slide, name, nth=0):
    found = [s for s in slide.shapes if s.name == name]
    return found[nth]


def set_paras(shp, paras):
    body = shp._element.find(".//p:txBody", NS)
    for p in body.findall("a:p", NS):
        body.remove(p)
    for x in paras:
        body.append(etree.fromstring(x.replace("<a:p>", f'<a:p xmlns:a="{NS["a"]}">', 1)))


def move(shp, x=None, y=None, w=None, h=None):
    if x is not None: shp.left = E(x)
    if y is not None: shp.top = E(y)
    if w is not None: shp.width = E(w)
    if h is not None: shp.height = E(h)


def drop(slide, names):
    for s in list(slide.shapes):
        if s.name in names:
            s._element.getparent().remove(s._element)


def pic(slide, path, x, y, w, h):
    return slide.shapes.add_picture(path, E(x), E(y), E(w), E(h))


def title(shp, text, size=3100, line=3348):
    set_paras(shp, [para([run(text, size, WHITE, True)], line)])


def bullets(items, size=1350, line=1809, after=600):
    return [para([run(a, size, WHITE, True), run(b, size, MUTED)], line, after, bullet=True) for a, b in items]


def notes(slide, text):
    slide.notes_slide.notes_text_frame.text = text


def footer(slide, n):
    set_paras(shape(slide, "Footer"), [para([run(FOOT, 850, MUTED, spc=60)], 1105)])
    set_paras(shape(slide, "Slide number"), [para([run(f"{n} / 7", 850, MUTED)], 1105, align="r")])


# ===================================================================================== 1. COVER
s1 = S[0]
set_paras(shape(s1, "Tagline"), [para([run("Six real NASA missions. Four cuyes who were there.", 1900, WHITE)], 2470, 0, align="ctr"),
                                  para([run("And one mission that is all yours.", 1900, WHITE, True)], 2470, 0, align="ctr")])
set_paras(shape(s1, "Team"), [para([run("Team SK-Horizons", 1400, WHITE, True), run(" · Quito, Ecuador · Sangolquí local event (ESPE)", 1400, WHITE)], 1890, 0, align="ctr"),
                              para([run("Alexander Kholodov · Sebastian Amaguaya", 1400, WHITE)], 1890, 0, align="ctr")])
notes(s1, "(15 s) We are SK-Horizons, from Quito. Our answer to the Space Mission Design Game challenge is Farpoint HORIZON: "
          "six real NASA missions lived with a crew of four cuyes, and a mission of your own, from the first idea to the data coming home.")

# ===================================================================================== 2. PROBLEM
s2 = S[1]
footer(s2, 2)
set_paras(shape(s2, "Bullets"), bullets([
    ("Behind GPS and every photo from space ", "are real missions that balance mass, power, data, budget and time."),
    ("Students learn the pieces apart: ", "orbits one day, rockets another. Nobody sees how one choice pulls on all the others."),
    ("Ecuador is a strategic place to launch from, ", "and understanding missions should not take formulas and simulators that need special training."),
]))
move(shape(s2, "Bullets"), y=2.85, h=2.45)
move(shape(s2, "Text"), y=5.4)
notes(s2, "(30 s) A satellite took this picture of Sangay. For it to exist, someone chose the orbit, the power, how much data to send and what it cost. "
          "That is taught as theory, one piece at a time. We want anyone to live those decisions together, as a mission team does.")

# ===================================================================================== 3. SOLUTION
s3 = S[2]
footer(s3, 3)
title(shape(s3, "Title"), "From the first idea to the data coming home")
set_paras(shape(s3, "Text"), [para([
    run("Pick a question worth answering, design the craft and stack your own rocket while live gauges trade ", 1350, MUTED),
    run("mass, power, data, delta-v, money and time", 1350, WHITE, True),
    run(". Then fly it: the climb from the equator, the trip to the Moon timed with JPL Horizons, a landing on NASA's real map of the south pole, "
        "and ground control through the Deep Space Network. Missing something is never game over: see why, change one thing, fly again.", 1350, MUTED)], 1809)])
move(shape(s3, "Text"), y=2.4, h=1.05)
drop(s3, ["TextBox 23"])
vid = shape(s3, "Online Media 21")
move(vid, x=5.2, y=3.6, w=6.4, h=3.6)
add(s3, card("Card", 0.83, 3.6, 4.0, 2.1))
add(s3, textbox("Card heading", 1.03, 3.78, 3.6, 0.2, [para([run("PLAY TOGETHER", 950, AMBER, True, 400)], 1235)]))
add(s3, textbox("Text", 1.03, 4.08, 3.6, 2.0, bullets([
    ("Alone or with up to 3 friends, ", "on one screen or online."),
    ("Four stations: ", "engineer, scientist, pilot, ground control, each with its own decisions."),
    ("The cuyes ", "take any empty station."),
], 1200, 1600, 400)))
add(s3, textbox("Caption", 0.83, 5.95, 4.0, 0.5, [para([run("Gameplay video (30 s): ", 900, MUTED), run("youtu.be/3xZdPJr71bg", 900, AMBER, True)], 1215),
                                                  para([run("Play it now: ", 900, MUTED), run("farpoint-horizon.web.app", 900, AMBER, True)], 1215)]))
notes(s3, "(40 s) The whole mission is one chain. You choose a need, design the craft and your own rocket, and every choice moves the gauges. "
          "Then you fly it, in real time and at true scale, and keep it alive from the ground. Up to four friends share it, each at a station.")

# ===================================================================================== 4. THE STORY (was the technology slide)
s4 = S[4]
footer(s4, 4)
set_paras(shape(s4, "Label"), [para([run("NEW IN v0.3.0 · THE STORY CAMPAIGN", 1100, BLUE, True, 300)], 1430)])
title(shape(s4, "Title"), "Six real NASA missions, four cuyes who were there")
move(shape(s4, "Title"), w=11.67, h=0.62)
drop(s4, ["Bullets", "Card", "Card heading", "Text", "Caption", "Picture 14", "Picture 15"])
add(s4, textbox("Text", 0.83, 1.78, 11.67, 0.5, [para([
    run("NASA learned by failing, bouncing and crashing, and it always came back. History stays exactly as NASA tells it: ", 1250, MUTED),
    run("the cuyes help, panic and joke, while the real events decide the outcome.", 1250, WHITE, True)], 1650)]))
missions = [
    ("1970", "Apollo 13", "Build the CO₂ adapter from bags, cardboard and tape before the air runs out.", "m1.jpg"),
    ("1993", "Hubble's first repair", "Five spacewalks against the clock to give the telescope its \"glasses\".", "m2.jpg"),
    ("1997", "Mars Pathfinder", "Land by bouncing on airbags, then roll Sojourner onto Mars.", "m3.jpg"),
    ("2009", "LCROSS", "\"The plan is to crash?\" \"Yes.\" Hit Cabeus and catch the ice in the plume.", "m4.jpg"),
    ("2022", "DART", "Hit an asteroid to push it: the first test of planetary defense.", "m5.jpg"),
    ("2022", "Artemis I", "The finale: around the Moon and home at Mach 32.", "m6.jpg"),
]
cw, gap, x0, y0 = 1.8, 0.174, 0.83, 2.5
for i, (yr, name, what, img) in enumerate(missions):
    x = x0 + i * (cw + gap)
    add(s4, card("Mission card", x, y0, cw, 2.6, 6000))
    pic(s4, f"{IMG}/{img}", x + 0.08, y0 + 0.08, cw - 0.16, (cw - 0.16) * 9 / 16)
    add(s4, textbox("Mission", x + 0.12, y0 + 1.15, cw - 0.24, 0.5, [
        para([run(f"{i + 1} · {yr}", 900, AMBER, True, 200)], 1200),
        para([run(name, 1250, WHITE, True)], 1550)]))
    add(s4, textbox("Mission text", x + 0.12, y0 + 1.72, cw - 0.24, 1.25, [para([run(what, 1050, MUTED)], 1350)]))
crew = [("Rumi", "engineer", "rumi.png"), ("Killa", "scientist", "killa.png"), ("Inti", "pilot", "inti.png"), ("Wayra", "ground control", "wayra.png")]
add(s4, card("Crew card", 0.83, 5.3, 11.67, 1.05))
add(s4, textbox("Card heading", 1.03, 5.5, 2.0, 0.65, [para([run("THE CREW", 950, AMBER, True, 400)], 1235),
                                                       para([run("each one a station", 1000, MUTED)], 1400)]))
for i, (n, role, img) in enumerate(crew):
    x = 3.0 + i * 2.38
    pic(s4, f"{IMG}/{img}", x, 5.38, 0.88, 0.88)
    add(s4, textbox("Crew", x + 0.98, 5.57, 1.35, 0.6, [para([run(n, 1250, WHITE, True)], 1500), para([run(role, 1000, MUTED)], 1300)]))
add(s4, textbox("Caption", 0.83, 6.5, 11.67, 0.25, [para([run("In-game captures. Every date and figure from NASA's mission pages; each chapter ends on NASA's own photo. Each mission also plays on its own, without the story.", 900, MUTED)], 1215)]))
notes(s4, "(45 s) New in version 0.3.0: a crew of four cuyes, Andean guinea pigs, who were there at six real NASA missions, in order. "
          "Apollo 13's air filter, Hubble's repair, Pathfinder's bounces, LCROSS's crash, DART's push and Artemis I. Every fact is NASA's; the cuyes bring the humor.")

# ===================================================================================== 5. NASA DATA
s5 = S[3]
footer(s5, 5)
title(shape(s5, "Title"), "NASA data is the ground you fly on")
set_paras(shape(s5, "Bullets"), bullets([
    ("LRO LOLA: ", "the real ground of the landing at Shackleton's rim."),
    ("JPL Horizons: ", "where the Moon is on launch day; the trip meets it."),
    ("GIBS, Landsat, ASTER, SRTM: ", "the Earth, the Andes, our volcanoes."),
    ("NSSDC fact sheets: ", "size, mass and gravity of every body."),
    ("Deep Space Network: ", "ground control's three complexes, each with a 70 m dish."),
    ("Mission pages, Apollo Flight Journal: ", "the six chapters."),
], 1200, 1560, 300))
move(shape(s5, "Bullets"), y=2.25, h=2.55)
drop(s5, ["Flow step", "Flow arrow"])
chips = [("NASA archives & APIs", 1.75), ("our scripts", 1.0), ("cited data files", 1.35)]
x = 0.83
for i, (t, w) in enumerate(chips):
    add(s5, chip("Flow step", x, 4.5, w, t)); x += w
    add(s5, arrow(x, 4.5)); x += 0.28
add(s5, chip("Flow step", x, 4.5, 0.95, "the game"))
move(shape(s5, "Card"), y=5.0, h=1.2)
move(shape(s5, "Card heading"), y=5.15)
set_paras(shape(s5, "Text"), [para([
    run("Rocket of the Electron type: ", 1150, MUTED), run("313 kg", 1150, AMBER, True), run(" to low orbit (real 300 kg). Low orbit ", 1150, MUTED),
    run("87.7 min", 1150, AMBER, True), run(". Trip to the Moon ", 1150, MUTED), run("82 h", 1150, AMBER, True),
    run(" (Apollo 11: 76 h). Cotopaxi ", 1150, MUTED), run("5,876 m", 1150, AMBER, True), run(" (published 5,897 m).", 1150, MUTED)], 1550)])
move(shape(s5, "Text"), y=5.4, h=0.75)
notes(s5, "(40 s) NASA data is not decoration here: you land on LOLA's map of the south pole, the trip is timed to JPL Horizons, "
          "the Earth is GIBS and Landsat. Our scripts turn each source into a data file that cites it, and the tests check the game against real values.")

# ===================================================================================== 6. IMPACT, PLAY IT, NEXT
s6 = S[5]
footer(s6, 6)
title(shape(s6, "Title"), "From Ecuador's volcanoes to the Moon, for everyone")
move(shape(s6, "Title"), h=1.1)
set_paras(shape(s6, "Bullets", 0), bullets([
    ("For students, teachers and the curious: ", "nothing to install, plain words, English and Spanish."),
    ("A class can play it today: ", "a guided first mission, then the story, then their own."),
    ("Identity: ", "launch from the equator, watch Cotopaxi and Sangay, follow El Niño."),
], 1250, 1650, 450))
move(shape(s6, "Bullets", 0), y=2.35, h=1.95)
drop(s6, ["Picture 16"])
move(shape(s6, "Card"), y=4.4, h=1.65)
move(shape(s6, "Card heading"), y=4.55)
set_paras(shape(s6, "Card heading"), [para([run("PLAY IT · NEXT STEPS", 950, AMBER, True, 400)], 1235)])
set_paras(shape(s6, "Bullets", 1), bullets([
    ("Live: ", "farpoint-horizon.web.app"),
    ("Code: ", "github.com/alexanderkholodov1/farpoint-horizon (MIT)"),
    ("Next: ", "classroom sessions in Ecuador, more NASA missions, a teacher's guide."),
], 1150, 1500, 300))
move(shape(s6, "Bullets", 1), y=4.85, h=1.5)
notes(s6, "(30 s) It runs in any browser, in two languages, so a class can play it today. Next we want to take it into Ecuadorian classrooms and add more NASA missions.")

# ===================================================================================== 7. TRANSPARENCY, TEAM
s7 = S[6]
footer(s7, 7)
set_paras(shape(s7, "Bullets"), bullets([
    ("Made by us: ", "the game, the story, the 3D models (our scripts; Rumi's body is a TRELLIS mesh) and the sounds."),
    ("Cited: ", "every source is in docs/sources.md and in the game's credits. No NASA logos; no AI-generated images in the game or the deck."),
    ("AI, disclosed: ", "Claude Code (code, research), Antigravity and Cursor (code); Meshy and TRELLIS 3D drafts for the cuyes; music composed by our script, written with Claude's help."),
], 1150, 1500, 350))
move(shape(s7, "Bullets"), w=4.25, h=2.5)
set_paras(shape(s7, "Card heading"), [para([run("TEAM SK-HORIZONS", 950, AMBER, True, 400)], 1235)])
move(shape(s7, "Card"), y=4.75, w=4.25, h=1.5)
move(shape(s7, "Card heading"), y=4.9, w=3.9)
set_paras(shape(s7, "Bullets", 1), [
    para([run("Alexander Kholodov", 1250, AMBER, True)], 1500, 0, bullet=True),
    para([run("planning, flight physics, testing, design polish", 1000, MUTED)], 1300, 250, indent=True),
    para([run("Sebastian Amaguaya", 1250, AMBER, True)], 1500, 0, bullet=True),
    para([run("the story and the cuyes, the missions, 3D models, music", 1000, MUTED)], 1300, 0, indent=True)])
move(shape(s7, "Bullets", 1), y=5.15, w=3.9, h=1.3)
move(shape(s7, "Title"), w=4.6)
move(shape(s7, "Picture 14"), x=5.9, y=1.45, w=6.6, h=6.6 * 5.02 / 7.84)
move(shape(s7, "Caption"), x=5.9, y=1.45 + 6.6 * 5.02 / 7.84 + 0.12, w=6.6)
notes(s7, "(20 s) Everything is ours and everything is cited, with every use of AI disclosed. We are Alexander and Sebastian, SK-Horizons. Thank you.")

# ===================================================================================== ORDER: story after the solution
lst = prs.slides._sldIdLst
ids = list(lst)
order = [0, 1, 2, 4, 3, 5, 6]
for el in ids:
    lst.remove(el)
for i in order:
    lst.append(ids[i])
prs.save(OUT)
print("saved", OUT)
