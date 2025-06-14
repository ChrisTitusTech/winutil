# ¿Cómo Contribuir?

## Pruebas

*   ¡Prueba los últimos cambios en WinUtil ejecutando la pre-release y reportando los problemas que encuentres para ayudarnos a mejorar continuamente WinUtil!

#### **Ejecutar la última pre-release**
   ```ps1
   irm https://christitus.com/windev | iex
   ```

!!! error "Ten en cuenta"

     Esta es una pre-release y debe ser tratada como tal. Existe para que los desarrolladores prueben la utilidad y reporten o corrijan errores antes de que se agreguen a la versión estable. ¡No la uses en producción!

## Incidencias (Issues)

*   Si encuentras algún desafío o problema con el script, te pido amablemente que los envíes a través de la pestaña "Issues" en el repositorio de GitHub. Al completar la plantilla proporcionada, puedes ofrecer detalles específicos sobre el problema, permitiéndome (y a otros en la comunidad) abordar rápidamente cualquier error o considerar solicitudes de características.

## Contribuir con Código

*   Las pull requests ahora se manejan directamente en la rama **MAIN**. Esto se hizo ya que ahora podemos seleccionar lanzamientos específicos para ejecutar a través de los releases en GitHub.

*   Si estás realizando cambios en el código, puedes enviar una PR a la rama `main`, pero soy muy selectivo con estas.

!!! advertencia "Importante"

     No uses un formateador de código, no hagas cantidades masivas de cambios de línea, ni realices múltiples cambios de características. ¡CADA CAMBIO DE CARACTERÍSTICA DEBE SER SU PROPIA PULL REQUEST!

*   Al crear pull requests, es esencial documentar minuciosamente todos los cambios realizados. Esto incluye, pero no se limita a, documentar cualquier adición hecha a la sección de `tweaks` y el correspondiente `undo tweak` (deshacer ajuste), para que los usuarios puedan eliminar los ajustes recién agregados si es necesario, y se requiere documentación completa para todos los cambios de código. Documenta tus cambios y explica brevemente por qué los hiciste en la Descripción de tu Pull Request. El incumplimiento de este formato puede resultar en la denegación de la pull request. Además, cualquier código que carezca de documentación suficiente también puede ser denegado.

*   Siguiendo estas directrices, podemos mantener un alto estándar de calidad y asegurar que la base de código permanezca organizada y bien documentada.

!!! nota "Nota"

     Al crear una función, por favor incluye "WPF" o "WinUtil" en el nombre del archivo para que pueda cargarse en el runspace.

## Guía Detallada

*   Esta es una guía para principiantes. Si sigues teniendo problemas, consulta la siguiente documentación oficial de GitHub:
    *   [Confirmar (Commit) a través de la WEB](https://docs.github.com/es/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/about-commits)
    *   [Confirmar (Commit) a través de GitHub Desktop](https://docs.github.com/es/desktop/making-changes-in-a-branch/committing-and-reviewing-changes-to-your-project-in-github-desktop#about-commits)
    *   [Crear una Pull Request](https://docs.github.com/es/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)

### Resumen

``` mermaid
%%{init: {"flowchart": {"curve": "cardinal"}} }%%
graph TD
  A[Hacer Fork del Proyecto] --> B[Clonar Repositorio];
  B --> C[Crear Nueva Rama];
  C --> D[Realizar Cambios];
  D --> G[Probar Cambios];
  G --> H{¿Pruebas Superadas?};
  H -->|Sí| E[Confirmar Cambios (Commit)];
  H -->|No| J[Corregir Problemas];
  J --> G;
  E --> F[Empujar Rama (Push)];
  F --> K[Crear Pull Request];
  K --> L[Completar plantilla de PR];
  classDef default stroke:#333,stroke-width:4px,font-size:12pt;
```
!!! nota "Información"

     Este es un diagrama para guiarte a través del proceso. Puede variar dependiendo del tipo de cambio que estés realizando.

### Hacer Fork del Repositorio
*   Haz fork del Repositorio WinUtil [aquí](https://github.com/ChrisTitusTech/winutil) para crear una copia que estará disponible en tu lista de repositorios.

![Fork Image](assets/Fork-Button-Dark.png#only-dark#gh-dark-mode-only)

![Fork Image](assets/Fork-Button-Light.png#only-light#gh-light-mode-only)

### Clonar el Fork
!!! consejo "Consejo"

     Aunque puedes realizar tus cambios directamente a través de la Web, recomendamos clonar el repositorio en tu dispositivo usando la aplicación GitHub Desktop (disponible en WinUtil) para probar tu fork fácilmente.

*   Instala GitHub Desktop si aún no está instalado.
*   Inicia sesión usando la misma cuenta de GitHub que usaste para hacer fork de WinUtil.
*   Elige el fork en "Tus Repositorios" y presiona "clonar {nombre-del-repositorio}"
*   Crea una nueva rama y nómbrala de forma que se relacione con tus cambios.

*   Ahora puedes modificar WinUtil a tu gusto usando tu editor de texto preferido.

### Probando tus cambios

*   Para probar si tus cambios funcionan como se espera, ejecuta los siguientes comandos en una terminal de PowerShell como administrador:

*   Cambia el directorio donde estás ejecutando los comandos al proyecto del fork.
*   `cd {ruta-a-la-carpeta-con-compile.ps1}`
*   Ejecuta el siguiente comando para compilar y ejecutar WinUtil:
*   `.\Compile.ps1 -run`

![Compile](assets/Compile.png)

*   Después de ver que tus cambios funcionan correctamente, siéntete libre de confirmar (commit) los cambios al repositorio y hacer una PR. Para obtener ayuda sobre eso, sigue la documentación a continuación.

### Confirmando (Committing) los cambios
*   Antes de confirmar tus cambios, por favor descarta los cambios realizados en el archivo `winutil.ps1`, como se muestra a continuación:

![Push Commit Image](assets/Discard-GHD.png)

*   Ahora, confirma (commit) tus cambios una vez que estés satisfecho con el resultado.

![Commit Image](assets/Commit-GHD.png)

*   Empuja (push) los cambios para subirlos a tu fork en github.com.

![Push Commit Image](assets/Push-Commit.png)

### Haciendo una PR
*   Para hacer una PR en tu repositorio bajo una nueva rama enlazando a la rama principal, aparecerá un botón que dirá "Preview and Create pull request". Haz clic en ese botón y completa toda la información que se proporciona en la plantilla. Una vez que toda la información esté completada correctamente, revisa tu PR para asegurarte de que no haya un archivo WinUtil.ps1 adjunto a la PR. Una vez que todo esté bien, crea la PR y espera a que Chris (el mantenedor) acepte o rechace tu PR. Una vez que sea aceptada por Chris, podrás ver tus cambios en la compilación "/windev".
*   Si no ves tu característica en la compilación principal "/win", está bien. Todos los cambios nuevos van a la compilación /windev para asegurarse de que todo funcione correctamente antes de hacerse completamente público.
*   ¡Felicidades! Acabas de enviar tu primera PR. Muchas gracias por contribuir a WinUtil.
