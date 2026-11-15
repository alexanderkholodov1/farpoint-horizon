# NASA Space Apps 2026: formulario de entrega, cada campo listo para pegar (español)

Reto: **Space Mission Design Game**. Equipo: **SK Horizon** (Quito, Ecuador; sede Sangolquí, ESPE).
El formulario global de la NASA se llena en inglés con [`form-en.md`](form-en.md). Este archivo es la misma entrega en
español, para la sede, la ficha y el pitch. Los campos van en el orden del formulario.

---

## Nombre del proyecto

```
Farpoint HORIZON
```

---

## Resumen  (máximo 1500 caracteres)

```
En Farpoint HORIZON no lees sobre una misión espacial: la vuelas. Los estudiantes aprenden órbitas, cohetes e instrumentos en capítulos separados y nunca ven cómo cada decisión tira de todas las demás. Nuestro juego 3D en el navegador cierra esa brecha con la misión completa en una sola cadena. Elige una pregunta científica, desde los volcanes del Ecuador hasta el hielo del polo sur lunar. Diseña la nave y arma tu propio cohete mientras indicadores en vivo equilibran masa, energía, datos, delta-v, presupuesto y vida útil. Después vuélala: un ascenso con física real desde la línea ecuatorial, un viaje a la Luna sincronizado con JPL Horizons y un alunizaje sobre el mapa LOLA de la NASA del borde del cráter Shackleton. Mantenla viva desde tierra con la Red de Espacio Profundo y las tormentas solares de NOAA. Todo se mueve con física real, en tiempo real y a escala verdadera, comparado con misiones reales, y cada número cita su fuente. Fallar nunca es una pantalla de derrota: entiendes por qué, cambias algo y vuelves a volar. En la v0.3.0, cuatro cuyes astronautas guían al jugador por seis misiones reales de la NASA en orden, de Apollo 13 a Artemis I. Se juega solo o en equipo de cuatro, en español o inglés, en cualquier dispositivo.
```

---

## Demostración del proyecto

```
https://youtu.be/3xZdPJr71bg
```

## Proyecto

```
https://farpoint-horizon.web.app
```

Repositorio: https://github.com/alexanderkholodov1/farpoint-horizon

---

## Detalles del proyecto

```
QUÉ ES
Farpoint HORIZON es un juego 3D de misiones espaciales que corre en cualquier navegador, sin instalar nada. Una persona, o un equipo de hasta cuatro, lleva una misión desde una pregunta científica hasta los datos que vuelven a la Tierra, y vive en el camino cada compromiso de diseño que enfrenta un equipo real.

EL PROBLEMA QUE RESOLVEMOS
Una misión espacial es un solo sistema: un instrumento mejor pesa más, una nave más pesada necesita un cohete más grande, un cohete más grande se come el presupuesto, y más datos piden más energía y una radio más rápida. Los estudiantes ven estas ideas de a una, en clases y herramientas separadas (una calculadora de órbitas aquí, un simulador de cohetes allá), y casi nunca ven cómo se afectan entre sí. El reto pide un juego que cierre esa brecha. El nuestro pone la cadena completa en manos del jugador.

CÓMO FUNCIONA
1. Una pregunta. Cada misión parte de una necesidad: vigilar los volcanes del Ecuador, seguir El Niño, cartografiar la Luna, mirar galaxias lejanas, encontrar hielo en el polo sur lunar. Las etapas siguen los Concept Maturity Levels del JPL de la NASA.
2. El diseño. Elige la órbita (5, cada una explicada en palabras simples), la plataforma (de un CubeSat 3U a un gran observatorio, 6 en total), 16 instrumentos, paneles solares, batería, radio, control de actitud, propulsión y vida útil. Indicadores en vivo muestran masa, energía, datos, delta-v, costo y años en cada decisión. La nave se arma en 3D y la pieza que causa un problema se ilumina sobre ella.
3. El cohete. Apila motores, tanques y propulsores reales; la ecuación del cohete decide qué llega a órbita. Sin ajustes, los modelos coinciden con los vehículos reales: uno tipo Electron lleva 313 kg a órbita baja (real: 300 kg) y uno tipo Falcon 9, 17,2 t (real: cerca de 17,5 t). La revisión bloquea un lanzamiento que no puede funcionar y dice dónde corregirlo.
4. El vuelo. El lanzamiento son unos ocho minutos de ascenso real desde la línea ecuatorial, sobre los Andes y el Cotopaxi, con gravedad, resistencia del aire, Max-Q y separación de etapas. El viaje a la Luna usa la atracción de la Tierra y de la Luna, con la Luna donde JPL Horizons la ubica el día del vuelo. El control de misión calcula la salida para encontrar a la Luna donde estará. Luego una corrección a medio camino, el frenado en la cara oculta sin radio (como las tripulaciones Apollo) y un alunizaje sobre el relieve LOLA de la NASA en el borde del cráter Shackleton.
5. El control de tierra. Encuentra la débil portadora de la nave con la Red de Espacio Profundo (como hicieron con la Voyager 2 en 2023), responde la alarma 1202 de la computadora (como en el Apollo 11) y decide cómo pasar una tormenta solar pronosticada con las escalas de NOAA.
6. El informe. Puntaje sobre 1000, una nota, metas extra, por qué la misión funcionó o no, las fotos reales que envía una misión como la tuya (el Cotopaxi desde Landsat 8, Shackleton desde LRO y ShadowCam) y las misiones reales que tomaron las mismas decisiones. Rediseña y vuelve a volar con un clic.

NUEVO EN LA v0.3.0: LOS CUYES QUE ESTUVIERON AHÍ
La NASA aprendió fallando, rebotando y chocando, y siempre volvió. Una tripulación de cuatro cuyes astronautas lleva al jugador por seis misiones reales de la NASA en el orden en que ocurrieron. La historia queda tal como la cuenta la NASA: los cuyes ayudan, se asustan y bromean, y los números reales deciden qué pasa. Cada cuy es una de las cuatro estaciones del juego: Rumi el ingeniero, Killa la científica, Inti el piloto, Wayra el control de tierra.
- Apollo 13 (1970): arma el adaptador de CO2 con bolsas, cartón y cinta antes de que se acabe el aire.
- STS-61 (1993): cinco caminatas espaciales contra el reloj para arreglar el Hubble, y luego enfocar la galaxia M100.
- Mars Pathfinder (1997): el descenso real, los rebotes de las bolsas de aire y la primera rueda de Sojourner en Marte.
- LCROSS (2009), DART (2022) y Artemis I (2022) completan la campaña.

POR QUÉ ES DIFERENTE
- El sistema completo en un solo juego. Cada decisión aparece en todo lo que viene después, que es justo lo que el reto pide entender.
- Comportamiento real, nunca un dibujo. Nada se mueve por una curva dibujada a mano. Las trayectorias salen de la gravedad, con constantes y efemérides reales. El tiempo corre en tiempo real, acelerarlo es un control visible, y tamaños y distancias guardan sus proporciones verdaderas.
- Comparado con la realidad. Pruebas automáticas vuelan el juego y lo comparan con valores reales: órbita baja de 87,7 minutos, viaje a la Luna de unas 82 h (Apollo 11: 76 h), órbita lunar de unos 110 km. Nuestras simplificaciones están escritas donde se hacen.
- Los datos de la NASA son el suelo sobre el que vuelas y alunizas, no decoración.
- El error enseña en lugar de castigar. Quedarse corto nunca es una pantalla de derrota; lograr más tiene premio.
- Hecho para todos. Primera misión guiada, glosario con fuentes, explicaciones de una línea, español e inglés, y corre en computadoras escolares, tablets y teléfonos.
- Hecho para jugar en equipo. Cuatro estaciones con sus propias decisiones, como un equipo de misión real, y bots que siguen las mismas reglas ocupan las estaciones vacías.

BENEFICIOS E IMPACTO
Estudiantes, docentes y aficionados tienen un lugar donde probar una misión completa, fallar sin riesgo y entender por qué. Un docente puede llevar una misión como actividad de clase en un navegador. Como está hecho en Ecuador, despega desde la línea ecuatorial y abre con una misión que vigila nuestros volcanes, acerca la ingeniería espacial a estudiantes latinoamericanos en su propio idioma.

HERRAMIENTAS Y TECNOLOGÍA
Godot 4.7 (renderizador GL Compatibility y exportación web de un solo hilo: corre en GPUs integradas y en cualquier hosting estático), GDScript, Python (procesamiento de datos y scripts de modelos 3D), Blender manejado por scripts para cada modelo propio, Firebase Hosting, y CI en GitHub Actions que corre las pruebas de física y construye la versión web en cada cambio. Contenido y balance viven en archivos JSON aparte del código, y cada entrada lleva su fuente. Más de 80 fuentes citadas en docs/sources.md y en los créditos del juego. Licencia MIT.

CREATIVIDAD Y FACTORES CONSIDERADOS
Elegimos física real en lugar de animación guionada para que lo que se aprende sea verdad: escala verdadera con marcadores legibles, tiempo real con reloj visible, y una campaña contada solo con las páginas de la propia NASA. Los cuyes traen humor e identidad andina sin cambiar la historia. Diseñamos para computadoras escolares modestas, para quien nunca oyó la palabra delta-v, para dos idiomas y para las reglas del reto: sin logos ni insignias de la NASA, y con todo uso de IA declarado.

Equipo SK Horizon, Quito, Ecuador: Alexander Kholodov (líder), Sebastián Amaguaya.
```

---

## Uso de IA (Super Intelligence)

```
Código y documentos: Claude Code (Anthropic, Claude Opus 5.5 y Sonnet), Antigravity y Cursor (Composer 2.5). Música: generada con Claude (Anthropic), declarada en los metadatos de los archivos de audio y en los créditos del juego. 3D: borradores de Meshy y TRELLIS (Microsoft, vía Hugging Face) como referencia para los cuatro cuyes; el cuerpo de Rumi es una malla de TRELLIS y el resto se modeló en Blender con nuestros scripts. No hay imágenes ni videos generados con IA, ni logos, insignias o identificadores de misiones de la NASA. La idea, el diseño, la historia y el balance son del equipo.
```

## Datos de la NASA y de otras fuentes

Las mismas tablas de [`form-en.md`](form-en.md) (secciones *NASA Data* y *Space Agency Partner & Other Data*): los
enlaces no cambian, y los nombres pueden quedar en inglés.
