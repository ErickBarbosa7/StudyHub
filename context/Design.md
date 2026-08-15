# 🎨 Design System: Organic Minimal

Este proyecto utiliza un estilo de diseño denominado **Organic Minimal**. La interfaz debe transmitir calma, orden y una sensación natural. Las interfaces deben priorizar la limpieza visual, la legibilidad y evitar la sobrecarga de información.

## 1. Paleta de Colores
Evitar los colores primarios saturados y el blanco/negro puros. Utilizar la siguiente paleta:

*   **Fondo Principal (Cream):** `#FAF8F5` o `#F6F4EB`. Usar para el fondo general de las pantallas (Scaffold) y tarjetas amplias.
*   **Acento Principal (Dark Green):** `#2C5234` o `#1E3F20`. Usar para botones primarios (ElevatedButton), íconos destacados y elementos interactivos clave.
*   **Acento Secundario (Soft Olive/Green):** `#9DB589` o `#C5D8B6`. Usar para estados secundarios, chips, fondos de íconos, indicadores (como el temporizador) y detalles sutiles.
*   **Texto Principal (Off-Black):** `#1A1C18` o `#222422`. Nunca usar negro puro (`#000000`). Esto reduce la fatiga visual.
*   **Texto Secundario:** Un gris con matices verdes/cálidos, como `#5C605A`.

El verde sigue siendo el color global. Se añaden acentos por módulo para dar variedad sin romper el Organic Minimal:

*   **Tareas (ámbar/miel):** acento `#D9A441`, fondo suave `#F5E2C0`. Usar para el encabezado del módulo, chips de estado "En progreso", checkboxes vacíos y detalles. Mantener verde para estados "Completado".
*   **Chat (teal/azul):** acento `#4E7C8B`, fondo suave `#DCEAEE`. Usar para el encabezado del módulo, burbujas de otros usuarios, nombre del remitente, borde focal y estados vacíos. Las burbujas propias siguen en `Dark Green`.

## 2. Tipografía
*   **Fuente Única:** `Sora` (Sora Variable, Google Fonts; pesos 300–800).
*   Toda la aplicación debe utilizar esta fuente para mantener un aspecto limpio y moderno.
*   Asegurar un buen contraste y legibilidad, utilizando pesos ligeros (`w400`) para cuerpos de texto y medios (`w600`) para títulos.

## 3. Elementos de Interfaz (UI)
*   **Bordes Redondeados:** Todos los elementos interactivos (botones, tarjetas, modales, campos de texto) deben tener bordes redondeados pronunciados. En Flutter, usar `BorderRadius.circular(16)` o `BorderRadius.circular(24)`.
*   **Sombras Muy Suaves:** Las tarjetas y elementos elevados deben flotar ligeramente, sin bordes duros. Usar sombras amplias, con alta difuminación (blur) y opacidad muy baja (ej. color negro al 5% u 8%).
*   **Detalles Orgánicos:** Incorporar íconos de líneas suaves, curvas amables y evitar líneas rectas cortantes o separadores rígidos (usar espacios en lugar de líneas divisorias cuando sea posible).

### 3.1. Estilos de Botones
Estilos de referencia implementados en la pantalla de inicio (`home_screen.dart`). Aplica estos patrones para mantener consistencia en toda la app.

*   **Botón Primario (C.T.A. principal):**
    *   `ElevatedButton.icon` con icono `rounded` (ej. `Icons.add_rounded`) que acompañe la acción.
    *   Fondo `Dark Green` (`#2C5234`), texto en `Cream` (`#FAF8F5`).
    *   `BorderRadius.circular(24)`.
    *   Altura de `56` (`height: 56`) para un objetivo táctil amplio y cómodo.
    *   Ancho completo (`width: double.infinity`) cuando la acción es la principal de la pantalla.
    *   Ejemplo:
      ```dart
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear sala de estudio'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      )
      ```

*   **Botón Secundario / Textual (acciones ligeras, ej. ayuda):**
    *   `TextButton.icon` con icono `rounded` pequeño de `size: 20` (ej. `Icons.help_outline_rounded`).
    *   Texto en `Texto Secundario` (gris cálido `#5C605A`) para que el C.T.A. principal conserve el protagonismo visual.
    *   Sin borde ni relleno; se apoya en el espaciado para respirar.
    *   Ejemplo:
      ```dart
      TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.help_outline_rounded, size: 20),
        label: const Text('¿Cómo funciona?'),
        style: TextButton.styleFrom(
          foregroundColor: kColorTextSecondary,
        ),
      )
      ```

*   **Jerarquía:** Un solo botón primario por pantalla. Las acciones secundarias van detrás como `TextButton` en texto secundario.

### 3.2. Separación de Interacciones (Quick vs. Deep Actions)
Estas reglas son globales y aplican a cualquier pantalla, widget o componente:

*   **Nunca** agrupes acciones inmediatas con aperturas de menús/modales en el mismo `GestureDetector`.
*   **Acción rápida (Quick):** Se ejecuta al instante al tocar un objetivo táctil específico (checkbox, "like", silenciar, toggle). El área táctil debe ser de mínimo `44x44` px.
*   **Acción profunda (Deep):** Apertura de detalles, modales o menús contextuales. Se asigna al resto del contenedor (cuerpo de la tarjeta, texto o chip de estado), nunca al target táctil de la acción rápida.
*   Ejemplo: en una tarea, el círculo/checkbox = acción rápida (marcar/desmarcar); el chip de estado o el texto = apertura del menú de estados.

### 3.3. Prohibición de Sombras Anidadas (Cero Ruido Visual)
*   **Prohibido** usar `BoxShadow` dentro de superficies que ya están elevadas (modales, bottom sheets, tarjetas principales).
*   En elementos seleccionables dentro de un modal (opciones de menú, selección de estado): cuando **no** está seleccionado, usar contenedor transparente con borde sutil `Border.all(color: kColorOlive, ...)` con opacidad (sin sombra).
*   Cuando **sí** está seleccionado, usar relleno sólido `kColorDarkGreen` sin bordes ni sombras.

### 3.4. Píldoras de Estado (Status Pills)
Cualquier indicador de estado de la app (estado de tarea, usuario conectado, contadores) respeta este patrón de contraste sobre fondo Crema o Blanco:
a
*   **Activo / En Progreso:** Fondo `kColorOlive` con `alpha: 0.3`, texto/ícono `kColorDarkGreen`.
*   **Completado / Éxito:** Fondo `kColorSoftGreen` con `alpha: 0.2`, texto/ícono `kColorDarkGreen` con `alpha: 0.6`.
*   **Pendiente / Inactivo:** Fondo transparente, texto/ícono `kColorTextSecondary`.

## 4. Layout y Espaciado
*   **Mucho Espacio en Blanco (White Space):** El diseño debe "respirar". Aplicar márgenes generosos (`padding` de `24.0` o `32.0`) entre los componentes. 
*   Evitar agrupar demasiados elementos en la misma sección. Si algo se ve apretado, aumentar el padding.

### 4.1. Contornos y Geometría Orgánica (Global)
*   Radios de borde muy pronunciados en todo el sistema: `BorderRadius.circular(24)` o `BorderRadius.circular(32)`.
*   Botones primarios: altura fija de `56` y ancho completo cuando son el C.T.A. principal de la pantalla.
*   Íconos internos de botones: tamaño proporcional (`size: 24` o `28`).
*   Objetivos táctiles de acciones rápidas: mínimo `44x44` px (regla 3.2).