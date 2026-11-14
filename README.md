# SK Horizon — Mission Architect

**NASA Space Apps Challenge 2026 · Reto: [Space Mission Design Game](https://www.spaceappschallenge.org/2026/challenges/space-mission-design-game/)**
Equipo **SK Horizon** · Quito, Ecuador

Juego 3D en Godot donde una persona o un equipo de hasta 4 diseña, lanza y opera una misión espacial completa. Cada decisión tiene consecuencias en la masa, la energía, los datos, el delta-v, el presupuesto y el tiempo.

> *A 3D Godot game where 1–4 players design, launch and operate a full space mission. Every choice trades off mass, power, data, delta-v, budget and lifetime. Spanish UI.*

---

## Cómo ejecutarlo

1. Instala **Godot 4.5 o superior** (sirve la versión de Steam).
2. En el Project Manager: **Import**, eliges `project.godot` y luego **Import & Edit**.
3. Presiona **F5** (o ▶) para jugar.

> Si la PC es lenta, cambia el renderizador a *Compatibility* (esquina superior derecha del editor).

## Flujo del juego

| Etapa | Qué hace el jugador | Nivel de madurez (CML, JPL) |
|---|---|---|
| Objetivo | Elige la pregunta científica: volcanes del Ecuador, El Niño, la Luna, un telescopio, o el modo libre | CML 1 · Idea |
| Diseño | Elige órbita, plataforma (de CubeSat 3U a gran observatorio), instrumentos, energía, comunicaciones, control de actitud, propulsión, lanzador y vida útil | CML 2–3 |
| Revisión | Revisa la compatibilidad (masa vs. cohete, presupuesto, energía, datos, Δv) y cada rol aprueba | CML 4 · Diseño puntual |
| Lanzamiento | Animación 3D con el lanzador elegido. Puede fallar | — |
| Operación | La misión transcurre mes a mes, con tormentas solares, basura espacial, fallas y descubrimientos | — |
| Informe | Puntaje sobre 1000, por qué tuvo éxito o falló y misiones reales parecidas | — |

## Cómo cumple los objetivos del reto

- **Misión completa:** objetivo, requisitos, nave, instrumentos, lanzador, órbita y operación.
- **Recursos visibles y conectados:** un tablero en vivo con presupuesto, masa, energía, batería en eclipse, datos, delta-v, vida útil y ciencia esperada.
- **Cada decisión tiene consecuencia.** Por ejemplo, un radar SAR ve a través de las nubes, pero consume 1,5 kW, genera 400 GB/día y exige una plataforma mediana.
- **No hay una única solución:** un CubeSat barato y una plataforma mediana pueden cumplir el mismo objetivo, con resultados distintos.
- **Colaboración para 1 a 4 jugadores:** roles de Dirección, Ciencia, Ingeniería y Operaciones. Cada rol tiene su meta, todos deben aprobar el diseño y, si alguien lo cambia, hay que volver a aprobarlo.
- **Educativo:** la caja «¿Por qué importa?» explica cada opción, la revisión explica cada problema y el informe enseña por qué pasó lo que pasó.
- **Rejugable:** se puede rediseñar, volver a volar (con otra suerte), elegir entre 3 dificultades y 5 escenarios, y guardar en el ranking local.

## Modelo simplificado (órdenes de magnitud reales)

- **Energía:** generación promedio = potencia de los paneles × (1 − fracción del tiempo en sombra). Si el consumo supera la generación, los instrumentos se turnan.
- **Batería:** debe cubrir el consumo durante el eclipse usando solo el 60 % de su capacidad.
- **Datos:** se bajan al día la velocidad del enlace × el factor de distancia × los minutos de contacto. Lo que no se baja es ciencia perdida.
- **Delta-v:** inserción en la órbita (GEO 1500 m/s, Luna 900 m/s) más el mantenimiento por año. En órbita baja, sin propulsión, el roce con la atmósfera la hace reingresar.
- **Riesgo:** la radiación depende de la órbita. Los CubeSats usan electrónica comercial, más vulnerable. El blindaje y la redundancia reducen las fallas.
- **Puntaje:** objetivos (400), ciencia (300), eficiencia de recursos (200) y metas de equipo (100).

Todos los valores están en `scripts/game_data.gd` y se pueden ajustar sin tocar el resto del código.

## Recursos de la NASA utilizados

- *Design and Develop Science Missions* (NASA Small Spacecraft Systems Virtual Institute): segmentos de lanzamiento, espacio, tierra y usuario.
- *Concept Maturity Levels* (JPL): las etapas del juego siguen los CML 1 a 4.
- *CubeSat 101* (NASA CSLI): plataformas CubeSat, viaje compartido (rideshare) y restricciones.
- Inspiración: *Mission Design Lab* (GSFC) y *Build It Yourself: Webb Telescope*.

## Estructura

```
scenes/main.tscn          escena principal
scripts/game_data.gd      catálogos (escenarios, piezas, órbitas, lanzadores, roles)
scripts/mission.gd        cálculos de presupuesto, revisiones, simulación y puntaje
scripts/ship_builder.gd   nave 3D modular que cambia con cada pieza elegida
scripts/space_builder.gd  Tierra, Luna, cielo, órbitas, cohete y plataforma de lanzamiento
scripts/main.gd           interfaz y flujo del juego
shaders/                  Tierra, nubes, atmósfera, Luna, cielo estrellado, celdas solares
tests/                    pruebas automáticas (lógica y capturas)
```

## Créditos

- Motor: [Godot Engine](https://godotengine.org) (MIT).
- Fuente: Inter, de Rasmus Andersson (SIL Open Font License).
- Textura de la Tierra: generada por el equipo a partir de una máscara pública de tierra y océano (paquete `global-land-mask`, datos NOAA GLOBE).
- Uso de IA: nos apoyamos en un asistente de IA (Claude) para generar y revisar parte del código. El diseño del juego, el balance y las decisiones son del equipo.
