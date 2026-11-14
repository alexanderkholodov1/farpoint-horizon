extends "res://scripts/screens/screen.gd"
## Overlay: how to play, in plain words. Opened with main.overlay("howto").


func enter(_args: Dictionary) -> void:
	var v := Kit.overlay(self, "Cómo se juega", 960, 680, queue_free)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = false
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.text = """[b]1. Elige un objetivo[/b] (CML 1). Cada misión nace de una pregunta científica: ¿cuándo va a erupcionar un volcán? ¿Llega El Niño?

[b]2. Diseña la misión paso a paso[/b] (CML 2 a 4), como en el Mission Design Lab de la NASA: órbita, plataforma, instrumentos, energía, comunicaciones, control, propulsión y lanzador. Cada decisión cambia las demás: el tablero de la derecha lo muestra en vivo.

[b]3. Revisa y lanza.[/b] Lo rojo impide lanzar (no cabe, no alcanza el dinero). Lo amarillo se puede lanzar… pero tendrá consecuencias en la operación.

[b]4. Opera la misión.[/b] Mira los meses pasar: tormentas solares, basura espacial, fallas… y descubrimientos. Un buen diseño resiste los imprevistos.

[b]5. Aprende del informe[/b] y rediseña. No hay una única respuesta correcta.

[b]Recursos clave[/b]
• [b]Masa:[/b] todo pesa. La plataforma y el cohete tienen un límite.
• [b]Energía:[/b] los paneles no producen en la sombra de la Tierra; la batería debe cubrir ese tiempo.
• [b]Datos:[/b] un instrumento que genera más datos de los que la antena puede enviar desperdicia ciencia.
• [b]Delta-v:[/b] el «cambio de velocidad» que da la propulsión. Ir a la Luna o a GEO exige mucho.
• [b]Presupuesto y tiempo:[/b] más años de operación = más ciencia y más costo.

[b]Modo equipo:[/b] hasta 4 jugadores con roles (Dirección, Ciencia, Ingeniería y Operaciones). Cada rol tiene su meta; todos deben aprobar el diseño antes de lanzar.

[b]Controles:[/b] arrastra con el mouse para girar la cámara, rueda para acercar.

Basado en recursos de la NASA: «Design and Develop Science Missions», «CubeSat 101» y los Concept Maturity Levels (CML) del JPL."""
	v.add_child(rt)
