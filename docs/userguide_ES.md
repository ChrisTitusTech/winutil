# Guía Detallada

## Instalar
---

=== "Instalación y Actualizaciones"

    *   Elige los programas que deseas instalar o actualizar.
        *   Para los programas que no están instalados actualmente, esta acción los instalará.
        *   Para los programas ya instalados, esta acción los actualizará a la última versión.
    *   Haz clic en el botón `Instalar/Actualizar Seleccionados` para iniciar el proceso de instalación o actualización.

=== "Actualizar Todo"

    *   Simplemente presiona el botón `Actualizar Todo`.
    *   Esto actualizará todos los programas aplicables que estén instalados sin necesidad de selección individual.

=== "Desinstalar"

    *   Selecciona los programas que deseas desinstalar.
    *   Haz clic en el botón `Desinstalar Seleccionados` para eliminar los programas seleccionados.

=== "Obtener Instalados"

    *   Haz clic en el botón `Obtener Instalados`.
    *   Esto escaneará y seleccionará todos los programas instalados en WinUtil que WinGet soporta.

=== "Limpiar Selección"
    *   Haz clic en el botón `Limpiar Selección`.
    *   Esto deseleccionará todos los programas marcados.

=== "Preferir Chocolatey"
    *   Marca la casilla `Preferir Chocolatey`.
    *   Por defecto, Winutil usará winget para instalar/actualizar/eliminar paquetes y recurrirá a Chocolatey como alternativa. Esta opción invierte la preferencia.
    *   Esta preferencia se usará para todos los botones en la página de Instalación y persistirá entre reinicios de Winutil.

![Install Image](assets/Install-Tab-Dark.png#only-dark#gh-dark-mode-only)
![Install Image](assets/Install-Tab-Light.png#only-light#gh-light-mode-only)

!!! consejo "Consejo"

     Si tienes problemas para encontrar una aplicación, presiona `ctrl + f` y busca su nombre. Las aplicaciones se filtrarán según tu entrada.

## Ajustes (Tweaks)
---

![Tweaks Image](assets/Tweaks-Tab-Dark.png#only-dark#gh-dark-mode-only)
![Tweaks Image](assets/Tweaks-Tab-Light.png#only-light#gh-light-mode-only)

### Ejecutar Ajustes
*   **Abrir Pestaña de Ajustes**: Navega a la pestaña 'Ajustes' en la aplicación.
*   **Seleccionar Ajustes**: Elige los ajustes que quieres aplicar. Puedes usar los preajustes disponibles en la parte superior para mayor comodidad.
*   **Ejecutar Ajustes**: Después de seleccionar los ajustes deseados, haz clic en el botón 'Ejecutar Ajustes' en la parte inferior de la pantalla.

### Deshacer Ajustes
*   **Abrir Pestaña de Ajustes**: Ve a la pestaña 'Ajustes' ubicada junto a 'Instalar'.
*   **Seleccionar Ajustes a Eliminar**: Elige los ajustes que quieres deshabilitar o eliminar.
*   **Deshacer Ajustes**: Haz clic en el botón 'Deshacer Ajustes Seleccionados' en la parte inferior de la pantalla para aplicar los cambios.

### Ajustes Esenciales
Los Ajustes Esenciales son modificaciones y optimizaciones que generalmente son seguras para la mayoría de los usuarios. Estos ajustes están diseñados para mejorar el rendimiento del sistema, la privacidad y reducir actividades innecesarias del sistema. Se consideran de bajo riesgo y se recomiendan para usuarios que desean asegurar que su sistema funcione de manera fluida y eficiente sin profundizar demasiado en configuraciones complejas. El objetivo de los Ajustes Esenciales es proporcionar mejoras notables con un riesgo mínimo, haciéndolos adecuados para una amplia gama de usuarios, incluidos aquellos que pueden no tener conocimientos técnicos avanzados.

### Ajustes Avanzados - PRECAUCIÓN
Los Ajustes Avanzados están destinados a usuarios experimentados que tienen un sólido entendimiento de su sistema y las posibles implicaciones de realizar cambios a bajo nivel. Estos ajustes implican alteraciones más significativas en el sistema operativo y pueden proporcionar una personalización sustancial. Sin embargo, también conllevan un mayor riesgo de causar inestabilidad del sistema o efectos secundarios no deseados si no se implementan correctamente. Los usuarios que elijan aplicar Ajustes Avanzados deben proceder con precaución, asegurándose de tener conocimientos adecuados y copias de seguridad para recuperarse si algo sale mal. Estos ajustes no se recomiendan para usuarios novatos o aquellos que no estén familiarizados con el funcionamiento interno de su sistema operativo.

### O&O Shutup

[O&O ShutUp10++](https://www.oo-software.com/en/shutup10) puede iniciarse desde WinUtil con solo un clic. Es una herramienta de privacidad gratuita para Windows que permite a los usuarios gestionar fácilmente su configuración de privacidad. Deshabilita la telemetría, controla las actualizaciones y gestiona los permisos de las aplicaciones para mejorar la seguridad y la privacidad. La herramienta ofrece configuraciones recomendadas para una privacidad óptima con solo unos pocos clics.

<iframe width="640" height="360" src="https://www.youtube.com/embed/3HvNr8eMcv0" title="O&O ShutUp10++: Para Windows 10 y 11, con Modo Oscuro" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

### DNS

La utilidad proporciona una función de selección de DNS conveniente, permitiendo a los usuarios elegir entre varios proveedores de DNS tanto para IPv4 como para IPv6. Esto permite a los usuarios optimizar su conexión a internet para velocidad, seguridad y privacidad según sus necesidades específicas. Aquí están las opciones disponibles:

*   **Predeterminado**: Utiliza la configuración DNS predeterminada configurada por tu ISP o red.
*   **DHCP**: Adquiere automáticamente la configuración DNS del servidor DHCP.
*   [**Google**](https://developers.google.com/speed/public-dns?hl=es): Un servicio DNS confiable y rápido proporcionado por Google.
*   [**Cloudflare**](https://developers.cloudflare.com/1.1.1.1/): Conocido por su velocidad y privacidad, Cloudflare DNS es una opción popular para mejorar el rendimiento de internet.
*   [**Cloudflare_Malware**](https://developers.cloudflare.com/1.1.1.1/setup/#:~:text=Use%20the%20following%20DNS%20resolvers%20to%20block%20malicious%20content%3A): Proporciona protección adicional bloqueando sitios de malware.
*   [**Cloudflare_Malware_Adult**](https://developers.cloudflare.com/1.1.1.1/setup/#:~:text=Use%20the%20following%20DNS%20resolvers%20to%20block%20malware%20and%20adult%20content%3A): Bloquea tanto malware como contenido para adultos, ofreciendo un filtrado más completo.
*   [**Open_DNS**](https://www.opendns.com/setupguide/#familyshield): Ofrece filtrado personalizable y características de seguridad mejoradas.
*   [**Quad9**](https://quad9.net/): Se centra en la seguridad bloqueando dominios maliciosos conocidos.
*   [**AdGuard_Ads_Trackers**](https://adguard-dns.io/es/welcome.html) AdGuard DNS bloqueará anuncios, rastreadores o cualquier otra solicitud de DNS. Visita el sitio web e inicia sesión para acceder a un panel, estadísticas y personalizar tu experiencia en la configuración del servidor.
*   [**AdGuard_Ads_Trackers_Malware_Adult**](https://adguard-dns.io/es/welcome.html) AdGuard DNS bloqueará anuncios, rastreadores, contenido para adultos y habilitará la Búsqueda Segura y el Modo Seguro, cuando sea posible.
*   [**dns0.eu_Open**](https://www.dns0.eu/) El DNS público europeo que hace tu Internet más seguro. Ofrece filtrado de propósito general para bloquear malware, phishing y dominios de rastreo para una privacidad y seguridad mejoradas.
*   [**dns0.eu_ZERO**](https://www.dns0.eu/zero) Proporciona seguridad avanzada con filtros robustos para entornos altamente sensibles, bloqueando dominios de alto riesgo utilizando inteligencia de amenazas y heurísticas sofisticadas como Dominios Recién Registrados (NRD) y Algoritmos de Generación de Dominios (DGA).
*   [**dns0.eu_KIDS**](https://www.dns0.eu/kids) Un DNS seguro para niños que bloquea contenido para adultos, resultados de búsqueda explícitos, videos para adultos, sitios de citas, piratería y anuncios, creando una experiencia de internet segura para niños en cualquier dispositivo o red.

### Personalizar Preferencias

La sección Personalizar Preferencias permite a los usuarios personalizar su experiencia en Windows activando o desactivando diversas características visuales y funcionales. Estas preferencias están diseñadas para mejorar la usabilidad y adaptar el sistema a las necesidades y preferencias específicas del usuario.

### Planes de Rendimiento

La sección Planes de Rendimiento permite a los usuarios gestionar el Perfil de Máximo Rendimiento en su sistema. Esta característica está diseñada para optimizar el sistema para un rendimiento máximo.

#### Añadir y activar el Perfil de Máximo Rendimiento:
*   Habilita y activa el Perfil de Máximo Rendimiento para mejorar el rendimiento del sistema minimizando la latencia y aumentando la eficiencia.
#### Eliminar el Perfil de Máximo Rendimiento:
*   Desactiva el Perfil de Máximo Rendimiento, cambiando el sistema al Perfil Equilibrado.

### Accesos Directos

La utilidad incluye una función para crear fácilmente un acceso directo en el escritorio, proporcionando un acceso rápido al script.

## Configuración (Config)
---

### Características
*   Instala las **Características de Windows** más utilizadas marcando la casilla y haciendo clic en "Instalar Características" para instalarlas.

*   Todos los .Net Frameworks (2, 3, 4)
*   Virtualización HyperV
*   Medios Heredados (WMP, DirectPlay)
*   NFS - Sistema de Archivos en Red
*   Habilitar Sugerencias Web en el Cuadro de Búsqueda en el Registro (requiere reinicio del explorador)
*   Deshabilitar Sugerencias Web en el Cuadro de Búsqueda en el Registro (requiere reinicio del explorador)
*   Habilitar Tarea de Copia de Seguridad Diaria del Registro a las 12:30am
*   Habilitar Recuperación de Arranque Heredada F8
*   Deshabilitar Recuperación de Arranque Heredada F8
*   Subsistema de Windows para Linux
*   Windows Sandbox

### Arreglos
*   Arreglos rápidos para tu sistema si estás teniendo problemas.

*   Configurar Inicio de Sesión Automático
*   Restablecer Windows Update
*   Restablecer Red
*   Escaneo de Corrupción del Sistema
*   Reinstalar WinGet
*   Eliminar Adobe Creative Cloud

### Paneles Heredados de Windows

Abre paneles de Windows de la vieja escuela directamente desde WinUtil. Los siguientes Paneles están disponibles:

*   Panel de Control
*   Conexiones de Red
*   Panel de Energía
*   Región
*   Configuración de Sonido
*   Propiedades del Sistema
*   Cuentas de Usuario

### Acceso Remoto

Habilita el servidor OpenSSH en tu máquina Windows.

## Actualizaciones
---

La utilidad proporciona tres configuraciones distintas para gestionar las actualizaciones de Windows: Configuración Predeterminada (De Fábrica), Configuración de Seguridad (Recomendada) y Deshabilitar TODAS las Actualizaciones (¡NO RECOMENDADO!). Cada configuración ofrece un enfoque diferente para manejar las actualizaciones, atendiendo a diversas necesidades y preferencias de los usuarios.

### Configuración Predeterminada (De Fábrica)
-   **Descripción**: Esta configuración conserva las configuraciones predeterminadas que vienen con Windows, asegurando que no se realicen modificaciones.
-   **Funcionalidad**: Eliminará cualquier configuración personalizada de Windows Update aplicada previamente.
-   **Nota**: Si los errores de actualización persisten, restablece todas las actualizaciones en la pestaña de configuración para restaurar todos los Servicios de Microsoft Update a su configuración predeterminada, reinstalándolos desde sus servidores.

### Configuración de Seguridad (Recomendada)
-   **Descripción**: Esta es la configuración recomendada para todas las computadoras.
-   **Calendario de Actualizaciones**:
    -   **Actualizaciones de Características**: Retrasa las actualizaciones de características por 2 años para evitar posibles errores e inestabilidad.
    -   **Actualizaciones de Seguridad**: Instala las actualizaciones de seguridad 4 días después de su lanzamiento para asegurar la protección del sistema contra fallas de seguridad urgentes.
-   **Justificación**:
    -   **Actualizaciones de Características**: A menudo introducen nuevas características y errores; retrasar estas actualizaciones minimiza el riesgo de interrupciones del sistema.
    -   **Actualizaciones de Seguridad**: Esenciales para parchear vulnerabilidades de seguridad críticas. Retrasarlas unos días permite la verificación de estabilidad y compatibilidad sin dejar el sistema expuesto durante períodos prolongados.

### Deshabilitar TODAS las Actualizaciones (¡NO RECOMENDADO!)
-   **Descripción**: Esta configuración deshabilita completamente todas las actualizaciones de Windows.
-   **Adecuación**: Puede ser apropiado para sistemas utilizados para fines específicos que no requieren navegación activa por internet.
-   **Advertencia**: Deshabilitar las actualizaciones aumenta significativamente el riesgo de que el sistema sea hackeado o infectado debido a la falta de parches de seguridad.
-   **Nota**: Se desaconseja encarecidamente utilizar esta configuración debido a los elevados riesgos de seguridad.

!!! error "Error"

     La pestaña de Actualizaciones no está funcional actualmente. Estamos trabajando activamente en una resolución para restaurar su funcionalidad.

## MicroWin
---

*   **MicroWin** te permite personalizar tus imágenes de instalación de Windows 10 y 11 eliminando componentes innecesarios (debloating) como desees.

![Microwin](assets/Microwin-Dark.png#only-dark#gh-dark-mode-only)
![Microwin](assets/Microwin-Light.png#only-light#gh-light-mode-only)

#### Uso básico

1.  Especifica el ISO de Windows de origen para personalizar.

    *   Si no tienes un archivo ISO de Windows preparado, puedes descargarlo usando la Herramienta de Creación de Medios para la versión respectiva de Windows. [Aquí](https://go.microsoft.com/fwlink/?linkid=2156295) está la versión de Windows 11, y [aquí](https://go.microsoft.com/fwlink/?LinkId=2265055) la versión de Windows 10.

2.  Configura el proceso de "debloat".
3.  Especifica la ubicación de destino para el nuevo archivo ISO.
4.  ¡Deja que la magia suceda!

!!! advertencia "Atención"

     Esta característica todavía está en desarrollo, y puedes encontrar algunos problemas con las imágenes generadas. Si eso sucede, ¡no dudes en reportar un problema!

#### Opciones

*   **Descargar oscdimg.exe del repositorio CTT GitHub** obtendrá un ejecutable OSCDIMG del repositorio de GitHub en lugar de un paquete de Chocolatey.

!!! nota "Información"

     OSCDIMG es la herramienta que permite al programa crear imágenes ISO. Típicamente, encontrarías esto en el [Kit de Evaluación e Implementación de Windows (ADK)](https://learn.microsoft.com/es-es/windows-hardware/get-started/adk-install)

*   Seleccionar un directorio temporal (scratch directory) copiará el contenido del archivo ISO al directorio que especifiques en lugar de una carpeta generada automáticamente en el directorio `%TEMP%`.
*   Puedes seleccionar una edición de Windows para el "debloat" (**SKU**) usando el conveniente menú desplegable.

Por defecto, MicroWin aplicará el "debloat" a la edición Pro, pero puedes elegir cualquier edición que desees.

##### Opciones de integración de controladores

*   **Inyectar controladores** agregará los controladores de la carpeta que especifiques a la imagen de Windows de destino.
*   **Importar controladores del sistema actual** agregará todos los controladores de terceros que estén presentes en tu instalación activa.

Esto hace que la imagen de destino tenga la misma compatibilidad de hardware que la instalación activa. Sin embargo, esto significa que solo podrás instalar la imagen de Windows de destino y aprovecharla al máximo en computadoras con **el mismo hardware**. Para evitar esto, necesitarás personalizar el archivo `install.wim` del ISO de destino en la carpeta `sources`.

##### Configuración de usuario personalizada

Con MicroWin, también puedes configurar tu usuario antes de proceder si no quieres usar la cuenta predeterminada `User`. Para hacer esto, simplemente escribe el nombre de la cuenta (20 caracteres máximo) y una contraseña. Luego, deja que MicroWin haga el resto.

!!! nota "Información"

     Por favor, asegúrate de recordar tu contraseña. MicroWin configurará los ajustes de inicio de sesión automático, por lo que no tendrás que introducir tu contraseña. Sin embargo, si se te requiere introducir tu contraseña, es mejor que no la olvides.

##### Opciones de Ventoy

*   **Copiar a Ventoy** copiará el archivo ISO de destino a cualquier unidad USB con [Ventoy](https://ventoy.net/es/index.html) instalado.
!!! nota "Información"

     Ventoy es una solución que te permite arrancar desde cualquier archivo ISO almacenado en una unidad. Piénsalo como tener múltiples USBs arrancables en uno. Ten en cuenta, sin embargo, que tu unidad necesita tener suficiente espacio libre para el archivo ISO de destino.

## Automatización

*   Algunas características están disponibles a través de la automatización. Esto te permite guardar tu archivo de configuración, pasarlo a WinUtil, alejarte y volver a un sistema terminado. Así es como puedes configurarlo actualmente con Winutil >24.01.15

*   En la Pestaña Instalar, haz clic en "Obtener Instalados", esto obtendrá todas las aplicaciones instaladas **soportadas por Winutil** en el sistema.
![GetInstalled](assets/Get-Installed-Dark.png#only-dark#gh-dark-mode-only)
![GetInstalled](assets/Get-Installed-Light.png#only-light#gh-light-mode-only)

*   Haz clic en el engranaje de Configuración en la esquina superior derecha y elige Exportar. Elige el archivo y la ubicación; esto exportará el archivo de configuración.
![SettingsExport](assets/Settings-Export-Dark.png#only-dark#gh-dark-mode-only)
![SettingsExport](assets/Settings-Export-Light.png#only-light#gh-light-mode-only)

*   Copia este archivo a un USB o a algún lugar donde puedas usarlo después de la instalación de Windows.

!!! consejo "Consejo"

     Usa la pestaña Microwin para crear una imagen de Windows personalizada e instalar la imagen de Windows.

*   En cualquier máquina Windows compatible, abre PowerShell **como Administrador** y ejecuta el siguiente comando para aplicar automáticamente los ajustes e instalar aplicaciones desde el archivo de configuración.
    ```ps1
    iex "& { $(irm https://christitus.com/win) } -Config [ruta-a-tu-configuración] -Run"
    ```
*   ¡Tómate una taza de café! Vuelve cuando haya terminado.
