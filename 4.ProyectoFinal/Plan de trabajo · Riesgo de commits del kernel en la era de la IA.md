# Plan de trabajo · Riesgo de commits del kernel en la era de la IA

Nov 4, 2026 · @juferoga

## Resumen

El 3 de diciembre entregas un artículo que predice el riesgo de los commits del kernel de Linux y mide si ese modelo aguanta la ola de contribuciones marcadas con `Assisted-by`. Los cinco entregables salen de esa misma línea de trabajo, sin rehacer nada entre uno y otro.

**Pregunta:** ¿un modelo difuso-evolutivo interpretable (≤15 reglas) mantiene su desempeño cuando pasa de commits de la era pre-IA a commits de 2026, frente a una referencia trivial (clase mayoritaria), regresión logística y gradient boosting?

**Etiqueta:** el commit es "riesgoso" si un `Fixes:` posterior lo cita en ≤90 días. Solo entran commits con al menos 90 días de observación.

**Criterio de éxito (provisional):** AUC-PR del modelo difuso ≥95 % del mejor de referencia, y una caída menor entre validación (pre-IA) y test (era IA). Se fija definitivo en la Entrega 1.

**Pesos del curso:** entregables 1 a 4 valen 10 % cada uno, la entrega final 40 % (rúbrica de 100 puntos) y la sustentación 20 %, individual. Un entregable semanal tardío pierde 10 % por día, hasta 2 días; la entrega final no admite retraso.

**Decisiones ya tomadas**

- Equipo de una persona; datos públicos, así que no hace falta solicitud de aprobación.
- Entrenar con el pasado, validar con ventanas móviles y bloquear el test de 2026 hasta la Entrega 5.
- Métrica principal: AUC-PR; secundarias: MCC, AUC-ROC, sensibilidad y especificidad. Significancia: McNemar sobre las mismas observaciones de prueba e intervalos de confianza del 95 % por bootstrap, declarados antes de ver resultados (un Wilcoxon con 5 semillas no sirve: su p mínimo es 0,0625).
- Solo variables conocidas al momento del commit, para evitar fuga de datos.

**Dos fechas de decisión**

| Fecha | Compuerta | Si pasa | Si falla |
| --- | --- | --- | --- |
| Vie 6 nov | Viabilidad del kernel: el dataset de Zenodo trae fechas y trailers usables, y la otra máquina clona el repo completo | Plan A: kernel | Plan B: AIDev (PRs de agentes) |
| Dom 15 nov | Con la Entrega 2 lista: hay suficientes commits etiquetados y la exploración muestra deriva entre años | Seguir con el plan A | Pasar al plan B con el pipeline ya armado |

**Preparar la otra máquina (hoy o mañana)**

- Linux o WSL, ≥50 GB libres y ≥16 GB de RAM.
- Clon completo de `torvalds/linux` (historial entero, no el superficial que usé yo para explorar).
- Python con pandas, scikit-learn, un gradient boosting y una librería de optimización evolutiva.
- El script `count_ai.py` sirve de punto de partida para la minería. Ojo: lo que se entrega debe correr en una sesión limpia de Colab, así que el cuaderno parte de la tabla ya procesada y anonimizada (con enlace de descarga) y la minería del kernel va aparte, como script.

## Entrega 1 · dom 8 nov, 11:59 p.m.

El PDF de 3–4 páginas IEEE queda listo el sábado en la noche; el domingo solo se revisa y se sube. Son cuatro días, y el cuello de botella es leer abstracts, no escribir.

**Jueves 5 · búsqueda**

- [ ] Adaptar la ecuación al kernel: bloque A = dominio (commit, "code change", patch, "pull request", "Linux kernel") Y bloque B = tarea (predict\*, risk, defect, "bug-introducing", "just-in-time") Y bloque C = método (fuzzy, "rule-based", evolutionary, "genetic algorithm", interpretab\*). Límite 2019–2026 más los clásicos muy citados; la matriz exige ≥10 trabajos desde 2021.
- [ ] Correrla en al menos dos bases (Scopus o IEEE Xplore, y Google Scholar o arXiv; ACM DL si hay acceso). Escribir antes los criterios de inclusión: aborda la misma tarea, reporta métricas cuantitativas, describe los datos. Anotar el conteo de cada etapa para el diagrama tipo PRISMA: encontrados, tras duplicados, tras filtro por título y resumen, tras texto completo e incluidos. Si el bloque C deja pocos resultados, hacer una segunda búsqueda sin él, con "concept drift" y "temporal validation".
- [ ] Pasar la lista a una hoja con título, año, venue y enlace.
- [ ] En la otra máquina: lanzar el clon completo del kernel (corre solo mientras trabajas en lo demás).

**Viernes 6 · matriz del estado del arte**

- [ ] Compuerta de viabilidad (ver Resumen): abrir el dataset de Zenodo y confirmar fechas, trailers `Fixes:` y tamaño.
- [ ] Leer abstracts y llenar la matriz con las 8 columnas del curso: referencia, problema y datos, paradigma y modelo, referencias comparadas, validación, métrica y resultado, limitaciones, relevancia para el proyecto.
- [ ] Meta: ≥15 trabajos, de ellos ≥10 desde 2021. Partir de la lista de candidatos ya reunida (JITLine, ApacheJIT, validez retrospectiva, calibración, conformal JIT, genetic-fuzzy, deriva conceptual, SZZ en Linux, "Will My Patch Make It?") y completar con lo que salga de la búsqueda.
- [ ] Marcar con claridad cuáles leíste completos y cuáles solo por abstract.

**Sábado 7 · síntesis y redacción**

- [ ] Escribir la síntesis (borrador de la sección II) y terminarla en la brecha: falta validación temporal sobre la era de contribuciones asistidas por IA con un modelo interpretable.
- [ ] Redactar problema, pregunta de investigación y criterio de éxito medible (sección I).
- [ ] Montar todo en la plantilla IEEE: 3–4 páginas con ecuación, conteos (diagrama tipo PRISMA) y matriz.
- [ ] Incluir una línea: datos públicos del repositorio del kernel, sin solicitud de aprobación.

**Domingo 8 · cierre**

- [ ] Revisar cifras, referencias y que la matriz cumpla los mínimos.
- [ ] Subir el PDF (un solo envío) antes de las 11:59 p.m.; apuntar la hora de envío.

## Entrega 2 · dom 15 nov

El dataset y su exploración son el trabajo pesado de la semana; la Metodología en IEEE se escribe sobre lo que ya corrió. Si algo falla, el domingo 15 se decide si se sigue con el kernel o se pasa al plan B.

**Lun 9 – mié 11 · tabla de commits**

- [ ] Extraer de cada commit solo lo conocido al momento de integrarlo: tamaño del diff, archivos y subsistemas tocados, hora y día, experiencia previa del autor, número de revisores y trailers (`Reviewed-by`, `Tested-by`, `Cc: stable`).
- [ ] Etiqueta: citado por un `Fixes:` posterior en ≤90 días, usando la distancia en días de `bfc_bic.csv`. Quitar los commits con menos de 90 días de observación.
- [ ] Normalizar la etiqueta `Assisted-by` (el formato varía: agente, modelo, herramientas) a una variable binaria y al nombre del agente.
- [ ] Rellenar los años 2024–2026 que Zenodo no cubre (termina en nov 2023) con la minería del clon completo.

**Jue 12 · exploración**

- [ ] Notebook ejecutado: tasa de positivos por año y por subsistema, porcentaje de commits con `Assisted-by` por mes, distribución de cada variable, correlaciones entre entradas, faltantes por variable y balance de clases.
- [ ] Mostrar la deriva entre años (es lo que justifica la pregunta) y el sesgo por censura de las etiquetas recientes.

**Vie 13 – sáb 14 · documento**

- [ ] Ficha del dataset: origen, fechas, tamaño, variables, etiqueta, licencia, limitaciones (ruido de `Fixes:`, cerca de 81 % de fiabilidad en la muestra de 383 casos).
- [ ] Verificación D1–D7: **ya con la definición del curso (tabla abajo)**. Cada criterio se verifica con un número medido, no a ojo.
- [ ] Tabla de modelos con rol y justificación (el curso exige mínimo tres: trivial, clásico y propuesto; la variante suma en la rúbrica):

| Modelo | Rol | Por qué |
| --- | --- | --- |
| Clase mayoritaria (siempre "no riesgoso") | Referencia trivial | Fija el piso: un modelo que no la supera no aporta |
| Regresión logística | Referencia clásica | Base simple y estable que cualquiera reproduce |
| Gradient boosting | Referencia clásica fuerte | Mejor desempeño típico en datos tabulares, pero opaco |
| Clasificador difuso-evolutivo (≤15 reglas) | Propuesto | Reglas legibles; la pregunta es si pierde poco y se degrada menos |
| Mismo clasificador sin optimización evolutiva | Variante (ablación) | Atribuye la mejora a la evolución y no solo a la forma del modelo |

- [ ] Borrador de la Metodología en IEEE.

**D1–D7 aplicado a este dataset** (criterios del curso; la columna de la derecha es lo que hay que medir y anotar)

| Criterio | Condición mínima del curso | Cómo se verifica con los commits |
| --- | --- | --- |
| D1 Tamaño | ≥300 observaciones para modelos difusos | Contar commits tras los filtros y anotar la cifra real |
| D2 Variable objetivo | Definida, medible; reportar balance de clases | Citado por un `Fixes:` en ≤90 días; porcentaje de positivos por año |
| D3 Calidad | Faltantes en el objetivo ≤10 %; duplicados identificados | Objetivo definido para todo commit con ≥90 días de observación; detectar el mismo parche en mainline y en ramas stable |
| D4 Estructura | Índice ordenado y muestreo regular; identificador de grupo | Índice = fecha del commit (muestreo irregular, se documenta); grupo = autor anonimizado y subsistema |
| D5 Disponibilidad | Toda entrada disponible al usar el modelo | El modelo se usa al integrar el commit: solo variables conocidas en ese momento, nada posterior |
| D6 Licencia y ética | Uso académico permitido; datos personales anonimizados | Confirmar la licencia del dataset de Zenodo y del repositorio; reemplazar nombres y correos por identificadores |
| D7 Documentación | Origen, fecha, unidades y significado de cada variable | Ficha tipo Datasheets for Datasets |

**Dom 15 · cierre**

- [ ] Compuerta de decisión (ver Resumen).
- [ ] Revisar que el notebook corra de principio a fin y subir todo.

## Entrega 3 · dom 22 nov

Esta semana se congela todo lo que se puede comparar: el pipeline, las dos referencias y las reglas del juego (métricas y prueba). El test de 2026 se mina y se guarda, pero no se toca.

**Mar 17 – mié 18 · pipeline y referencias (el lunes 16 es festivo)**

- [ ] Un solo script o notebook que va de los datos crudos a las métricas, ejecutado de principio a fin, con semilla fija.
- [ ] División temporal: entrenamiento con el pasado, validación con ventanas móviles, nunca mezcla aleatoria.
- [ ] Entrenar y validar las referencias con el mismo pipeline y la misma partición: la trivial (clase mayoritaria) y las clásicas (regresión logística y gradient boosting). Reportar AUC-PR, MCC y AUC-ROC por ventana, y la caída entre ventanas.
- [ ] Comprobar que ninguna variable usa información posterior al commit y que escalado, imputación, selección de variables y balanceo se ajustan solo con el entrenamiento (todo dentro de un Pipeline).

**Jue 19 · reglas del juego**

- [ ] Declarar la métrica principal (AUC-PR), las secundarias (MCC, AUC-ROC, sensibilidad y especificidad) y las pruebas antes de ver resultados: McNemar sobre las mismas observaciones de prueba e intervalos de confianza del 95 % por bootstrap. Si se comparan varios modelos sobre varias ventanas, Friedman con Nemenyi. Un Wilcoxon con 5 semillas no sirve: su p mínimo es 0,0625.
- [ ] Declarar el criterio de éxito final, con números.
- [ ] Espacio de hiperparámetros del modelo propuesto:

| Hiperparámetro | Qué controla |
| --- | --- |
| Número de reglas (≤15) | Interpretabilidad frente a desempeño |
| Funciones de pertenencia | Tipo, forma y número de conjuntos por variable; método de inferencia y defuzzificación |
| Población y generaciones | Costo de la búsqueda evolutiva |
| Tasa de mutación y cruce | Exploración frente a convergencia |
| Pesos de los objetivos | Equilibrio entre AUC-PR y número de reglas |

**Vie 20 – sáb 21 · minería del test y Metodología**

- [ ] Minar los commits de 2026 con ≥90 días de observación, guardar el archivo y su suma de verificación. No evaluar nada con él.
- [ ] Escribir la Metodología completa en IEEE: datos, etiqueta, variables, división, modelos, métricas, prueba y amenazas a la validez.

**Dom 22 · cierre**

- [ ] Verificar que el código corre limpio desde cero en una sesión limpia de Colab, partiendo de la tabla procesada y subir.

## Entrega 4 · dom 29 nov

Se entrena y se ajusta el modelo difuso solo con validación, y se termina la semana con una configuración congelada. **No se evalúa el test de 2026.**

**Lun 23 – mié 25 · experimentos**

- [ ] Registro de experimentos en CSV: una fila por corrida con semilla, hiperparámetros, número de reglas, métricas de validación por ventana y tiempo.
- [ ] Prueba de humo (pocos datos, pocas generaciones) y luego barrido del espacio de hiperparámetros declarado en la Entrega 3 (búsqueda aleatoria o evolutiva, con un presupuesto de corridas fijado de antemano).
- [ ] Entrenar las referencias bajo las mismas ventanas y correr la ablación (el clasificador sin optimización evolutiva): la rúbrica pide ablación o variante para el máximo en modelado. Antes de lanzar el barrido, calcular el presupuesto (configuraciones × ventanas × semillas × minutos por corrida) y reducir la rejilla si pasa de unas 3 horas.

**Jue 26 · sensibilidad**

- [ ] Tabla o mapa de sensibilidad: al menos 2 hiperparámetros en 3 niveles cada uno (por ejemplo número de reglas × tamaño de población), con el AUC-PR de validación como media ± desviación.
- [ ] Elegir la configuración final por validación, con una regla de desempate escrita antes (menos reglas gana si la diferencia es menor al error estándar).

**Vie 27 · cinco semillas y congelación**

- [ ] Validación con 5 semillas de la configuración elegida y de las dos referencias; media y desviación por métrica.
- [ ] Aplicar la prueba de significancia declarada en la Entrega 3.
- [ ] Congelar la configuración final en un archivo con fecha y hash del commit del código.

**Sáb 28 – dom 29 · Sección IV**

- [ ] Escribir la Sección IV (Experimentación) en IEEE: hardware y software, espacios de hiperparámetros, método de búsqueda, semillas, criterios de parada y presupuesto de cómputo. Los resultados van en la V, después de la prueba.
- [ ] Subir el registro CSV, la tabla de sensibilidad, la validación con 5 semillas, la configuración congelada y la Sección IV.

## Entrega 5 · jue 3 dic

El test de 2026 se toca una sola vez, el lunes, y el resto de la semana es escribir. No hay prórroga y la sustentación es el 4 de diciembre, así que el miércoles 2 queda de colchón. La entrega final vale 40 % y la sustentación 20 %, individual: tienes que poder explicar cualquier parte.

**Lun 30 nov · prueba única**

- [ ] Verificar la suma de verificación del archivo de test y que la configuración sigue congelada.
- [ ] Evaluar una sola vez todos los modelos en el test: tabla con AUC-PR, MCC, AUC-ROC y caída frente a validación, cada una con intervalo de confianza del 95 % por bootstrap o media ± desviación, más tiempo de entrenamiento, tiempo de inferencia y número de parámetros. McNemar entre el modelo propuesto y cada referencia, con estadístico y valor p.
- [ ] Análisis descriptivo del subgrupo con `Assisted-by` frente al resto (hay pocos positivos asistidos, así que se reporta sin pruebas fuertes). Aparte: análisis de errores (dónde falla), interpretabilidad (reglas activadas y variables que usan), comparación con los valores de la matriz del estado del arte aclarando si el protocolo es comparable, y robustez ante un período distinto.
- [ ] Si el modelo difuso no alcanza el criterio, reportarlo tal cual y discutir por qué. No se vuelve a ajustar con el test.

**Mar 1 dic · artículo (8–10 páginas IEEE)**

- [ ] Unir las secciones ya escritas (I–II de la Entrega 1, III de la 3, IV de la 4) y añadir V Resultados, VI Discusión (con amenazas a la validez y el plan de monitoreo y reentrenamiento de la etapa 6 de CRISP-ML(Q)) y VII Conclusiones. Son 8 a 10 páginas sin contar referencias ni anexos, con título, resumen y palabras clave también en inglés y al menos 15 referencias, todas citadas en el texto.
- [ ] Figuras mínimas: curva de aprendizaje, matriz de confusión, sensibilidad y comparación de modelos con barras de error; además la caída entre ventanas y las reglas aprendidas. Todas numeradas, con título y citadas en el texto.
- [ ] Revisar contra la rúbrica adjunta, punto por punto.

**Mié 2 dic · paquete y ensayo**

- [ ] Repositorio con la estructura sugerida (README, datos, cuadernos, src, resultados, artículo). README con versiones, semillas y pasos; cuaderno de Colab con las salidas visibles que reproduce la tabla principal en una sesión limpia; registro\_experimentos.csv; y anexo de reproducibilidad en el artículo.
- [ ] Presentación de 8 a 10 diapositivas y ensayo cronometrado: 12 minutos (problema y brecha 2, datos y metodología 4, resultados con prueba de significancia 4, limitaciones y conclusión 2) más 5 de preguntas.

**Jue 3 dic · entrega**

- [ ] Subir a Classroom, antes de las 23:59 y en un solo envío: PDF del artículo, código ejecutado con README, registro de experimentos y presentación. Confirmar que todo abre.

**Vie 4 dic · sustentación**

- [ ] Llevar la presentación y una respuesta preparada para: por qué reglas difusas, qué pasa con la etiqueta ruidosa, qué diría el resultado si el modelo no gana.

## Riesgos y plan B

Los dos riesgos que pueden tumbar el plan son el tamaño de la minería y los pocos positivos asistidos por IA; el resto se maneja con decisiones ya tomadas.

| Riesgo | Qué pasa | Qué hacer |
| --- | --- | --- |
| Etiquetas con censura por la derecha | Los commits recientes parecen limpios solo porque aún no los cita un `Fixes:` | Solo commits con ≥90 días de observación; declararlo en la Metodología |
| Etiqueta `Assisted-by` inconsistente | Se pierden casos por variaciones de formato | Normalizar con expresión regular y revisar a mano una muestra |
| Ruido en `Fixes:` | Cerca de 81 % de fiabilidad en una muestra de 383 casos | Reportarlo como amenaza a la validez; no prometer más precisión que la etiqueta |
| Pocos positivos con IA | El análisis del subgrupo no alcanza para concluir | Dejarlo descriptivo; la pregunta central es la deriva temporal, no un efecto causal de la IA |
| Clon y minería lentos | Historial completo del kernel: mucho disco, mucho tiempo | Lanzar el clon el jueves 5; si el viernes 6 no hay avance, pasar al plan B |
| Hueco de datos 2024–2025 | El dataset de Zenodo termina en nov 2023 | Minar esos años del clon; si no alcanza, ventana de validación más corta y decirlo |
| El modelo difuso rinde menos | No alcanza 95 % del mejor de referencia | Reportarlo honesto y relajar el criterio en la discusión, sin tocar el test; la contribución queda en la comparación de robustez |

**Referencias que no existen.** La lista de candidatos que reuní se vio en su mayoría solo por título. Abre cada una y confirma autor, año y medio de publicación antes de citarla: el curso califica como insuficientes las referencias inexistentes.

**Plan B · AIDev.** Si el kernel no es viable en la compuerta del 6 o del 15 de noviembre, el mismo pipeline se aplica a AIDev (pull requests de agentes): misma pregunta de robustez, mismas tres familias de modelos, mismo calendario. El costo es perder el ángulo del kernel y enfrentar un trabajo previo más cercano, así que la brecha se sostiene en la validación temporal y las reglas interpretables.
