# CLAUDE.md — SK Horizon: Mission Architect

Contexto para continuar el proyecto en Claude Code. Responder en **español**, de forma concisa.

## Qué es
- Juego 3D en **Godot 4.7** (versión de Steam en la PC del equipo) para el **NASA Space Apps Challenge 2026**, reto **"Space Mission Design Game"** (categoría *Games*). Equipo **SK Horizon**, sede de Quito, Ecuador.
- Reto: un juego interactivo para diseñar, gestionar y simular una misión espacial completa (objetivo, nave, instrumentos, lanzador, órbita, presupuesto, masa, energía, datos, comunicaciones y vida útil), con colaboración de hasta 4 jugadores, evaluación y retroalimentación educativa.

## Plazos (domingo 15/11/2026, hora de Ecuador)
- **9:00 AM:** cierre de la entrega del **pitch (PPT, máximo 7 slides)** y del **repositorio git**.
- **11:00 AM:** exposición. **5 min de pitch y 2 min de preguntas.**

## Estado actual
- El juego está completo y jugable de principio a fin: menú → equipo → objetivo → diseño en 8 pasos → revisión → lanzamiento → operación mes a mes → informe → ranking.
- Probado sin errores en Godot 4.5.1 y 4.7.1 (Linux, renderizador Compatibility) con `tests/autoshot.tscn` y `tests/fuzz.gd`.
- **Problema abierto:** en la laptop del equipo (Asus VivoBook Go, **AMD Radeon integrada**, Windows, Godot 4.7.2 Steam) la v1 (Forward+/Vulkan) se cerraba y el editor quedó pidiendo modo recuperación. La v2/v3 usa **gl_compatibility**, sin MSAA 3D. **Falta confirmar que la v3 llega al menú en esa PC.**
  - Registro del juego: `%APPDATA%\Godot\app_userdata\SK Horizon - Mission Architect\logs\godot.log`
  - `main.gd` imprime trazas `[SKH] ...` en cada paso del arranque (`flush_stdout_on_print=true`). La última traza indica dónde se cae.
  - Si se cae, sospechosos en orden: shader del cielo (`shaders/sky.gdshader`, bucles de estrellas), nubes y atmósfera (transparencias), glow del `Environment`, sombras del `DirectionalLight3D`, `CPUParticles3D`. Probar desactivándolos uno a uno; conviene un "modo seguro" que los apague.
- **Pendiente:** subir el proyecto a un repositorio público de GitHub (sin la carpeta `.godot/`), hacer el pitch de 7 slides con su guion de 5 minutos y, opcionalmente, quitar las trazas `[SKH]` antes de la entrega final.

## Arquitectura (todo se construye por código; `main.tscn` es solo un nodo con script)
| Archivo | Rol |
|---|---|
| `project.godot` | Escena principal `res://scenes/main.tscn`; autoload `GameData`; renderizador gl_compatibility |
| `scripts/game_data.gd` | **Catálogos y balance:** escenarios, plataformas (bus), instrumentos, paneles, baterías, comunicaciones, ADCS, propulsión, órbitas, lanzadores, roles, pasos/CML y dificultad |
| `scripts/mission.gd` | Modelo: `compute()` (masa, energía, batería, datos, Δv, vida útil, costo, revisiones fatal/warn/ok, metas por rol), `simulate(seed)` (eventos mes a mes) y `score()` (objetivos 400, ciencia 300, eficiencia 200, equipo 100) |
| `scripts/ship_builder.gd` | Nave 3D modular con primitivas, según las piezas elegidas |
| `scripts/space_builder.gd` | Cielo, Tierra (textura con costas reales y marcador de Ecuador), Luna procedural, anillos de órbita, cohete, plataforma de lanzamiento con volcanes, partículas, `Label3D` |
| `scripts/main.gd` | Interfaz (tema en código, fuente Inter), flujo de pantallas, cámara orbital, animación de lanzamiento, reproducción de la simulación, informe, ranking en `user://ranking.json` |
| `shaders/` | earth, clouds, atmosphere, moon, sky, solar_cell, engine_glow, `noise.gdshaderinc` |
| `tests/autoshot.gd` | Recorrido automático que guarda capturas en `/tmp/shots` (Linux, xvfb). Solo para desarrollo |
| `tests/fuzz.gd` | 600 diseños aleatorios: `godot --headless -s res://tests/fuzz.gd` |

### Detalles importantes de GDScript
- No usar `class_name`: los scripts se cargan con `preload` (evita depender de la caché del editor).
- Evitar `:=` cuando el valor es Variant (por ejemplo, el valor de un diccionario): da error de parseo. Usar el tipo explícito.
- `get_node()` devuelve `Node`: tiparlo como `Node3D` antes de usar `.visible`, `.scale` o `.rotate_y`.
- Las fuentes Inter no tienen ✎ ni ✕; sí tienen ✓ ✗ ⚠ ★ ● ▶ ₂.

## Modelo de juego (resumen)
- Energía: generación promedio = paneles × (1 − fracción en eclipse). Batería ≥ consumo × minutos de eclipse / 60 / 0,6.
- Datos bajados por día (GB) = Mbps × factor de distancia × minutos de contacto × 60 / 8 / 1000.
- Δv: inserción (GEO 1500, Luna 900, L2 60 m/s) + mantenimiento por año. En LEO/SSO sin propulsión, la vida útil la limita el frenado atmosférico.
- **Bloqueantes (no deja lanzar):** sin instrumentos, no caben, demasiado grande, sobrepeso de la plataforma o del cohete, presupuesto excedido, órbita inútil para el objetivo.
- **Advertencias (se puede lanzar, con consecuencias en la simulación):** energía, batería, datos, apuntado, Δv, vida útil, radiación y reserva baja.
- Escenarios: volcanes del Ecuador, El Niño, Luna, telescopio (L2) y libre. Dificultades fácil, normal y difícil.
- Roles: Director/a, Científico/a, Ingeniero/a y Operaciones. En modo equipo, todos deben aprobar el diseño, y cualquier cambio reinicia las aprobaciones.

## Recursos de la NASA usados (citarlos en el pitch y el README)
- *Design and Develop Science Missions*: segmentos de lanzamiento, espacio, tierra y usuario.
- *Concept Maturity Levels (JPL)*: las etapas del juego son CML 1 a 4.
- *CubeSat 101*: plataformas CubeSat y viaje compartido.
- Inspiración: Mission Design Lab y el juego del telescopio Webb.

## Guion sugerido para el pitch (7 slides, 5 min)
1. Problema: el diseño de misiones se enseña de forma abstracta.
2. Solución: SK Horizon, capturas del juego.
3. Cómo se juega: CML 1 → 4, lanzamiento, operación, informe.
4. Trade-offs reales: un ejemplo con el radar SAR o con un CubeSat frente a un SmallSat.
5. Modo equipo y valor educativo.
6. Impacto local: volcanes del Ecuador, El Niño y el NEE-01 Pegaso.
7. Tecnología, recursos de la NASA, próximos pasos y equipo.
