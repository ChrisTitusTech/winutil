## Problemas de Ejecución

### Bloqueado por antivirus
Se sabe que Windows Security (anteriormente Defender) y otros software antivirus bloquean el script. El script es marcado debido a que requiere privilegios de administrador y realiza cambios drásticos en el sistema.

Para resolver esto, permite/añade a la lista blanca el script en la configuración de tu software antivirus, o deshabilita temporalmente la protección en tiempo real. Dado que el proyecto es de código abierto, puedes auditar el código si la seguridad es una preocupación.

### La descarga no funciona
Si `https://christitus.com/win` no funciona, o quieres descargar el código directamente desde GitHub, puedes usar el enlace de descarga directa:

```ps1
irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex
```

Si ves errores que hacen referencia a TLS o seguridad, es posible que estés ejecutando una versión anterior de Windows donde TLS 1.2 no es el protocolo de seguridad predeterminado utilizado para las conexiones de red. Los siguientes comandos forzarán a .NET a usar TLS 1.2 y descargarán el script directamente usando .NET en lugar de PowerShell:

```ps1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex (New-Object Net.WebClient).DownloadString('https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1')
```

Si sigue sin funcionar y vives en India, podría deberse a que India bloquea el dominio de contenido de GitHub e impide las descargas. Ver más en [Times of India](https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms).

Si sigues teniendo problemas, intenta usar una **VPN**, o cambiar tu **proveedor de DNS** a uno de los siguientes dos proveedores:

| Proveedor  | DNS Primario | DNS Secundario |
|:----------:|:------------:|:--------------:|
| Cloudflare | `1.1.1.1`    | `1.0.0.1`      |
| Google     | `8.8.8.8`    | `8.8.4.4`      |

### Script bloqueado por la Política de Ejecución
1.  Asegúrate de estar ejecutando PowerShell como administrador: Presiona `Tecla de Windows`+`X` y selecciona *PowerShell (Administrador)* en Windows 10, o `Windows Terminal (Administrador)` en Windows 11.
2.  En la ventana de PowerShell, escribe esto para permitir la ejecución de código no firmado y ejecutar el script de instalación:
    ```ps1
    Set-ExecutionPolicy Unrestricted -Scope Process -Force
    irm https://christitus.com/win | iex
    ```

## Problemas en Tiempo de Ejecución

### Configuración de WinGet
Si no has instalado nada usando PowerShell antes, es posible que se te pida configurar WinGet. Esto requiere interacción del usuario en la primera ejecución. Necesitarás escribir manualmente `y` en la consola de PowerShell y presionar enter para continuar. Una vez que lo hagas la primera vez, no se te volverá a pedir.

### MicroWin: Error `0x80041031`
Este código de error típicamente indica un problema relacionado con la Instrumental de Administración de Windows (WMI). Aquí hay algunos pasos que puedes intentar para resolver el problema:

1.  **Reinicia Tu Computadora:**

    A veces, un simple reinicio puede resolver problemas temporales. Reinicia tu computadora e intenta montar el ISO nuevamente.

3.  **Verifica la Corrupción del Sistema:**

    Ejecuta la utilidad Comprobador de Archivos de Sistema (SFC) para escanear y reparar archivos de sistema que puedan estar corruptos.
    ```powershell
    sfc /scannow
    ```

4.  **Actualiza Tu Sistema:**

    Asegúrate de que tu sistema operativo esté actualizado. Busca actualizaciones de Windows e instala cualquier actualización pendiente.

5.  **Verifica el Servicio WMI:**

    Asegúrate de que el servicio de Instrumental de Administración de Windows (WMI) esté en ejecución. Puedes hacerlo a través de la aplicación Servicios:
    -   Presiona `Win`+`R` para abrir el diálogo Ejecutar.
    -   Escribe `services.msc` y presiona Enter.
    -   Localiza *Instrumental de Administración de Windows* en la lista.
    -   Asegúrate de establecer su estado en "En ejecución" y el tipo de inicio en "Automático".

6.  **Verifica la Interferencia del Software de Seguridad:**

    El software de seguridad a veces puede interferir con las operaciones de WMI. Deshabilita temporalmente tu antivirus o software de seguridad y verifica si el problema persiste. WMI es un vector común de ataque/infección, por lo que muchos programas antivirus limitarán su uso.

7.  **Visor de Eventos:**

    Verifica el Visor de Eventos para obtener información de error más detallada. Busca entradas relacionadas con el error `80041031` y verifica si hay detalles adicionales que puedan ayudar a identificar la causa.

    -   Presiona `Win`+`X` y selecciona *Visor de Eventos*.
    -   Navega a *Registros de Windows* > *Aplicación* o *Sistema*.
    -   Busca entradas con el origen relacionado con WMI o la aplicación utilizada para montar el ISO.

8.  **Integridad del Archivo ISO:**

    Asegúrate de que el archivo ISO que intentas montar no esté corrupto. Intenta montar un archivo ISO diferente para ver si el problema persiste.

Si el problema persiste después de intentar estos pasos, se requiere una solución de problemas adicional. Considera buscar ayuda del soporte de Microsoft o foros comunitarios para obtener una guía más específica basada en la configuración de tu sistema y el software que utilizas para montar el ISO.

## Problemas de Windows

### Windows tarda más en apagarse
Esto podría deberse a varias razones:
-   Activa el inicio rápido: Presiona `Tecla de Windows`+`R`, luego escribe:
    ```bat
    control /name Microsoft.PowerOptions /page pageGlobalSettings
    ```
-   Si eso no funciona, deshabilita la Hibernación:
    -   Presiona `Tecla de Windows`+`X` y selecciona *PowerShell (Administrador)* en Windows 10, o `Windows Terminal (Administrador)` en Windows 11.
    -   En la ventana de PowerShell, escribe:
        ```bat
        powercfg /H off
        ```
Incidencia relacionada: [#69](https://github.com/ChrisTitusTech/winutil/issues/69)

### La Búsqueda de Windows no funciona
Habilita las Aplicaciones en Segundo Plano. Incidencias relacionadas: [#69](https://github.com/ChrisTitusTech/winutil/issues/69) [95](https://github.com/ChrisTitusTech/winutil/issues/95) [#232](https://github.com/ChrisTitusTech/winutil/issues/232)

### Activación de la Barra de Juegos de Xbox Rota
Establece el Servicio de Administración de Accesorios de Xbox en Automático:

```ps1
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```

Incidencia relacionada: [#198](https://github.com/ChrisTitusTech/winutil/issues/198)

### Windows 11: La Configuración Rápida ya no funciona
Ejecuta el Script y haz clic en *Habilitar Centro de Actividades*.

### El Explorador (navegador de archivos) ya no se inicia
 - Presiona `Tecla de Windows`+`R` luego escribe:
    ```bat
    control /name Microsoft.FolderOptions
    ```
- Cambia la opción *Abrir Explorador de Archivos en* a *Este equipo*.

### La batería se agota demasiado rápido
Si estás usando una laptop o tablet y encuentras que tu batería se agota demasiado rápido, por favor intenta los siguientes pasos de solución de problemas e informa los resultados a la comunidad de Winutil.

1.  **Verifica la Salud de la Batería:**
    -   Presiona `Tecla de Windows`+`X` y selecciona *PowerShell (Administrador)* en Windows 10, o `Windows Terminal (Administrador)` en Windows 11.
    -   Ejecuta el siguiente comando para generar un informe de batería:
        ```powershell
        powercfg /batteryreport /output "C:attery_report.html"
        ```
    -   Abre el informe HTML generado para revisar la información sobre la salud y el uso de la batería. Una batería con mala salud puede retener menos carga, descargarse más rápido o causar otros problemas.

2.  **Revisa la Configuración de Energía:**
    -   Abre la aplicación Configuración y ve a *Sistema* > *Energía y suspensión*.
    -   Ajusta la configuración del plan de energía según tus preferencias y patrones de uso.
    -   Haz clic en *Configuración de energía adicional* para acceder a configuraciones de energía avanzadas que puedan ayudar.

3.  **Identifica Aplicaciones que Consumen Mucha Energía:**
    -   Haz clic derecho en la barra de tareas y selecciona *Administrador de Tareas*.
    -   Navega a la pestaña *Procesos* para identificar aplicaciones con alto uso de CPU o memoria.
    -   Considera reconfigurar, cerrar, deshabilitar o desinstalar aplicaciones que usan muchos recursos.

4.  **Actualiza Controladores:**
    -   Visita el sitio web del fabricante de tu dispositivo o usa Windows Update para buscar actualizaciones de controladores.
    -   Asegúrate de que los controladores de gráficos, chipset y otros esenciales estén actualizados.

5.  **Busca Actualizaciones de Windows:**
    -   Abre la aplicación Configuración y ve a *Actualización y seguridad* > *Windows Update*.
    -   Busca e instala cualquier actualización disponible para tu sistema operativo.

6.  **Reduce el Brillo de la Pantalla:**
    -   Abre la aplicación Configuración y ve a *Sistema* > *Pantalla*.
    -   Ajusta el brillo de la pantalla según tus preferencias y condiciones de iluminación.

7.  **Habilita el Ahorro de Batería:**
    -   Abre la aplicación Configuración y ve a *Sistema* > *Batería*.
    -   Activa *Ahorro de batería* para limitar la actividad en segundo plano y conservar energía.

8.  **Verifica el Uso de Energía en Configuración:**
    -   Abre la aplicación Configuración y ve a *Sistema* > *Batería* > *Uso de la batería por aplicación*.
    -   Revisa la lista de aplicaciones y su uso de energía. Deshabilita o desinstala cualquiera que no necesites.

9.  **Verifica las Aplicaciones en Segundo Plano:**
    -   Abre la aplicación Configuración y ve a *Privacidad* > *Aplicaciones en segundo plano*.
    -   Deshabilita o desinstala aplicaciones innecesarias que se ejecutan en segundo plano.

10. **Usa `powercfg` para Análisis:**
    -   Presiona `Tecla de Windows`+`X` y selecciona *PowerShell (Administrador)* en Windows 10, o `Windows Terminal (Administrador)` en Windows 11.
    -   Ejecuta el siguiente comando para analizar el uso de energía y generar un informe:
        ```powershell
        powercfg /energy /output "C:\energy_report.html"
        ```
    -   Abre el informe HTML generado para identificar patrones de consumo de energía.

11. **Revisa los Registros de Eventos:**
    -   Abre el Visor de Eventos buscándolo en el menú Inicio.
    -   Navega a *Registros de Windows* > *Sistema*.
    -   Busca eventos con el origen *Power-Troubleshooter* para identificar eventos relacionados con la energía. Estos pueden destacar problemas de batería, alimentación de entrada y otros.

12. **Verifica las Fuentes de Activación:**
    -   Presiona `Tecla de Windows`+`X` y selecciona *PowerShell (Administrador)* en Windows 10, o `Windows Terminal (Administrador)` en Windows 11.
    -   Usa el comando `powercfg /requests` para identificar procesos que impiden la suspensión.
    -   Usa el comando `powercfg /waketimers` para ver los temporizadores de activación activos.
    -   Verifica el Programador de Tareas para ver si alguno de los procesos descubiertos está programado para iniciarse en el arranque o a intervalos regulares.

13. **Identificación Avanzada de Aplicaciones que Consumen Mucha Energía:**
    -   Abre el Monitor de Recursos desde el menú Inicio.
    -   Navega a las pestañas *CPU*, *Memoria*, *Red* y otras para identificar procesos con alto uso de recursos.
    -   Considera reconfigurar, cerrar, deshabilitar o desinstalar aplicaciones que usan muchos recursos.

14. **Deshabilita el Historial de Actividad:**
    -   Abre la aplicación Configuración y ve a *Privacidad* > *Historial de actividad*.
    -   Desactiva *Permitir que Windows recopile mis actividades de esta PC*.

15. **Evita que los Adaptadores de Red Despierten la PC:**
    -   Abre el Administrador de Dispositivos buscándolo en el menú Inicio.
    -   Localiza tu adaptador de red, haz clic derecho y ve a *Propiedades*.
    -   En la pestaña *Administración de energía*, desmarca la opción que permite que el dispositivo despierte la computadora.

16. **Revisa las Aplicaciones Instaladas:**
    -   Revisa manualmente las aplicaciones instaladas buscando *Agregar o quitar programas* en el menú Inicio.
    -   Verifica la configuración/preferencias de las aplicaciones individuales para opciones relacionadas con la energía.
    -   Desinstala software innecesario o problemático.

Estos pasos de solución de problemas son genéricos, pero deberían ayudar en la mayoría de las situaciones. Debes tener en cuenta estos puntos clave:
-   La salud de la batería es el limitador más significativo del tiempo de ejecución de tu dispositivo. Una batería en mal estado generalmente no puede durar como antes, simplemente cerrando algunas aplicaciones. Considera reemplazar tu batería.
-   Las aplicaciones en segundo plano que usan CPU y memoria, realizan muchas o grandes solicitudes de red, leen/escriben en el disco con frecuencia, o que mantienen tu PC despierta cuando podría estar conservando energía son la siguiente preocupación principal. Evita instalar programas que no necesitas, solo usa programas en los que confíes y configura las aplicaciones para que usen la menor cantidad de energía posible y se ejecuten con la menor frecuencia posible.
-   Windows realiza muchas tareas que pueden afectar la vida útil de la batería por defecto. Cambiar la configuración, detener tareas programadas y deshabilitar características puede ayudar al sistema a permanecer en estados de menor consumo de energía para conservar la batería.
-   Los cargadores defectuosos, la alimentación de entrada inconsistente y las altas temperaturas harán que las baterías se degraden y se descarguen más rápido. Usa cargadores confiables de alta calidad, asegúrate de que la alimentación de entrada sea estable, limpia cualquier ventilador o puerto de flujo de aire y mantén la batería/PC fresca.
